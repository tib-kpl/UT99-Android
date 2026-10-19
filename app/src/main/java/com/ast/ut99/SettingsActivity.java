package com.ast.ut99;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.view.*;
import android.widget.*;
import java.util.*;

/** Android settings, independent of either Unreal menu implementation. */
public final class SettingsActivity extends Activity {
    static final int OPEN = 3520, RESTART = 3521, DATA = 3522, EDIT_TOUCH = 3523, RESET_TOUCH = 3524;
    private final String[] languages = {"", "frt", "int", "det", "est", "itt", "nlt", "ptt", "rut", "elt", "ctt"};
    private String selectedLanguage;
    private boolean french;

    private String text(String fr, String en) { return french ? fr : en; }
    private int dp(int value) { return (int)(value * getResources().getDisplayMetrics().density + .5f); }
    private TextView label(String value, int size) {
        TextView view = new TextView(this); view.setText(value); view.setTextSize(size);
        view.setTextColor(0xffe4dac5); view.setPadding(0, dp(12), 0, dp(8)); return view;
    }
    private Button button(String value, Runnable action) {
        Button button = new Button(this); button.setText(value); button.setAllCaps(false);
        button.setOnClickListener(v -> action.run()); return button;
    }
    private interface Choice { void accept(int index); }
    private Spinner choices(String[] names, int initial, Choice changed) {
        Spinner spinner = new Spinner(this);
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, names);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter); spinner.setSelection(initial);
        spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) { changed.accept(position); }
            public void onNothingSelected(AdapterView<?> parent) { }
        });
        return spinner;
    }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        french = "fr".equalsIgnoreCase(getResources().getConfiguration().locale.getLanguage());
        selectedLanguage = state == null ? AndroidGameSettings.language(this) : state.getString("language", "");
        LinearLayout body = new LinearLayout(this); body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(24), dp(12), dp(24), dp(16));
        body.addView(label(text("Manette sur écran tactile", "On-screen touch controller"), 17));
        String mode = AndroidGameSettings.touch(this);
        body.addView(choices(new String[]{text("Automatique (sans manette physique)", "Automatic (without a physical controller)"),
                text("Toujours afficher", "Always show"), text("Masquer", "Hide")},
                mode.equals("on") ? 1 : mode.equals("off") ? 2 : 0,
                index -> AndroidGameSettings.touch(this, new String[]{"auto", "on", "off"}[index])));
        final TextView opacityLabel = label("", 15);
        final String opacityText = text("Opacité de la manette tactile : ", "On-screen controller opacity: ");
        int opacity = AndroidGameSettings.touchOpacity(this);
        opacityLabel.setText(opacityText + opacity + " %");
        body.addView(opacityLabel);
        SeekBar opacityBar = new SeekBar(this);
        opacityBar.setMax(16); // 20..100 % in 5 % steps
        opacityBar.setProgress((opacity - 20) / 5);
        opacityBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            public void onProgressChanged(SeekBar bar, int progress, boolean fromUser) {
                int percent = 20 + progress * 5;
                opacityLabel.setText(opacityText + percent + " %");
                AndroidGameSettings.touchOpacity(SettingsActivity.this, percent);
            }
            public void onStartTrackingTouch(SeekBar bar) { }
            public void onStopTrackingTouch(SeekBar bar) { }
        });
        body.addView(opacityBar, new LinearLayout.LayoutParams(-1, dp(48)));
        body.addView(button(text("Modifier la disposition de la manette tactile", "Edit on-screen controller layout"), () -> {
            setResult(EDIT_TOUCH); finish();
        }));
        body.addView(button(text("Réinitialiser la disposition", "Reset layout"), () ->
                new AlertDialog.Builder(this, AlertDialog.THEME_DEVICE_DEFAULT_DARK)
                        .setMessage(text("Remettre les boutons tactiles à leur position d’origine ?", "Restore the touch buttons to their default position?"))
                        .setNegativeButton(android.R.string.cancel, null)
                        .setPositiveButton(text("Réinitialiser", "Reset"), (dialog, which) -> { setResult(RESET_TOUCH); finish(); })
                        .show()));
        body.addView(label(text("Langue du jeu", "Game language"), 17));
        int initial = Arrays.asList(languages).indexOf(selectedLanguage);
        body.addView(choices(new String[]{text("Automatique / choix à l’installation", "Automatic / installation choice"),
                "Français", "English", "Deutsch", "Español", "Italiano", "Nederlands", "Português", "Русский", "Ελληνικά", "繁體中文"},
                Math.max(0, initial), index -> selectedLanguage = languages[index]));
        body.addView(label(text("La traduction doit être présente dans les fichiers du jeu. La langue prend effet après relance.",
                "The translation must be present in the game data. Language changes require a restart."), 14));
        body.addView(button(text("Appliquer la langue et relancer le jeu…", "Apply language and restart…"), () ->
                confirm(text("Quitter la partie et relancer le jeu avec cette langue ?", "Leave the match and restart with this language?"), RESTART)));
        body.addView(label(text("Emplacement du jeu", "Game location"), 17));
        TextView path = label(getIntent().getStringExtra(UT99Paths.EXTRA_DATA_ROOT), 13);
        path.setTextIsSelectable(true); body.addView(path);
        body.addView(button(text("Changer de fichiers ou d’emplacement…", "Change game data or location…"), () ->
                confirm(text("Quitter la partie et ouvrir le gestionnaire de fichiers du jeu ? Les fichiers actuels seront conservés.",
                        "Leave the match and open the game data manager? Current files will be preserved."), DATA)));
        Button back = button(text("Retour au jeu", "Return to game"), this::finish); body.addView(back);
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true); scroll.addView(body);
        LinearLayout outer = new LinearLayout(this); outer.setOrientation(LinearLayout.VERTICAL); outer.setBackgroundColor(0xff181416);
        LinearLayout header = new LinearLayout(this); header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(dp(24), 0, dp(24), 0);
        header.addView(label(text("Réglages Android", "Android settings"), 22),
                new LinearLayout.LayoutParams(0, -2, 1));
        Button topBack = button(text("Retour au jeu", "Return to game"), this::finish);
        header.addView(topBack); outer.addView(header);
        outer.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        setContentView(outer);
        topBack.requestFocus();
    }
    private void confirm(String message, int result) {
        new AlertDialog.Builder(this, AlertDialog.THEME_DEVICE_DEFAULT_DARK).setMessage(message)
                .setNegativeButton(android.R.string.cancel, null)
                .setPositiveButton(text("Continuer", "Continue"), (dialog, which) -> {
                    if (result == RESTART) AndroidGameSettings.language(this, selectedLanguage);
                    setResult(result); finish();
                }).show();
    }
    @Override protected void onSaveInstanceState(Bundle state) {
        state.putString("language", selectedLanguage); super.onSaveInstanceState(state);
    }
    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_B) {
            if (event.getAction() == KeyEvent.ACTION_UP) onBackPressed(); return true;
        }
        if (event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_A) {
            return super.dispatchKeyEvent(new KeyEvent(event.getDownTime(), event.getEventTime(), event.getAction(),
                    KeyEvent.KEYCODE_DPAD_CENTER, event.getRepeatCount()));
        }
        return super.dispatchKeyEvent(event);
    }
}
