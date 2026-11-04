package com.ast.ut99;

/** Input state independent of Android so shortcut ordering can be regression-tested. */
final class SettingsChord {
    interface Sink {
        void key(int button, boolean down);
        void open();
    }
    private final Sink sink;
    private final boolean[] held = new boolean[2], forwarded = new boolean[2];
    private final int[] device = new int[2];
    private boolean opened;

    SettingsChord(Sink sink) { this.sink = sink; }

    void key(int button, int deviceId, boolean down) {
        if (down) {
            if (held[button] || opened) return;
            held[button] = true;
            device[button] = deviceId;
            int other = 1 - button;
            if (held[other] && device[other] == deviceId) {
                opened = true;
                // A slow chord may follow an already forwarded single press. Release it.
                for (int i = 0; i < 2; i++) if (forwarded[i]) { sink.key(i, false); forwarded[i] = false; }
                sink.open();
            }
        } else {
            if (!held[button] || device[button] != deviceId) return; // Orphan/device-mismatched releases.
            held[button] = false;
            if (!opened) {
                if (!forwarded[button]) sink.key(button, true);
                sink.key(button, false);
            }
            forwarded[button] = false;
            if (!held[0] && !held[1]) opened = false;
        }
    }

    /** Preserve held single-button bindings after a short simultaneous-press grace period. */
    void flush() {
        if (opened) return;
        for (int i = 0; i < 2; i++) if (held[i] && !forwarded[i]) {
            forwarded[i] = true;
            sink.key(i, true);
        }
    }

    /** The host releases native input separately when focus/lifecycle changes. */
    void reset() {
        held[0] = held[1] = forwarded[0] = forwarded[1] = opened = false;
    }

    void cancel() {
        for (int i = 0; i < 2; i++) if (forwarded[i]) sink.key(i, false);
        reset();
    }
}
