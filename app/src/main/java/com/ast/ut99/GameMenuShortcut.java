package com.ast.ut99;

import android.os.Handler;
import android.os.Looper;
import android.view.InputDevice;
import android.view.KeyEvent;

/** Select + Start, either order, without forwarding a quick chord to the engine. */
final class GameMenuShortcut {
    interface Relay { void send(KeyEvent event); }
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final KeyEvent[] original = new KeyEvent[2];
    private final SettingsChord chord;
    private final Runnable flush;
    private final Runnable openMenu;
    private boolean replaying;

    GameMenuShortcut(Runnable open, Relay relay) {
        openMenu = open;
        chord = new SettingsChord(new SettingsChord.Sink() {
            public void open() { handler.removeCallbacks(flush); open.run(); }
            public void key(int button, boolean down) {
                KeyEvent event = original[button];
                if (event == null) return;
                replaying = true;
                try { relay.send(KeyEvent.changeAction(event, down ? KeyEvent.ACTION_DOWN : KeyEvent.ACTION_UP)); }
                finally { replaying = false; }
            }
        });
        flush = this::flushPending;
    }

    private void flushPending() {
        // A disconnected pad cannot send Select/Start's final KEY_UP.
        for (KeyEvent event : original) if (event != null && event.getDevice() == null) {
            reset();
            return;
        }
        chord.flush();
        if (original[0] != null || original[1] != null) handler.postDelayed(flush, 250);
    }

    boolean key(KeyEvent event) {
        if (replaying) return false;
        int code = event.getKeyCode();
        // Keyboard/mouse players have no touch icon or Select/Start buttons.
        if (code == KeyEvent.KEYCODE_F10) {
            if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled()) openMenu.run();
            return true;
        }
        boolean controller = (event.getSource() & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
                || (event.getSource() & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
        if (!controller && code == KeyEvent.KEYCODE_BACK && event.getDevice() != null) {
            int sources = event.getDevice().getSources();
            controller = (sources & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
                    || (sources & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
        }
        // Some pads send Android BACK for Select. Never intercept the phone's Back key.
        int button = code == KeyEvent.KEYCODE_BUTTON_SELECT || (code == KeyEvent.KEYCODE_BACK && controller) ? 0
                : code == KeyEvent.KEYCODE_BUTTON_START ? 1 : -1;
        if (button < 0 || (event.getAction() != KeyEvent.ACTION_DOWN && event.getAction() != KeyEvent.ACTION_UP)) return false;
        boolean down = event.getAction() == KeyEvent.ACTION_DOWN;
        if (down && event.getRepeatCount() == 0) {
            // A few OUYA/Android pads lose START's KEY_UP. A fresh press ends that stale press.
            if (original[button] != null) {
                if (original[button].getDeviceId() != event.getDeviceId()) return false;
                chord.key(button, event.getDeviceId(), false);
            }
            original[button] = new KeyEvent(event);
            chord.key(button, event.getDeviceId(), true);
            handler.removeCallbacks(flush);
            handler.postDelayed(flush, 250);
        } else if (!down) {
            if (original[button] != null && original[button].getDeviceId() != event.getDeviceId()) return false;
            if (event.isCanceled()) chord.cancel();
            else chord.key(button, event.getDeviceId(), false);
            original[button] = null;
        }
        return true;
    }

    void reset() {
        handler.removeCallbacks(flush);
        // Release any single press already delivered before the chord grace period expired.
        chord.cancel();
        original[0] = original[1] = null;
    }
}
