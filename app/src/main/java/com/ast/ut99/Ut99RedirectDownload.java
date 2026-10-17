package com.ast.ut99;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;

/** One cancellable server redirect transfer; never touches installed game files. */
public final class Ut99RedirectDownload {
    private static final int LIMIT = 256 * 1024 * 1024;
    private static volatile Job current;

    private static final class Job {
        volatile boolean cancelled;
        volatile int state, bytes, totalBytes;
        volatile HttpURLConnection connection;
        final File output;
        Job(String path, int total) { output = new File(path); totalBytes = total; }
    }

    public static synchronized boolean start(String address, String path, int size, boolean compressed) {
        cancel();
        if (size <= 0 || size > LIMIT) return false;
        Job job = new Job(path, compressed ? -1 : size);
        current = job;
        Thread worker = new Thread(() -> {
            try {
                byte[] data = fetch(job, new URL(address));
                if (compressed) data = decodeUz(data, size);
                if (data.length != size) throw new IOException("Package size mismatch");
                if (job.cancelled) return;
                try (FileOutputStream out = new FileOutputStream(job.output)) { out.write(data); }
                job.state = job.cancelled ? -1 : 1;
            } catch (Exception failure) {
                System.err.println("UT99 redirect failed: " + failure);
                job.state = -1;
            } catch (OutOfMemoryError exhausted) {
                System.err.println("UT99 redirect failed: insufficient memory for package of " + size + " bytes");
                job.state = -1;
            } finally {
                if (job.connection != null) job.connection.disconnect();
                if (job.cancelled || job.state != 1) job.output.delete();
            }
        }, "UT99-server-download");
        worker.setDaemon(true);
        worker.start();
        return true;
    }

    public static int status() { Job job = current; return job == null ? -1 : job.state; }
    public static int progress() { Job job = current; return job == null ? 0 : job.bytes; }
    /** HTTP payload size, which can differ from the expanded package size for .uz. */
    public static int total() { Job job = current; return job == null ? -1 : job.totalBytes; }
    public static synchronized void cancel() {
        Job job = current;
        current = null;
        if (job != null) {
            job.cancelled = true;
            if (job.connection != null) job.connection.disconnect();
            // The worker owns cleanup until it finishes writing.
            if (job.state != 0) job.output.delete();
        }
    }

