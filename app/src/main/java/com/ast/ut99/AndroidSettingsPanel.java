package com.ast.ut99;

import android.app.Activity;
import android.content.ContextWrapper;
import java.io.File;
import java.util.Arrays;

/** Tournament-themed Android settings, shared by classic and console menu variants. */
final class AndroidSettingsPanel extends ContextWrapper {
    static final int RESTART = 3521, DATA = 3522, EDIT_TOUCH = 3523, RESET_TOUCH = 3524;
    private final String[] languages = {"", "frt", "int", "det", "est", "itt", "nlt", "ptt", "rut", "elt", "ctt"};
    private String selectedLanguage;
    private boolean french;
    private GameSettingsMenu menu;
    private final File root;
    private int result;
    private void setResult(int action) { result = action; }
    private void finish() { menu.dismiss(); }

    static GameSettingsMenu open(Activity activity, File root, GameSettingsMenu.Result completed) {
        return new AndroidSettingsPanel(activity, root, completed).menu;
    }
    private String text(String fr, String en) { return french ? fr : en; }

    private AndroidSettingsPanel(Activity activity, File root, GameSettingsMenu.Result completed) {
        super(activity);
        this.root = root;
        french = "fr".equalsIgnoreCase(getResources().getConfiguration().locale.getLanguage());
        selectedLanguage = AndroidGameSettings.language(this);
        menu = new GameSettingsMenu(activity, true, R.drawable.menu_logo_ut99);
        menu.setOnDismissListener(dialog -> { if (!activity.isFinishing()) completed.complete(result); });
        menu.page(text("Commandes", "Controls"), this::controls);
        menu.page(text("Manette", "Controller"), () -> ControllerMapping.page(this, menu, true, french));
        menu.page(text("Confort", "Comfort"), this::comfort);
        menu.page(text("Jeu", "Game"), this::game);
        menu.page(text("Fichiers", "Game data"), this::data);
        menu.show("UNREAL TOURNAMENT", text("RÉGLAGES ANDROID  /  UT99", "ANDROID SETTINGS  /  UT99"),
                -1);
    }

    private void controls() {
        menu.section(text("Manette sur écran tactile", "On-screen touch controller"));
        String mode = AndroidGameSettings.touch(this);
        menu.choice(text("Visibilité", "Visibility"), new String[]{text("Automatique · sans manette physique", "Automatic · without a controller"),
                text("Toujours afficher", "Always show"), text("Masquer", "Hide")}, mode.equals("on") ? 1 : mode.equals("off") ? 2 : 0, 0,
                index -> AndroidGameSettings.touch(this, new String[]{"auto", "on", "off"}[index]));
        String[] values = new String[17];
        for (int i = 0; i < values.length; i++) values[i] = (20 + i * 5) + " %";
        menu.slider(text("Opacité", "Opacity"), 16, (AndroidGameSettings.touchOpacity(this) - 20) / 5, (AndroidGameSettings.DEFAULT_TOUCH_OPACITY - 20) / 5, values,
                value -> AndroidGameSettings.touchOpacity(this, 20 + value * 5));
        menu.button(text("Modifier la disposition tactile", "Edit touch layout"), () -> { setResult(EDIT_TOUCH); finish(); });
        menu.button(text("Réinitialiser la disposition", "Reset touch layout"), () ->
                menu.confirm(text("Remettre les boutons tactiles à leur position d’origine ?", "Restore the touch buttons to their default position?"),
                        text("Réinitialiser", "Reset"), () -> { setResult(RESET_TOUCH); finish(); }));
        menu.note(text("Select + Start ouvre ce menu à la manette. La petite icône est réservée au mode tactile.",
                "Select + Start opens these settings with a controller. The small icon appears in touch mode only."));
    }

    private void comfort() {
        menu.section(text("Aide à la visée · manette", "Aim assist · controller"));
        menu.choice(text("Intensité", "Strength"), new String[]{
                text("Désactivée", "Off"), text("Légère", "Light"),
                text("Moyenne", "Medium"), text("Forte", "Strong")},
                AndroidGameSettings.aimAssist(this), AndroidGameSettings.DEFAULT_AIM_ASSIST,
                level -> AndroidGameSettings.aimAssist(this, level));
        menu.note(text("Suit doucement un adversaire visible proche du viseur. Les coéquipiers sont exclus. Un mouvement franc du stick garde la priorité.",
                "Gently follows a visible opponent near the crosshair. Teammates are excluded. Firm stick movement takes priority."));
        menu.note(text("Active à la manette uniquement, après fermeture de ce menu. Aucun effet sur la visée tactile ou à la souris.",
                "Controller only, applied when you close this menu. Touch and mouse aiming are unaffected."));
    }

    private void game() {
        menu.section(text("Langue du jeu", "Game language"));
        menu.choice(text("Langue", "Language"), new String[]{text("Automatique / choix à l’installation", "Automatic / installation choice"),
                "Français", "English", "Deutsch", "Español", "Italiano", "Nederlands", "Português", "Русский", "Ελληνικά", "繁體中文"},
                Math.max(0, Arrays.asList(languages).indexOf(selectedLanguage)), 0, index -> selectedLanguage = languages[index]);
        menu.note(text("La traduction doit être présente dans les fichiers du jeu. La langue prend effet après relance.",
                "The translation must be present in the game data. Language changes require a restart."));
        menu.button(text("Appliquer la langue et relancer…", "Apply language and restart…"), () ->
                confirm(text("Quitter la partie et relancer le jeu avec cette langue ?", "Leave the match and restart with this language?"), RESTART));
        defaultsSection();
    }

    private void data() {
        menu.section(text("Emplacement du jeu", "Game location"));
        menu.path(root.getAbsolutePath());
        menu.button(text("Changer de fichiers ou d’emplacement…", "Change game data or location…"), () ->
                confirm(text("Quitter la partie et ouvrir le gestionnaire de fichiers du jeu ? Les fichiers actuels seront conservés.",
                        "Leave the match and open the game data manager? Current files will be preserved."), DATA));
    }

    private void defaultsSection() {
        menu.section(text("Réglages par défaut", "Default settings"));
        menu.button(text("Réinitialiser les réglages Android…", "Reset Android settings…"), () ->
                menu.confirm(text("Rétablir les valeurs par défaut des réglages Android ? La disposition tactile, les fichiers et les sauvegardes seront conservés. La langue prendra effet à la prochaine relance.",
                        "Restore the default Android settings? Touch layouts, game data and saves will be preserved. Language changes take effect on the next launch."),
                        text("Réinitialiser", "Reset"), () -> {
            AndroidGameSettings.resetDefaults(this);
            selectedLanguage = AndroidGameSettings.language(this);
            menu.refresh();
            android.widget.Toast.makeText(this, text("Réglages réinitialisés", "Settings reset"), android.widget.Toast.LENGTH_SHORT).show();
        }));
        menu.note(text("Disposition tactile et fichiers du jeu conservés. Langue : prochaine relance.",
                "Touch layout and game data are preserved. Language: next launch."));
    }

    private void confirm(String message, int result) {
        menu.confirm(message, text("Continuer", "Continue"), () -> {
                    if (result == RESTART) AndroidGameSettings.language(this, selectedLanguage);
                    setResult(result); finish();
                });
    }
}
