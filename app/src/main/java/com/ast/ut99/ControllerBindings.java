package com.ast.ut99;

/** Android key numbers, independent of Android so profile validation can be tested locally. */
final class ControllerBindings {
    static final int SCORES = 98;
    static final int[] BUTTONS = {96, 97, 99, 100, 102, 103, 106, 107};
    static final int[] TARGETS = {96, 97, 99, 100, 102, 103, 106, 107, SCORES, 0};
    static boolean configurable(int key) {
        for (int button : BUTTONS) if (button == key) return true;
        return false;
    }
    static int validated(int original, int saved) {
        for (int target : TARGETS) if (target == saved) return saved;
        return original;
    }
    static int normalized(int key, int scan) {
        if (key != 0) return key;
        switch (scan) {
            case 304: return 96;
            case 305: return 97;
            case 308: return 99;
            case 307: return 100;
            case 310: return 102;
            case 311: return 103;
            case 289: case 317: return 106;
            case 290: case 318: return 107;
            default: return key;
        }
    }
}
