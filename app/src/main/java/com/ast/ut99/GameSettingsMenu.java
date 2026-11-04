package com.ast.ut99;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.graphics.*;
import android.graphics.drawable.*;
import android.os.Build;
import android.text.TextUtils;
import android.view.*;
import android.widget.*;
import java.util.ArrayList;
import java.util.Locale;
import org.libsdl.app.SDLActivity;

/** Instant, controller-first settings over the paused game. Original game logos, code-drawn controls. API 16+. */
final class GameSettingsMenu extends Dialog {
    interface Result { void complete(int action); }
    interface Choice { void changed(int index); }
    interface Level { void changed(int progress); }
    private final Activity activity;
    private final boolean tournament, french;
    private final int logoResource;
    private final int accent, ink = 0xffeeeae1, muted = 0xffa5a8aa;
    private final ArrayList<String> names = new ArrayList<>();
    private final ArrayList<Runnable> pages = new ArrayList<>();
    private final ArrayList<Button> tabs = new ArrayList<>();
    private final ArrayList<MenuGlyph> glyphs = new ArrayList<>();
    private LinearLayout rows;
    private ScrollView scroll;
    private TextView pageTitle;
    private int tab, railWidth;
    private boolean selectHeld, startHeld, backHeld, confirmHeld;
    private long lastAxis;
    private int axisDirection;
    private String tabPreference;

    GameSettingsMenu(Activity activity, boolean tournament, int logoResource) {
        super(activity, android.R.style.Theme_Translucent_NoTitleBar_Fullscreen);
        this.activity = activity;
        this.tournament = tournament;
        this.logoResource = logoResource;
        french = "fr".equalsIgnoreCase(activity.getResources().getConfiguration().locale.getLanguage());
        accent = tournament ? 0xffef7768 : 0xffd9b779;
        setCanceledOnTouchOutside(false);
    }

    private String text(String fr, String en) { return french ? fr : en; }
    private int dp(float value) { return Math.round(value * activity.getResources().getDisplayMetrics().density); }
    private Typeface face(boolean heading) {
        return Typeface.create(heading && !tournament ? "serif" : tournament && heading ? "sans-serif-condensed" : "sans-serif-medium",
                heading ? Typeface.BOLD : Typeface.NORMAL);
    }
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
        attributes.dimAmount = .58f;
        attributes.windowAnimations = 0;
        window.setAttributes(attributes);
        FrameLayout frame = new FrameLayout(activity);
        frame.setFitsSystemWindows(true);
        int width = activity.getResources().getConfiguration().screenWidthDp;
        railWidth = width < 560 ? 132 : width < 700 ? 160 : 184;

