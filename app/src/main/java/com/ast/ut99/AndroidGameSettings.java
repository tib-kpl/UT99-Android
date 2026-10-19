package com.ast.ut99;

import android.content.Context;

/** Preferences owned by the game process, separate from launcher/import state. */
final class AndroidGameSettings {
    private static final String PREFS = "android_game_settings";
    static String language(Context context) {
        return context.getSharedPreferences(PREFS, 0).getString("language", "");
    }
    static void language(Context context, String value) {
        context.getSharedPreferences(PREFS, 0).edit().putString("language", value).commit();
    }
    static String touch(Context context) {
        return context.getSharedPreferences(PREFS, 0).getString("touch", "auto");
    }
    static void touch(Context context, String value) {
        context.getSharedPreferences(PREFS, 0).edit().putString("touch", value).commit();
    }
    /** Whole on-screen controller opacity in percent (20..100). */
    static int touchOpacity(Context context) {
        return Math.max(20, Math.min(100, context.getSharedPreferences(PREFS, 0).getInt("touch_opacity", 70)));
    }
    static void touchOpacity(Context context, int percent) {
        context.getSharedPreferences(PREFS, 0).edit().putInt("touch_opacity", percent).commit();
    }
}
