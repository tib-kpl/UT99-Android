package com.ast.ut99;

import android.app.Activity;
import android.app.Dialog;
import android.app.AlertDialog;
import android.graphics.*;
import android.graphics.drawable.*;
import android.os.Build;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.text.style.RelativeSizeSpan;
import android.view.*;
import android.widget.*;
import java.util.ArrayList;
import java.util.Locale;
import org.libsdl.app.SDLActivity;

/** Code-drawn game-themed settings, shared in design with the UT99 port. API 16+. */
final class GameSettingsMenu extends Dialog {
    interface Result { void complete(int action); }
    interface Choice { void changed(int index); }
    interface Level { void changed(int progress); }
    private final Activity activity;
    private final boolean tournament, french;
    private final int accent, ink = 0xffeae4d8;
    private final ArrayList<String> names = new ArrayList<>();
    private final ArrayList<Runnable> pages = new ArrayList<>();
    private final ArrayList<Button> tabs = new ArrayList<>();
    private LinearLayout rows;
    private ScrollView scroll;
    private int tab;
    private boolean selectHeld, startHeld, backHeld, confirmHeld;
    private long lastAxis;
    private int axisDirection;
    private String tabPreference;

    GameSettingsMenu(Activity activity, boolean tournament) {
        super(activity, android.R.style.Theme_Translucent_NoTitleBar_Fullscreen);
        this.activity = activity;
        setCanceledOnTouchOutside(false);
        this.tournament = tournament;
        french = "fr".equalsIgnoreCase(activity.getResources().getConfiguration().locale.getLanguage());
        accent = tournament ? 0xffec625a : 0xffd2aa65;
    }

    private String text(String fr, String en) { return french ? fr : en; }
    private int dp(float value) { return Math.round(value * activity.getResources().getDisplayMetrics().density); }
    int selectedTab() { return tab; }
    void refresh() { select(tab, true); }
    void page(String name, Runnable build) { names.add(name); pages.add(build); }

    void show(String title, String subtitle, int initial) {
        tabPreference = "tab_" + title;
        if (initial < 0) initial = activity.getPreferences(0).getInt(tabPreference, 0);
        Window window = getWindow();
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_DIM_BEHIND);
        WindowManager.LayoutParams attributes = window.getAttributes();
        attributes.dimAmount = .55f;
        attributes.windowAnimations = 0;
        window.setAttributes(attributes);
        window.setWindowAnimations(0);
        FrameLayout frame = new FrameLayout(activity);
        frame.setBackgroundColor(Color.TRANSPARENT);
        // Insets are handled by the window; do not draw controls under cutouts/system bars.
        frame.setFitsSystemWindows(true);
        LinearLayout panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackground(new Backdrop());
        panel.setPadding(dp(16), dp(8), dp(16), dp(8));
        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(-1, -1);
        panelParams.setMargins(dp(24), dp(18), dp(24), dp(18));
        frame.addView(panel, panelParams);

        LinearLayout header = new LinearLayout(activity);
        header.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout titles = new LinearLayout(activity);
        titles.setOrientation(LinearLayout.VERTICAL);
        TextView wordmark = label(title, 25, accent);
        wordmark.setTypeface(Typeface.create(tournament ? "sans-serif-condensed" : "serif", Typeface.BOLD));
        titles.addView(wordmark);
        titles.addView(label(subtitle, 12, 0xffa8acb4));
        header.addView(titles, new LinearLayout.LayoutParams(0, -2, 1));
        Button back = action(text("Reprendre", "Resume"), this::dismiss);
        header.addView(back, new LinearLayout.LayoutParams(-2, dp(48)));
        panel.addView(header);