        LinearLayout panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.HORIZONTAL);
        panel.setBackground(new PanelBackdrop());
        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(-1, -1);
        panelParams.setMargins(dp(28), dp(18), dp(28), dp(18));
        frame.addView(panel, panelParams);

        LinearLayout rail = new LinearLayout(activity);
        rail.setOrientation(LinearLayout.VERTICAL);
        rail.setPadding(dp(16), dp(20), dp(16), dp(14));
        panel.addView(rail, new LinearLayout.LayoutParams(dp(railWidth), -1));
        ImageView logo = new ImageView(activity);
        logo.setImageResource(logoResource);
        logo.setScaleType(ImageView.ScaleType.FIT_CENTER);
        logo.setAdjustViewBounds(true);
        logo.setContentDescription(title);
        rail.addView(logo, new LinearLayout.LayoutParams(-1, dp(52)));
        TextView overline = label(text("PARAMÈTRES", "SETTINGS"), 11, muted);
        overline.setPadding(dp(10), dp(20), 0, dp(10));
        rail.addView(overline);

        for (int i = 0; i < names.size(); i++) {
            final int index = i;
            Button button = action(names.get(i), () -> select(index, true));
            button.setTextSize(13);
            button.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT);
            button.setPadding(dp(12), 0, dp(8), 0);
            button.setBackground(railBackground());
            MenuGlyph glyph = new MenuGlyph(kind(names.get(i)), muted);
            glyph.setBounds(0, 0, dp(18), dp(18));
            if (width >= 560) button.setCompoundDrawables(glyph, null, null, null);
            button.setCompoundDrawablePadding(dp(10));
            glyphs.add(glyph);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, dp(48));
            lp.bottomMargin = dp(5);
            rail.addView(button, lp);
            tabs.add(button);
        }
        rail.addView(new View(activity), new LinearLayout.LayoutParams(1, 0, 1));
        Button resume = action(text("Reprendre", "Resume"), this::dismiss);
        resume.setBackground(primaryBackground());
        resume.setTextColor(tournament ? 0xff291817 : 0xff292218);
        rail.addView(resume, new LinearLayout.LayoutParams(-1, dp(46)));
        TextView close = label("Select + Start", 11, muted);
        close.setGravity(Gravity.CENTER);
        close.setPadding(0, dp(9), 0, 0);
        rail.addView(close);

        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(22), dp(18), dp(22), dp(12));
        panel.addView(content, new LinearLayout.LayoutParams(0, -1, 1));
        LinearLayout heading = new LinearLayout(activity);
        heading.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout pageHeading = new LinearLayout(activity);
        pageHeading.setOrientation(LinearLayout.VERTICAL);
        TextView eyebrow = label(text("OPTIONS DU JEU", "GAME OPTIONS"), 11, accent);
        if (Build.VERSION.SDK_INT >= 21) eyebrow.setLetterSpacing(.12f);
        pageHeading.addView(eyebrow);
        pageTitle = label("", 24, ink);
        pageTitle.setTypeface(face(true));
        pageHeading.addView(pageTitle);
        heading.addView(pageHeading, new LinearLayout.LayoutParams(0, -2, 1));
        TextView shoulders = label("L1   /   R1", 11, muted);
        shoulders.setPadding(dp(10), dp(7), dp(10), dp(7));
        shoulders.setBackground(plate(0xff24272b, 0xff383b3d));
        heading.addView(shoulders);
        content.addView(heading);
        View divider = new View(activity);
        divider.setBackgroundColor(0xff3a3b3b);
        LinearLayout.LayoutParams dividerParams = new LinearLayout.LayoutParams(-1, dp(1));
        dividerParams.topMargin = dp(12); dividerParams.bottomMargin = dp(5);
        content.addView(divider, dividerParams);

        scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setVerticalScrollBarEnabled(false);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setSmoothScrollingEnabled(false);
        rows = new LinearLayout(activity);
        rows.setOrientation(LinearLayout.VERTICAL);
        rows.setPadding(dp(1), 0, dp(1), dp(6));
        scroll.addView(rows);
        content.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));
        TextView hint = label(text("A  Choisir       ← →  Ajuster       B  Reprendre",
                "A  Select       ← →  Adjust       B  Resume"), 11, muted);
        hint.setPadding(0, dp(10), 0, 0);
        content.addView(hint);
        setContentView(frame);
        // PhoneWindow resolves theme animations during setContentView, so clear them afterwards.
        window.setWindowAnimations(0);
        SDLActivity.mNextNativeState = SDLActivity.NativeState.PAUSED;
        SDLActivity.handleNativeState();
        super.show();
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        immersive(window);
        select(Math.max(0, Math.min(initial, pages.size() - 1)), true);
    }

    private void immersive(Window window) {
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= 19) window.getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }

    private void select(int index, boolean focusRows) {
        tab = index;
        activity.getPreferences(0).edit().putInt(tabPreference, index).apply();
        pageTitle.setText(names.get(tab));
        for (int i = 0; i < tabs.size(); i++) {
            tabs.get(i).setTextColor(i == tab ? accent : muted);
            tabs.get(i).setSelected(i == tab);
            glyphs.get(i).color(i == tab ? accent : muted);
        }
        rows.removeAllViews();
        pages.get(tab).run();
        scroll.scrollTo(0, 0);
        if (focusRows) {
            ArrayList<View> focusables = rows.getFocusables(View.FOCUS_FORWARD);
            if (!focusables.isEmpty()) focusables.get(0).post(() -> focusables.get(0).requestFocus());
        }
    }

    private TextView label(String value, int size, int color) {
        TextView view = new TextView(activity);
        view.setText(value); view.setTextSize(size); view.setTextColor(color);
        view.setIncludeFontPadding(false);
        return view;
    }

    void section(String value) {
        LinearLayout heading = new LinearLayout(activity);
        heading.setGravity(Gravity.CENTER_VERTICAL);
        heading.setPadding(dp(2), dp(14), 0, dp(8));
        TextView title = label(value.toUpperCase(Locale.ROOT), 11, accent);
        title.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL));
        heading.addView(title);
        View rule = new View(activity);
        rule.setBackgroundColor(0xff333637);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(1), 1);
        lp.leftMargin = dp(12);
        heading.addView(rule, lp);
        rows.addView(heading);
    }

    void note(String value) {
        TextView view = label(value, 12, muted);
        view.setLineSpacing(dp(2), 1);
        view.setPadding(dp(4), dp(2), dp(4), dp(9));
        rows.addView(view);
    }

    void path(String value) {
        TextView view = label(value, 12, muted);
        view.setTypeface(Typeface.MONOSPACE);
        view.setPadding(dp(12), dp(12), dp(12), dp(12));
        view.setBackground(cardBackground());
        view.setTextIsSelectable(true);
        addRow(view);
    }

    void confirm(String message, String accept, Runnable confirmed) {
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(24), dp(22), dp(24), dp(12));
        TextView title = label(text("CONFIRMATION", "CONFIRMATION"), 11, accent);
        title.setPadding(0, 0, 0, dp(12));
        body.addView(title);
        TextView copy = label(message, 16, ink);
        copy.setLineSpacing(dp(3), 1);
        body.addView(copy);
        AlertDialog dialog = new AlertDialog.Builder(activity, AlertDialog.THEME_DEVICE_DEFAULT_DARK)
                .setView(body).setNegativeButton(android.R.string.cancel, null)
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
        immersive(dialog.getWindow());
        dialog.getWindow().setBackgroundDrawable(plate(tournament ? 0xff1c242e : 0xff27241f, 0xff55524b));
        for (int which : new int[]{AlertDialog.BUTTON_NEGATIVE, AlertDialog.BUTTON_POSITIVE}) {
            Button button = dialog.getButton(which);
            button.setFocusableInTouchMode(true);
            button.setTextSize(14); button.setTextColor(ink); button.setAllCaps(false);
            button.setPadding(dp(18), dp(8), dp(18), dp(8));
            button.setBackground(cardBackground());
            if (Build.VERSION.SDK_INT >= 21) button.setStateListAnimator(null);
        }
        dialog.getButton(AlertDialog.BUTTON_NEGATIVE).requestFocus();
    }

    private GradientDrawable plate(int fill, int stroke) {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{fill, tournament ? 0xff141c25 : 0xff1b1b18});
        drawable.setCornerRadius(dp(6)); drawable.setStroke(dp(1), stroke);
        return drawable;
    }

    private StateListDrawable cardBackground() {
        StateListDrawable drawable = new StateListDrawable();
        drawable.addState(new int[]{android.R.attr.state_pressed}, plate(tournament ? 0xff473134 : 0xff4c402c, accent));
        drawable.addState(new int[]{android.R.attr.state_focused}, plate(tournament ? 0xff38282e : 0xff3c3426, accent));
        drawable.addState(new int[]{android.R.attr.state_selected}, plate(tournament ? 0xff38282e : 0xff3c3426, accent));
        drawable.addState(new int[]{}, plate(tournament ? 0xff222b35 : 0xff2b2a25, 0xff3b3e3f));
        return drawable;
    }

    private StateListDrawable railBackground() {
        StateListDrawable drawable = new StateListDrawable();
        drawable.addState(new int[]{android.R.attr.state_focused}, new RailPlate(true, true));
        drawable.addState(new int[]{android.R.attr.state_pressed}, new RailPlate(true, true));
        drawable.addState(new int[]{android.R.attr.state_selected}, new RailPlate(true, false));
        drawable.addState(new int[]{}, new RailPlate(false, false));
        return drawable;
    }

    private StateListDrawable primaryBackground() {
        StateListDrawable drawable = new StateListDrawable();
        GradientDrawable normal = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{accent, tournament ? 0xffc35a4d : 0xffb78f50});
        normal.setCornerRadius(dp(5));
        GradientDrawable focused = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{tournament ? 0xffffa18e : 0xfff5d89f, accent});
        focused.setCornerRadius(dp(5)); focused.setStroke(dp(2), ink);
        drawable.addState(new int[]{android.R.attr.state_focused}, focused);
        drawable.addState(new int[]{android.R.attr.state_pressed}, focused);
        drawable.addState(new int[]{}, normal);
        return drawable;
    }

    private Button action(String value, Runnable clicked) {
        Button button = new Button(activity);
        button.setFocusable(true); button.setFocusableInTouchMode(true);
        button.setText(value); button.setTextSize(14); button.setAllCaps(false); button.setTextColor(ink);
        button.setTypeface(face(false)); button.setMinHeight(0); button.setMinimumHeight(0);
        button.setPadding(dp(12), dp(8), dp(12), dp(8));
        button.setBackground(cardBackground());
        if (Build.VERSION.SDK_INT >= 21) button.setStateListAnimator(null);
        button.setOnClickListener(v -> clicked.run());
        return button;
    }

    private LinearLayout card(boolean focusable) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(14), dp(11), dp(14), dp(11));
        card.setMinimumHeight(dp(58));
        card.setBackground(cardBackground());
        card.setFocusable(focusable); card.setFocusableInTouchMode(focusable);
        return card;
    }

    void button(String value, Runnable clicked) {
        LinearLayout row = card(true);
        row.setMinimumHeight(dp(48));
        TextView caption = label(value.replace("…", ""), 14, ink);
        caption.setTypeface(face(false));
        row.addView(caption, new LinearLayout.LayoutParams(0, -2, 1));
        TextView arrow = label("›", 24, accent);
        arrow.setPadding(dp(12), 0, 0, 0);
        row.addView(arrow);
        row.setContentDescription(value);
        row.setOnClickListener(v -> clicked.run());
        addRow(row);
    }

    private void addRow(View view) {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.bottomMargin = dp(7);
        rows.addView(view, lp);
    }

    private String shortValue(String value) {
        int separator = value.indexOf(" · ");
        if (separator < 0 && (value.startsWith("Automatique") || value.startsWith("Automatic"))) separator = value.indexOf(" / ");
        return separator < 0 ? value : value.substring(0, separator);
    }

    private LinearLayout settingLabel(String title, String defaultValue) {
        LinearLayout labels = new LinearLayout(activity);
        labels.setOrientation(LinearLayout.VERTICAL);
        TextView caption = label(title, 14, ink);
        caption.setTypeface(face(false));
        labels.addView(caption);
        TextView hint = label(text("Défaut : ", "Default: ") + shortValue(defaultValue), 11, muted);
        hint.setPadding(0, dp(5), 0, 0);
        labels.addView(hint);
        return labels;
    }

    void choice(String title, String[] values, int initial, int defaultIndex, Choice changed) {
        final int[] current = {Math.max(0, Math.min(initial, values.length - 1))};
        LinearLayout row = card(true);
        row.addView(settingLabel(title, values[defaultIndex]), new LinearLayout.LayoutParams(0, -2, 1));
        TextView value = label("", 14, accent);
        value.setTypeface(face(false)); value.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        value.setMaxLines(2); value.setEllipsize(TextUtils.TruncateAt.END);
        value.setPadding(dp(8), 0, 0, 0);
        row.addView(value, new LinearLayout.LayoutParams(0, -2, 1));
        Runnable update = () -> {
            value.setText("‹  " + shortValue(values[current[0]]) + "  ›");
            row.setContentDescription(title + ": " + values[current[0]] + ". " + text("Par défaut : ", "Default: ") + values[defaultIndex]);
        };
        row.setOnClickListener(v -> {
            current[0] = (current[0] + 1) % values.length;
            changed.changed(current[0]); update.run();
        });
        row.setOnKeyListener((v, key, event) -> {
            if (key != KeyEvent.KEYCODE_DPAD_LEFT && key != KeyEvent.KEYCODE_DPAD_RIGHT) return false;
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                current[0] = (current[0] + (key == KeyEvent.KEYCODE_DPAD_LEFT ? values.length - 1 : 1)) % values.length;
                changed.changed(current[0]); update.run();
            }
            return true;
        });
        update.run(); addRow(row);
    }

    void slider(String title, int max, int initial, int defaultIndex, String[] values, Level changed) {
        LinearLayout card = card(false);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(14), dp(11), dp(14), dp(4));
        LinearLayout header = new LinearLayout(activity);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.addView(settingLabel(title, values[defaultIndex]), new LinearLayout.LayoutParams(0, -2, 1));
        TextView current = label(values[initial], 18, accent);
        current.setTypeface(face(false));
        current.setPadding(dp(12), 0, 0, 0);
        header.addView(current);
        card.addView(header, new LinearLayout.LayoutParams(-1, -2));
        SeekBar bar = new SeekBar(activity);
        bar.setFocusable(true); bar.setFocusableInTouchMode(true);
        bar.setBackgroundColor(Color.TRANSPARENT);
        // The card carries focus; Android's fallback highlight would cover the track in grey.
        if (Build.VERSION.SDK_INT >= 26) bar.setDefaultFocusHighlightEnabled(false);
        bar.setPadding(dp(5), 0, dp(5), 0);
        bar.setOnFocusChangeListener((v, focused) -> card.setSelected(focused));
        LayerDrawable track = new LayerDrawable(new Drawable[]{new SliderTrack(0xff4d5050),
                new ClipDrawable(new SliderTrack(accent), Gravity.LEFT, ClipDrawable.HORIZONTAL)});
        track.setId(0, android.R.id.background); track.setId(1, android.R.id.progress);
        bar.setProgressDrawable(track);
        GradientDrawable thumb = new GradientDrawable();
        thumb.setShape(GradientDrawable.OVAL); thumb.setColor(accent);
        thumb.setStroke(dp(2), tournament ? 0xfff8c6bd : 0xffffe4b0);
        thumb.setSize(dp(12), dp(12));
        bar.setThumb(thumb); bar.setMax(max); bar.setProgress(initial); bar.setKeyProgressIncrement(1);
        bar.setContentDescription(title + ". " + text("Par défaut : ", "Default: ") + values[defaultIndex]);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            public void onProgressChanged(SeekBar view, int progress, boolean fromUser) {
                current.setText(values[progress]);
                if (fromUser) changed.changed(progress);
            }
            public void onStartTrackingTouch(SeekBar view) { card.setSelected(true); }
            public void onStopTrackingTouch(SeekBar view) { card.setSelected(view.hasFocus()); }
        });
        card.addView(bar, new LinearLayout.LayoutParams(-1, dp(44)));
        addRow(card);
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
    private final class SliderTrack extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        SliderTrack(int color) { paint.setColor(color); }
        @Override public void draw(Canvas canvas) {
            Rect bounds = getBounds(); float center = bounds.exactCenterY();
            canvas.drawRoundRect(new RectF(bounds.left, center - dp(1.25f), bounds.right, center + dp(1.25f)), dp(2), dp(2), paint);
        }
        @Override public void setAlpha(int alpha) { paint.setAlpha(alpha); }
        @Override public void setColorFilter(ColorFilter filter) { paint.setColorFilter(filter); }
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }

    private final class RailPlate extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final boolean selected, focused;
        RailPlate(boolean selected, boolean focused) { this.selected = selected; this.focused = focused; }
        @Override public void draw(Canvas canvas) {
            if (!selected) return;
            RectF box = new RectF(getBounds()); box.inset(dp(1), dp(1));
            paint.setColor(tournament ? 0xff302429 : 0xff353024);
            canvas.drawRoundRect(box, dp(5), dp(5), paint);
            paint.setColor(accent);
            canvas.drawRoundRect(new RectF(box.left, box.top + dp(10), box.left + dp(3), box.bottom - dp(10)), dp(1), dp(1), paint);
            if (focused) {
                paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(dp(1)); paint.setColor(ink);
                canvas.drawRoundRect(box, dp(5), dp(5), paint); paint.setStyle(Paint.Style.FILL);
            }
        }
        @Override public void setAlpha(int alpha) { }
        @Override public void setColorFilter(ColorFilter filter) { }
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }

    private int kind(String name) {
        String value = name.toLowerCase(Locale.ROOT);
        if (value.contains("command") || value.contains("control")) return 0;
        if (value.contains("confort") || value.contains("comfort")) return 1;
        if (value.contains("affich") || value.contains("display")) return 2;
        if (value.contains("fichier") || value.contains("data")) return 4;
        return 3;
    }

    private final class MenuGlyph extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int kind;
        private int color;
        MenuGlyph(int kind, int color) { this.kind = kind; this.color = color; }
        void color(int value) { color = value; invalidateSelf(); }
        @Override public void draw(Canvas canvas) {
            Rect bounds = getBounds();
            canvas.save(); canvas.translate(bounds.left, bounds.top); canvas.scale(bounds.width() / 24f, bounds.height() / 24f);
            paint.setColor(color); paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(1.5f);
            paint.setStrokeJoin(Paint.Join.ROUND); paint.setStrokeCap(Paint.Cap.ROUND);
            if (kind == 0) {
                Path pad = new Path(); pad.moveTo(9, 3); pad.lineTo(15, 3); pad.lineTo(15, 9); pad.lineTo(21, 9);
                pad.lineTo(21, 15); pad.lineTo(15, 15); pad.lineTo(15, 21); pad.lineTo(9, 21); pad.lineTo(9, 15);
                pad.lineTo(3, 15); pad.lineTo(3, 9); pad.lineTo(9, 9); pad.close(); canvas.drawPath(pad, paint);
            } else if (kind == 1) {
                canvas.drawCircle(12, 12, 7, paint); canvas.drawCircle(12, 12, 2, paint);
                canvas.drawLine(12, 1, 12, 6, paint); canvas.drawLine(12, 18, 12, 23, paint);
                canvas.drawLine(1, 12, 6, 12, paint); canvas.drawLine(18, 12, 23, 12, paint);
            } else if (kind == 2) {
                canvas.drawRoundRect(new RectF(2, 4, 22, 17), 2, 2, paint);
                canvas.drawLine(12, 17, 12, 21, paint); canvas.drawLine(7, 21, 17, 21, paint);
            } else if (kind == 4) {
                Path folder = new Path(); folder.moveTo(2, 6); folder.lineTo(10, 6); folder.lineTo(12, 9);
                folder.lineTo(22, 9); folder.lineTo(22, 20); folder.lineTo(2, 20); folder.close(); canvas.drawPath(folder, paint);
            } else {
                Path diamond = new Path(); diamond.moveTo(12, 2); diamond.lineTo(22, 12); diamond.lineTo(12, 22);
                diamond.lineTo(2, 12); diamond.close(); canvas.drawPath(diamond, paint);
                canvas.drawCircle(12, 12, 3, paint);
            }
            canvas.restore();
        }
        @Override public void setAlpha(int alpha) { }
        @Override public void setColorFilter(ColorFilter filter) { }
        @Override public int getOpacity() { return PixelFormat.TRANSLUCENT; }
    }

    private final class PanelBackdrop extends Drawable {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        @Override public void draw(Canvas canvas) {
            Rect bounds = getBounds();
            paint.setShader(new LinearGradient(0, 0, bounds.width(), bounds.height(),
                    tournament ? 0xff202832 : 0xff302d27, 0xff111518, Shader.TileMode.CLAMP));
            canvas.drawRect(bounds, paint); paint.setShader(null);
            paint.setColor(tournament ? 0xff131a23 : 0xff1c1d1b);
            canvas.drawRect(0, 0, dp(railWidth), bounds.height(), paint);
            paint.setShader(new RadialGradient(bounds.width() * .85f, 0, bounds.width() * .65f,
                    tournament ? 0x102d708c : 0x158e6d37, Color.TRANSPARENT, Shader.TileMode.CLAMP));
            canvas.drawRect(bounds, paint); paint.setShader(null);
            paint.setColor(0xff3a3c3c); paint.setStrokeWidth(dp(1));
            canvas.drawLine(dp(railWidth), dp(18), dp(railWidth), bounds.height() - dp(18), paint);
            paint.setStyle(Paint.Style.STROKE); paint.setColor(tournament ? 0xff5c4543 : 0xff6c5c40);
            canvas.drawRect(dp(.5f), dp(.5f), bounds.width() - dp(.5f), bounds.height() - dp(.5f), paint);
            paint.setStyle(Paint.Style.FILL); paint.setColor(accent);
            canvas.drawRect(0, 0, dp(railWidth), dp(2), paint);
            canvas.drawRect(bounds.width() - dp(32), bounds.height() - dp(2), bounds.width(), bounds.height(), paint);
        }
        @Override public void setAlpha(int alpha) { }
        @Override public void setColorFilter(ColorFilter filter) { }
        @Override public int getOpacity() { return PixelFormat.OPAQUE; }
    }
}
