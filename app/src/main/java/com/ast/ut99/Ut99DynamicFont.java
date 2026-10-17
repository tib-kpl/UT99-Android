package com.ast.ut99;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;

/** Builds bounded glyph pages for the native Canvas.CreateFont API. */
public final class Ut99DynamicFont {
    private Ut99DynamicFont() {}

    public static int[] build(int family, int size, int flags, String glyphs) {
        if (size < 1 || size > 128 || glyphs == null || glyphs.length() > 256) return null;
        Paint paint = new Paint((flags & 8) != 0 ? Paint.ANTI_ALIAS_FLAG : 0);
        String name = family == 1 ? "serif" : family == 2 ? "monospace" : "sans-serif";
        paint.setTypeface(Typeface.create(name, ((flags & 1) != 0 ? Typeface.BOLD : 0)
                | ((flags & 2) != 0 ? Typeface.ITALIC : 0)));
        paint.setTextSize(size);
        paint.setUnderlineText((flags & 4) != 0);
        paint.setColor(Color.WHITE);
        Paint.FontMetricsInt fm = paint.getFontMetricsInt();
        int lineHeight = Math.max(1, fm.bottom - fm.top);
        int[] widths = new int[glyphs.length()];
        int widest = 1;
        long area = 0;
        for (int i = 0; i < widths.length; i++) {
            widths[i] = Math.max(1, (int) Math.ceil(paint.measureText(glyphs, i, i + 1)));
            widest = Math.max(widest, widths[i]);
            area += (long) (widths[i] + 2) * (lineHeight + 2);
        }
        int width = 256;
        while (width < widest + 2) width *= 2;
        while (width < 2048 && (long) width * width < area) width *= 2;
        int[] metrics = new int[glyphs.length() * 4];
        int x = 1, y = 1;
        for (int i = 0; i < widths.length; i++) {
            if (x + widths[i] + 1 > width) { x = 1; y += lineHeight + 2; }
            metrics[i * 4] = x;
            metrics[i * 4 + 1] = y;
            metrics[i * 4 + 2] = widths[i];
            metrics[i * 4 + 3] = lineHeight;
            x += widths[i] + 2;
        }
        int height = 1;
        while (height < y + lineHeight + 1) height *= 2;
        if (height > 4096 || (long) width * height > 4 * 1024 * 1024) return null;
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        try {
            Canvas canvas = new Canvas(bitmap);
            for (int i = 0; i < glyphs.length(); i++) {
                if (Character.isISOControl(glyphs.charAt(i))) continue;
                canvas.drawText(glyphs, i, i + 1, metrics[i * 4], metrics[i * 4 + 1] - fm.top, paint);
            }
            int[] result = new int[2 + metrics.length + width * height];
            result[0] = width;
            result[1] = height;
            System.arraycopy(metrics, 0, result, 2, metrics.length);
            bitmap.getPixels(result, 2 + metrics.length, width, 0, 0, width, height);
            return result;
        } finally {
            bitmap.recycle();
        }
    }
}