        HorizontalScrollView tabScroll = new HorizontalScrollView(activity);
        tabScroll.setHorizontalScrollBarEnabled(false);
        LinearLayout strip = new LinearLayout(activity);
        for (int i = 0; i < names.size(); i++) {
            final int index = i;
            Button button = action(names.get(i), () -> select(index, true));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-2, dp(48));
            lp.setMargins(0, dp(6), dp(6), dp(6));
            strip.addView(button, lp);
            tabs.add(button);
        }
        tabScroll.addView(strip);
        panel.addView(tabScroll);
        scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        rows = new LinearLayout(activity);
        rows.setOrientation(LinearLayout.VERTICAL);
        rows.setPadding(dp(2), dp(4), dp(2), dp(8));
        scroll.addView(rows);
        panel.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        TextView hint = label(text("L1 / R1 : onglets   •   A : valider   •   B : retour   •   Select + Start : fermer",
                "L1 / R1: tabs   •   A: confirm   •   B: back   •   Select + Start: close"), 11, 0xffa8acb4);
        hint.setPadding(0, dp(6), 0, 0);
        panel.addView(hint);
        setContentView(frame);
        // PhoneWindow resolves its theme during setContentView; clear animation afterwards.
        window.setWindowAnimations(0);
        SDLActivity.mNextNativeState = SDLActivity.NativeState.PAUSED;
        SDLActivity.handleNativeState();
        super.show();
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        if (Build.VERSION.SDK_INT >= 19) frame.setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        select(Math.max(0, Math.min(initial, pages.size() - 1)), false);
        back.requestFocus();
    }

    private void select(int index, boolean focusRows) {
        tab = index;
        activity.getPreferences(0).edit().putInt(tabPreference, index).apply();
        for (int i = 0; i < tabs.size(); i++) {
            tabs.get(i).setTextColor(i == tab ? accent : ink);
            tabs.get(i).setSelected(i == tab);
        }
        rows.removeAllViews();
        pages.get(tab).run();
        scroll.scrollTo(0, 0);
        if (focusRows) {
            View first = rows.getFocusables(View.FOCUS_FORWARD).isEmpty() ? null
                    : rows.getFocusables(View.FOCUS_FORWARD).get(0);
            if (first != null) first.post(() -> first.requestFocus());
        }
    }

    private TextView label(String value, int size, int color) {
        TextView view = new TextView(activity);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(color);
        return view;
    }

    void section(String value) {
        TextView view = label(value.toUpperCase(Locale.ROOT), 13, accent);
        view.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        view.setPadding(dp(4), dp(10), 0, dp(6));
        rows.addView(view);
    }

    void note(String value) {
        TextView view = label(value, 13, 0xffaeb4be);
        view.setPadding(dp(6), dp(4), dp(6), dp(10));
        rows.addView(view);
    }

    void path(String value) {
        TextView view = label(value, 13, 0xffaeb4be);
        view.setTypeface(Typeface.MONOSPACE);
        view.setPadding(dp(6), dp(4), dp(6), dp(10));
        view.setTextIsSelectable(true);
        rows.addView(view);
    }

    void confirm(String message, String accept, Runnable confirmed) {
        AlertDialog dialog = new AlertDialog.Builder(activity, AlertDialog.THEME_DEVICE_DEFAULT_DARK)
                .setMessage(message).setNegativeButton(android.R.string.cancel, null)
                .setPositiveButton(accept, (d, which) -> confirmed.run()).create();
        dialog.setOnKeyListener((d, key, event) -> {
            if (key == KeyEvent.KEYCODE_BUTTON_A) {
                if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled()) {
                    View focus = dialog.getCurrentFocus();
                    if (focus != null) focus.performClick();
                }
                return true;
            }
            if (key == KeyEvent.KEYCODE_BUTTON_B) {
                if (event.getAction() == KeyEvent.ACTION_UP) dialog.cancel();
                return true;
            }
            return false;
        });
        dialog.getWindow().getDecorView();
        dialog.getWindow().setWindowAnimations(0);
        dialog.show();
        dialog.getWindow().setWindowAnimations(0);
        dialog.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= 19) dialog.getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        dialog.getWindow().setBackgroundDrawable(plate(tournament ? 0xff233449 : 0xff302c26, accent));
        for (int which : new int[]{AlertDialog.BUTTON_NEGATIVE, AlertDialog.BUTTON_POSITIVE}) {
            Button button = dialog.getButton(which);
            button.setFocusableInTouchMode(true);
            button.setTextColor(ink);
            button.setAllCaps(false);
            button.setBackground(background());
        }
        dialog.getButton(AlertDialog.BUTTON_NEGATIVE).requestFocus();
    }

    private GradientDrawable plate(int fill, int stroke) {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{fill, tournament ? 0xff101a29 : 0xff181715});
        drawable.setCornerRadius(dp(3));
        drawable.setStroke(dp(1), stroke);
        return drawable;
    }

    private StateListDrawable background() {
        StateListDrawable drawable = new StateListDrawable();
        drawable.addState(new int[]{android.R.attr.state_pressed}, plate(0xff575047, accent));
        drawable.addState(new int[]{android.R.attr.state_focused}, plate(tournament ? 0xff3b2833 : 0xff433a2c, accent));
        drawable.addState(new int[]{android.R.attr.state_selected}, plate(0xff30323a, accent));
        drawable.addState(new int[]{}, plate(tournament ? 0xff233449 : 0xff302c26, 0xff50515a));
        return drawable;
    }

    private Button action(String value, Runnable clicked) {
        Button button = new Button(activity);
        button.setFocusable(true);
        button.setFocusableInTouchMode(true);
        button.setText(value);
        button.setTextSize(14);
        button.setAllCaps(false);
        button.setTextColor(ink);
        button.setMinHeight(dp(48));
        button.setMinimumHeight(dp(48));
        button.setPadding(dp(14), dp(6), dp(14), dp(6));
        button.setBackground(background());
        button.setOnClickListener(v -> clicked.run());
        return button;
    }

    void button(String value, Runnable clicked) {
        Button button = action(value + "   ›", clicked);
        button.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT);
        addRow(button);
    }

    private void addRow(View view) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.bottomMargin = dp(6);
        rows.addView(view, lp);
    }

    private CharSequence withDefault(String primary, String value) {
        String hint = text("Par défaut : ", "Default: ") + value;
        SpannableString result = new SpannableString(primary + "\n" + hint);
        int start = primary.length() + 1;
        result.setSpan(new ForegroundColorSpan(0xffaeb4be), start, result.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        result.setSpan(new RelativeSizeSpan(.82f), start, result.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        return result;
    }

    void choice(String title, String[] values, int initial, int defaultIndex, Choice changed) {
        final int[] current = {Math.max(0, Math.min(initial, values.length - 1))};
        final Button button = action("", () -> {});
        Runnable update = () -> {
            button.setText(withDefault(title + "\n‹   " + values[current[0]] + "   ›", values[defaultIndex]));
            button.setContentDescription(title + ": " + values[current[0]] + ". " + text("Par défaut : ", "Default: ") + values[defaultIndex]);
        };
        button.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT);
        button.setOnClickListener(v -> {
            current[0] = (current[0] + 1) % values.length;
            changed.changed(current[0]); update.run();
        });
        button.setOnKeyListener((v, key, event) -> {
            if (key != KeyEvent.KEYCODE_DPAD_LEFT && key != KeyEvent.KEYCODE_DPAD_RIGHT) return false;
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                current[0] = (current[0] + (key == KeyEvent.KEYCODE_DPAD_LEFT ? values.length - 1 : 1)) % values.length;
                changed.changed(current[0]); update.run();
            }
            return true;
        });
        update.run(); addRow(button);
    }

    void slider(String title, int max, int initial, int defaultIndex, String[] values, Level changed) {
        TextView caption = label("", 14, ink);
        caption.setText(withDefault(title + "  " + values[initial], values[defaultIndex]));
        caption.setPadding(dp(6), dp(8), 0, 0);
        rows.addView(caption);
        SeekBar bar = new SeekBar(activity);
        bar.setFocusable(true); bar.setFocusableInTouchMode(true);
        StateListDrawable sliderFocus = new StateListDrawable();
        sliderFocus.addState(new int[]{android.R.attr.state_focused}, plate(tournament ? 0xff3b2833 : 0xff433a2c, accent));
        sliderFocus.addState(new int[]{android.R.attr.state_pressed}, plate(tournament ? 0xff3b2833 : 0xff433a2c, accent));
        sliderFocus.addState(new int[]{}, new ColorDrawable(Color.TRANSPARENT));
        bar.setBackground(sliderFocus);
        LayerDrawable track = new LayerDrawable(new Drawable[]{new SliderTrack(0xff484438),
                new ClipDrawable(new SliderTrack(accent), Gravity.LEFT, ClipDrawable.HORIZONTAL)});
        track.setId(0, android.R.id.background);
        track.setId(1, android.R.id.progress);
        bar.setProgressDrawable(track);
        GradientDrawable thumb = new GradientDrawable();
        thumb.setShape(GradientDrawable.OVAL);
        thumb.setColor(accent);
        thumb.setSize(dp(14), dp(14));
        bar.setThumb(thumb);
        bar.setMax(max); bar.setProgress(initial);
        bar.setContentDescription(title);
        bar.setKeyProgressIncrement(1);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            public void onProgressChanged(SeekBar view, int progress, boolean fromUser) {
                caption.setText(withDefault(title + "  " + values[progress], values[defaultIndex]));
                if (fromUser) changed.changed(progress);
            }
            public void onStartTrackingTouch(SeekBar view) { }
            public void onStopTrackingTouch(SeekBar view) { }
        });
        rows.addView(bar, new LinearLayout.LayoutParams(-1, dp(48)));
    }

    boolean key(KeyEvent event) {
        int code = event.getKeyCode();
        boolean down = event.getAction() == KeyEvent.ACTION_DOWN;
        if (code == KeyEvent.KEYCODE_BUTTON_L1 || code == KeyEvent.KEYCODE_BUTTON_R1) {
            if (down && event.getRepeatCount() == 0) select((tab + (code == KeyEvent.KEYCODE_BUTTON_L1 ? pages.size() - 1 : 1)) % pages.size(), true);
            return true;
        }
        if (code == KeyEvent.KEYCODE_BUTTON_SELECT || code == KeyEvent.KEYCODE_BUTTON_START) {
            // Opening releases/repeats do not close the new screen. Require fresh presses.
            if (!down || event.getRepeatCount() == 0) {
                if (code == KeyEvent.KEYCODE_BUTTON_SELECT) selectHeld = down;
                else startHeld = down;
                if (selectHeld && startHeld) dismiss();
            }
            return true;
        }
        if (code == KeyEvent.KEYCODE_BUTTON_B || code == KeyEvent.KEYCODE_BACK) {
            // BACK can also be a pad's Select: ignore the release that opened this screen.
            if (down && event.getRepeatCount() == 0) backHeld = true;
            if (!down) {
                if (backHeld && !event.isCanceled()) dismiss();
                backHeld = false;
            }
            return true;
        }
        if (code == KeyEvent.KEYCODE_BUTTON_A) {
            if (down && event.getRepeatCount() == 0) confirmHeld = true;
            if (!down) {
                View focus = getCurrentFocus();
                if (confirmHeld && !event.isCanceled() && focus != null) focus.performClick();
                confirmHeld = false;
            }
            return true;
        }
        return false;
    }

    boolean motion(MotionEvent event) {
        if ((event.getSource() & InputDevice.SOURCE_JOYSTICK) != InputDevice.SOURCE_JOYSTICK) return false;
        float x = event.getAxisValue(MotionEvent.AXIS_HAT_X), y = event.getAxisValue(MotionEvent.AXIS_HAT_Y);
        if (Math.abs(x) < .5f && Math.abs(y) < .5f) { x = event.getAxisValue(MotionEvent.AXIS_X); y = event.getAxisValue(MotionEvent.AXIS_Y); }
        int key = Math.abs(y) >= Math.abs(x) && Math.abs(y) > .6f ? (y < 0 ? KeyEvent.KEYCODE_DPAD_UP : KeyEvent.KEYCODE_DPAD_DOWN)
                : Math.abs(x) > .6f ? (x < 0 ? KeyEvent.KEYCODE_DPAD_LEFT : KeyEvent.KEYCODE_DPAD_RIGHT) : 0;
        if (key == 0) axisDirection = 0;
        else if (axisDirection != key || event.getEventTime() - lastAxis > 200) {
            axisDirection = key; lastAxis = event.getEventTime();
            dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, key));
            dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_UP, key));
        }
        return true;
    }

    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        return key(event) || super.dispatchKeyEvent(event);
    }

    @Override public boolean dispatchGenericMotionEvent(MotionEvent event) {
        return motion(event) || super.dispatchGenericMotionEvent(event);
    }

    @Override public void dismiss() {
        super.dismiss();
        if (!activity.isFinishing() && !activity.isChangingConfigurations()) {
            // handleNativeState waits for the game's window focus before actually resuming.
            SDLActivity.mNextNativeState = SDLActivity.NativeState.RESUMED;
            SDLActivity.handleNativeState();
        }
    }

    /** Keep the slider independent of the engine Activity's Holo/Material theme. */
    private final class SliderTrack extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        SliderTrack(int color) { paint.setColor(color); }
        @Override public void draw(Canvas canvas) {
            Rect bounds = getBounds();
            float center = bounds.exactCenterY();
            canvas.drawRect(bounds.left, center - dp(1), bounds.right, center + dp(1), paint);
        }
        @Override public void setAlpha(int alpha) { paint.setAlpha(alpha); }
        @Override public void setColorFilter(ColorFilter filter) { paint.setColorFilter(filter); }
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }

    /** Stone/bronze for Unreal, blue gunmetal/red for the Tournament. No game assets. */
    private final class Backdrop extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        @Override public void draw(Canvas canvas) {
            Rect bounds = getBounds();
            paint.setShader(new LinearGradient(0, 0, bounds.width(), bounds.height(),
                    tournament ? 0xff162d48 : 0xff322b20, 0xff080b10, Shader.TileMode.CLAMP));
            canvas.drawRect(bounds, paint); paint.setShader(null);
            paint.setColor(tournament ? 0x133b7199 : 0x13bc9b62);
            paint.setStrokeWidth(dp(1));
            for (int y = 0; y < bounds.height(); y += dp(32)) canvas.drawLine(0, y, bounds.width(), y, paint);
            paint.setTypeface(Typeface.create("serif", Typeface.BOLD_ITALIC));
            paint.setTextSize(bounds.height() * .85f); paint.setColor(tournament ? 0x0e81b8e4 : 0x0ebc9b62);
            canvas.drawText("U", bounds.width() * .66f, bounds.height() * .92f, paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(dp(1)); paint.setColor(accent);
            canvas.drawRect(dp(10), dp(8), bounds.width() - dp(10), bounds.height() - dp(8), paint);
            paint.setStyle(Paint.Style.FILL);
            canvas.drawRect(dp(10), dp(8), dp(86), dp(11), paint);
        }
        @Override public void setAlpha(int alpha) { }
        @Override public void setColorFilter(ColorFilter filter) { }
        @Override public int getOpacity() { return PixelFormat.OPAQUE; }
    }
}
