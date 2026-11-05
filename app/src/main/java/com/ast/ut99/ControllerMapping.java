package com.ast.ut99;

import android.content.Context;
import android.content.SharedPreferences;
import android.hardware.input.InputManager;
import android.view.InputDevice;
import android.view.KeyEvent;
import java.util.ArrayList;
import java.util.HashMap;

/** Per-device button profiles. Dialog navigation and the settings chord stay physical. */
final class ControllerMapping implements InputManager.InputDeviceListener {
    interface Relay { void send(KeyEvent event); }
    private final Context context;
    private final Relay relay;
    private final HashMap<String, KeyEvent> held = new HashMap<>();
    private boolean replaying;
    private InputManager manager;

    ControllerMapping(Context context, Relay relay) { this.context = context; this.relay = relay; }

    void start() {
        if (manager != null) return;
        manager = (InputManager) context.getSystemService(Context.INPUT_SERVICE);
        if (manager != null) manager.registerInputDeviceListener(this, null);
    }
    void stop() {
        reset();
        if (manager != null) manager.unregisterInputDeviceListener(this);
        manager = null;
    }
    @Override public void onInputDeviceAdded(int id) {}
    @Override public void onInputDeviceChanged(int id) {}
    @Override public void onInputDeviceRemoved(int deviceId) {
        ArrayList<String> removed = new ArrayList<>();
        for (String id : held.keySet()) if (held.get(id).getDeviceId() == deviceId) removed.add(id);
        for (String id : removed) {
            KeyEvent event = held.remove(id);
            if (!outputHeld(event.getKeyCode())) send(KeyEvent.changeAction(event, KeyEvent.ACTION_UP));
        }
    }

