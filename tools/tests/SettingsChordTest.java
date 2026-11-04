package com.ast.ut99;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/** Regression cases for inputs that must never leak a held key across the Android menu. */
public final class SettingsChordTest {
    private final List<String> events = new ArrayList<>();
    private final SettingsChord chord = new SettingsChord(new SettingsChord.Sink() {
        public void key(int button, boolean down) { events.add(button + (down ? "+" : "-")); }
        public void open() { events.add("open"); }
    });
    private void expect(String... wanted) {
        if (!events.equals(Arrays.asList(wanted))) throw new AssertionError(events + " != " + Arrays.asList(wanted));
        events.clear();
    }
    private void key(int button, boolean down) { chord.key(button, 7, down); }

    private void run() {
        for (int first = 0; first < 2; first++) {
            key(first, true); key(1 - first, true);
            chord.flush(); key(first, true); // flush/repeats cannot reopen or forward.
            key(first, false); key(1 - first, false);
            expect("open");
            key(first, true); key(first, false); // ordinary single-button binding survives.
            expect(first + "+", first + "-");
        }
        key(0, true); chord.flush(); key(0, false);
        expect("0+", "0-");
        key(1, true); chord.flush(); key(0, true); key(0, false); key(1, false);
        expect("1+", "1-", "open"); // slow chord releases a previously forwarded Start.
        key(0, true); chord.reset(); key(0, false); chord.flush();
        expect(); // Activity pause cancels a pending single press.
        key(1, true); chord.flush(); chord.cancel(); key(1, false);
        expect("1+", "1-"); // canceled Android events release a held key without a new tap.
        key(0, true); chord.key(1, 8, true); chord.key(0, 8, false);
        expect(); // Two controllers cannot accidentally form a chord or release each other's key.
        key(0, false); chord.key(1, 8, false);
        expect("0+", "0-", "1+", "1-");
        key(0, true); key(1, true); chord.reset(); key(1, false); key(0, false);
        expect("open"); // Opening releases arriving after resume are swallowed.
        System.out.println("Settings chord tests passed");
    }
    public static void main(String[] args) { new SettingsChordTest().run(); }
}