    private static byte[] fetch(Job job, URL url) throws IOException {
        for (int redirects = 0; redirects <= 5; redirects++) {
            String scheme = url.getProtocol();
            if ((!"http".equalsIgnoreCase(scheme) && !"https".equalsIgnoreCase(scheme))
                    || url.getUserInfo() != null) throw new IOException("Unsupported redirect URL");
            if (job.cancelled) throw new IOException("Cancelled");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            job.connection = connection;
            connection.setInstanceFollowRedirects(false);
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);
            connection.setRequestProperty("Accept-Encoding", "identity");
            try {
                int code = connection.getResponseCode();
                if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
                    String location = connection.getHeaderField("Location");
                    if (location == null) throw new IOException("Missing redirect location");
                    url = new URL(url, location);
                    continue;
                }
                if (code != 200) throw new IOException("HTTP " + code);
                long length = connection.getContentLength();
                if (length > LIMIT) throw new IOException("Download too large");
                if (length >= 0) job.totalBytes = (int)length;
                try (InputStream in = connection.getInputStream();
                     ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                    byte[] block = new byte[32768];
                    int count;
                    while ((count = in.read(block)) != -1) {
                        if (job.cancelled) throw new IOException("Cancelled");
                        if (count > LIMIT - out.size()) throw new IOException("Download too large");
                        out.write(block, 0, count);
                        job.bytes = out.size();
                    }
                    if (length >= 0 && out.size() != length) throw new IOException("Truncated download");
                    job.totalBytes = out.size();
                    return out.toByteArray();
                }
            } finally { connection.disconnect(); }
        }
        throw new IOException("Too many redirects");
    }

    // UE1 .uz: header, Huffman, optional RLE, move-to-front, BWT, RLE.
    // All reads, tree sizes, block indices and expansion sizes are bounded.
    static byte[] decodeUz(byte[] data, int expected) throws IOException {
        if (expected < 0) throw new IOException("Invalid expected UZ size");
        return decodeUz(data, expected, expected);
    }

    // Disc images do not provide the expanded map size. Keep a separate bounded
    // entry point so network downloads still require an exact advertised size.
    static byte[] decodeDiscUz(byte[] data, int maximum) throws IOException {
        if (maximum <= 0 || maximum > LIMIT) throw new IOException("Invalid UZ limit");
        return decodeUz(data, -1, maximum);
    }

    private static byte[] decodeUz(byte[] data, int expected, int maximum) throws IOException {
        Cursor input = new Cursor(data);
        int signature = input.integer();
        if (signature != 1234 && signature != 5678) throw new IOException("Unknown UZ format");
        int nameLength = input.compact();
        if (nameLength == Integer.MIN_VALUE || Math.abs(nameLength) > 1024) throw new IOException("Invalid UZ name");
        input.skip(Math.abs(nameLength) * (nameLength < 0 ? 2 : 1));
        int bound = (int)Math.min(LIMIT, (long)maximum * 2 + 1048576);
        int decoded = input.integer();
        if (decoded < 0 || decoded > bound) throw new IOException("Invalid Huffman size");
        Bits bits = new Bits(input);
        int[][] tree = new int[511][3];
        int[] nodes = {0};
        readTree(bits, tree, nodes, 0);
        byte[] buffer = new byte[decoded];
        for (int i = 0; i < decoded; i++) {
            int node = 0;
            while (tree[node][0] < 0) node = tree[node][1 + bits.bit()];
            buffer[i] = (byte)tree[node][0];
        }
        if (signature == 5678) buffer = rle(buffer, bound);
        int[] alphabet = new int[256];
        for (int i = 0; i < 256; i++) alphabet[i] = i;
        for (int i = 0; i < buffer.length; i++) {
            int index = buffer[i] & 255, value = alphabet[index];
            System.arraycopy(alphabet, 0, alphabet, 1, index);
            alphabet[0] = value;
            buffer[i] = (byte)value;
        }
        // Determine the exact output size first. Growing streams and their final
        // copies can otherwise exhaust Android's heap for a 40 MB package.
        input = new Cursor(buffer);
        int outputSize = 0;
        while (input.position < buffer.length) {
            int length = input.integer(), first = input.integer(), last = input.integer();
            if (length < 0 || length > 0x40000 || first < 0 || first > length
                    || last < 0 || last > length) throw new IOException("Invalid BWT block");
            input.skip(length + 1);
            if (length > bound - outputSize) throw new IOException("BWT expansion too large");
            outputSize += length;
        }
        byte[] output = new byte[outputSize];
        int outputPosition = 0;
        input = new Cursor(buffer);
        while (input.position < buffer.length) {
            int length = input.integer(), first = input.integer(), last = input.integer();
            if (length < 0 || length > 0x40000 || first < 0 || first > length
                    || last < 0 || last > length) throw new IOException("Invalid BWT block");
            int start = input.position;
            input.skip(length + 1);
            int[] counts = new int[257], offsets = new int[257], next = new int[length + 1];
            for (int i = 0; i <= length; i++) counts[i == last ? 256 : buffer[start + i] & 255]++;
            int total = 0;
            for (int i = 0; i < 257; i++) { offsets[i] = total; total += counts[i]; }
            Arrays.fill(counts, 0);
            for (int i = 0; i <= length; i++) {
                int value = i == last ? 256 : buffer[start + i] & 255;
                next[offsets[value] + counts[value]++] = i;
            }
            for (int node = first, i = 0; i < length; i++, node = next[node]) output[outputPosition++] = buffer[start + node];
        }
        byte[] result = rle(output, maximum);
        if (expected >= 0 && result.length != expected) throw new IOException("UZ size mismatch");
        return result;
    }

    private static int readTree(Bits bits, int[][] tree, int[] nodes, int depth) throws IOException {
        if (nodes[0] >= tree.length || depth > 255) throw new IOException("Invalid Huffman tree");
        int index = nodes[0]++;
        if (bits.bit() == 0) tree[index][0] = bits.byteValue();
        else {
            tree[index][0] = -1;
            tree[index][1] = readTree(bits, tree, nodes, depth + 1);
            tree[index][2] = readTree(bits, tree, nodes, depth + 1);
        }
        return index;
    }

    private static byte[] rle(byte[] data, int bound) throws IOException {
        int size = rleSize(data, bound);
        byte[] output = new byte[size];
        int position = 0, previous = -1, run = 0;
        for (int i = 0; i < data.length; i++) {
            int value = data[i] & 255;
            output[position++] = (byte)value;
            run = value == previous ? run + 1 : 1;
            previous = value;
            if (run == 5) {
                int extra = (data[++i] & 255) - 5;
                Arrays.fill(output, position, position + extra, (byte)value);
                position += extra;
                run = 0;
            }
        }
        return output;
    }

    private static int rleSize(byte[] data, int bound) throws IOException {
        int size = 0;
        int previous = -1, run = 0;
        for (int i = 0; i < data.length; i++) {
            int value = data[i] & 255;
            if (size >= bound) throw new IOException("RLE expansion too large");
            size++;
            run = value == previous ? run + 1 : 1;
            previous = value;
            if (run == 5) {
                if (++i >= data.length) throw new IOException("Truncated RLE run");
                int count = data[i] & 255;
                if (count < 5 || count - 5 > bound - size) throw new IOException("Invalid RLE run");
                size += count - 5;
                run = 0;
            }
        }
        return size;
    }

    private static final class Cursor {
        final byte[] data;
        int position;
        Cursor(byte[] data) { this.data = data; }
        int value() throws IOException {
            if (position >= data.length) throw new IOException("Truncated UZ data");
            return data[position++] & 255;
        }
        int integer() throws IOException { return value() | value()<<8 | value()<<16 | value()<<24; }
        void skip(int count) throws IOException {
            if (count < 0 || count > data.length - position) throw new IOException("Truncated UZ header");
            position += count;
        }
        int compact() throws IOException {
            int first = value(), result = first & 63, shift = 6, next = first;
            for (int i = 0; (next & (i == 0 ? 64 : 128)) != 0; i++) {
                if (i >= 4) throw new IOException("Invalid compact index");
                next = value(); result |= (next & 127) << shift; shift += 7;
            }
            return (first & 128) != 0 ? -result : result;
        }
    }

    private static final class Bits {
        final Cursor input;
        int value, remaining;
        Bits(Cursor input) { this.input = input; }
        int bit() throws IOException {
            if (remaining == 0) { value = input.value(); remaining = 8; }
            int bit = value & 1; value >>>= 1; remaining--; return bit;
        }
        int byteValue() throws IOException {
            int value = 0;
            for (int i = 0; i < 8; i++) value |= bit() << i;
            return value;
        }
    }
}