    private static boolean controller(InputDevice device) {
        if (device == null || device.isVirtual()) return false;
        int sources = device.getSources();
        return (sources & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
                || (sources & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
    }
    private static SharedPreferences profile(Context context, InputDevice device) {
        // Descriptor is stable across reconnects; Android device IDs are not.
        return context.getSharedPreferences("controller_" + device.getDescriptor(), 0);
    }
    private void send(KeyEvent event) {
        replaying = true;
        try { relay.send(event); } finally { replaying = false; }
    }
    private boolean outputHeld(int target) {
        for (KeyEvent event : held.values()) if (event.getKeyCode() == target) return true;
        return false;
    }
    boolean key(KeyEvent event) {
        if (replaying || !controller(event.getDevice())) return false;
        ArrayList<String> disconnected = new ArrayList<>();
        for (String id : held.keySet()) if (held.get(id).getDevice() == null) disconnected.add(id);
        for (String id : disconnected) {
            KeyEvent removed = held.remove(id);
            if (!outputHeld(removed.getKeyCode())) send(KeyEvent.changeAction(removed, KeyEvent.ACTION_UP));
        }
        int source = ControllerBindings.normalized(event.getKeyCode(), event.getScanCode());
        if (!ControllerBindings.configurable(source)) return false;
        String id = event.getDeviceId() + ":" + source;
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            if (event.getRepeatCount() != 0 || held.containsKey(id)) return true;
            int target = ControllerBindings.validated(source, profile(context, event.getDevice()).getInt("button_" + source, source));
            if (target == 0) return true;
            boolean alreadyHeld = outputHeld(target);
            KeyEvent mapped = new KeyEvent(event.getDownTime(), event.getEventTime(), event.getAction(),
                    target, 0, event.getMetaState(), event.getDeviceId(), 0, event.getFlags(), event.getSource());
            held.put(id, mapped);
            if (!alreadyHeld) send(mapped);
            return true;
        }
        if (event.getAction() == KeyEvent.ACTION_UP) {
            KeyEvent down = held.remove(id);
            if (down != null && !outputHeld(down.getKeyCode())) send(KeyEvent.changeAction(down, KeyEvent.ACTION_UP));
            return true;
        }
        return false;
    }
    void reset() {
        ArrayList<KeyEvent> pressed = new ArrayList<>(held.values());
        held.clear();
        java.util.HashSet<Integer> released = new java.util.HashSet<>();
        for (KeyEvent event : pressed) if (released.add(event.getKeyCode())) send(KeyEvent.changeAction(event, KeyEvent.ACTION_UP));
    }

    private static String text(boolean fr, String french, String english) { return fr ? french : english; }
    static void page(Context context, GameSettingsMenu menu, boolean tournament, boolean fr) {
        ArrayList<InputDevice> devices = new ArrayList<>();
        for (int id : InputDevice.getDeviceIds()) {
            InputDevice device = InputDevice.getDevice(id);
            if (controller(device)) devices.add(device);
        }
        menu.section(text(fr, "Manette physique", "Physical controller"));
        if (devices.isEmpty()) {
            menu.note(text(fr, "Connectez une manette, puis actualisez cette page.", "Connect a controller, then refresh this page."));
            menu.button(text(fr, "Actualiser", "Refresh"), menu::refresh);
            return;
        }
        SharedPreferences selection = context.getSharedPreferences("controller_selection", 0);
        String selected = selection.getString("descriptor", "");
        int current = 0;
        String[] names = new String[devices.size()];
        for (int i = 0; i < names.length; i++) {
            names[i] = devices.get(i).getName();
            if (devices.get(i).getDescriptor().equals(selected)) current = i;
        }
        final InputDevice device = devices.get(current);
        menu.choice(text(fr, "Profil de la manette", "Controller profile"), names, current, 0, index -> {
            selection.edit().putString("descriptor", devices.get(index).getDescriptor()).apply();
            menu.refresh();
        });
        SharedPreferences prefs = profile(context, device);
        String[] buttons = {"A / \u00d7", "B / \u25cb", "X / \u25a1", "Y / \u25b3", "L1 / LB", "R1 / RB", "L3", "R3"};
        String[] actions = tournament
                ? new String[]{text(fr,"Sauter","Jump"), text(fr,"S'accroupir","Duck"), text(fr,"Jeter l'arme","Throw weapon"), text(fr,"Sans action","Unassigned"), text(fr,"Marcher","Walk"), text(fr,"Arme suivante","Next weapon"), text(fr,"Sans action","Unassigned"), text(fr,"Sans action","Unassigned")}
                : new String[]{text(fr,"Sauter","Jump"), text(fr,"S'accroupir","Duck"), text(fr,"Saisir","Grab"), text(fr,"Marcher","Walk"), text(fr,"Objet pr\u00e9c\u00e9dent","Previous item"), text(fr,"Objet suivant","Next item"), text(fr,"S'accroupir","Duck"), text(fr,"Objectif","Objective")};
        String[] choices = new String[ControllerBindings.TARGETS.length];
        for (int i = 0; i < buttons.length; i++) choices[i] = buttons[i] + " : " + actions[i];
        choices[8] = text(fr, "Tableau des scores (maintenir)", "Scoreboard (hold)");
        choices[9] = text(fr, "D\u00e9sactiv\u00e9", "Disabled");
        menu.note(text(fr, "Choisissez la fonction de chaque bouton. Les actions indiqu\u00e9es sont celles du jeu par d\u00e9faut ; vos affectations dans le jeu restent prioritaires.",
                "Choose each button's function. Listed actions are the game's defaults; custom in-game bindings still apply."));
        for (int i = 0; i < buttons.length; i++) {
            final int original = ControllerBindings.BUTTONS[i];
            int target = ControllerBindings.validated(original, prefs.getInt("button_" + original, original));
            int initial = 0;
            for (int n = 0; n < ControllerBindings.TARGETS.length; n++) if (ControllerBindings.TARGETS[n] == target) initial = n;
            menu.choice(buttons[i], choices, initial, i, index -> prefs.edit().putInt("button_" + original, ControllerBindings.TARGETS[index]).apply());
        }
        menu.note(tournament ? text(fr, "Select : scores (maintenir). Start : menu du jeu. Select + Start : r\u00e9glages Android.",
                "Select: scoreboard (hold). Start: game menu. Select + Start: Android settings.")
                : text(fr, "Select : traducteur. Start : menu du jeu. Select + Start : r\u00e9glages Android. Le tableau des scores concerne les parties multijoueurs.",
                "Select: translator. Start: game menu. Select + Start: Android settings. The scoreboard is for multiplayer games."));
        menu.note(text(fr, "Sticks, croix directionnelle et g\u00e2chettes inchang\u00e9s. La navigation dans ces r\u00e9glages conserve A/B et L1/R1. Profil appliqu\u00e9 au retour au jeu.",
                "Sticks, D-pad and triggers keep their existing functions. These settings retain A/B and L1/R1 navigation. Profile applies when you resume."));
        menu.button(text(fr, "R\u00e9initialiser cette manette", "Reset this controller"), () -> menu.confirm(
                text(fr, "R\u00e9tablir les boutons par d\u00e9faut de cette manette ?", "Restore this controller's default buttons?"), text(fr,"R\u00e9initialiser","Reset"), () -> {
                    prefs.edit().clear().apply(); menu.refresh();
                }));
    }
}
