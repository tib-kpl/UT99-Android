package com.ast.ut99;

import java.io.*;
import java.util.*;

/** Read-only ISO9660/Joliet reader for the original UT GOTY disc. No mounting. */
final class Ut99DiscImage implements Closeable {
    static final int SECTOR = 2048;
    static final class Entry {
        final String path;
        final long offset, size;
        Entry(String path, long offset, long size) {
            this.path = path; this.offset = offset; this.size = size;
        }
    }
    private final RandomAccessFile file;
    private final long length;
    private final List<Entry> entries = new ArrayList<>();
    private final Set<Long> visited = new HashSet<>();
    private boolean joliet;

    Ut99DiscImage(File image) throws IOException {
        file = new RandomAccessFile(image, "r");
        length = file.length();
        try {
            byte[] primary = null, supplementary = null;
            for (int sector = 16; sector < 80; sector++) {
                byte[] descriptor = read((long)sector * SECTOR, SECTOR);
                if (!"CD001".equals(new String(descriptor, 1, 5, "US-ASCII")) || descriptor[6] != 1)
                    throw new IOException("Invalid ISO descriptor");
                int type = descriptor[0] & 255;
                if (type == 1) primary = descriptor;
                if (type == 2 && descriptor[88] == '%' && descriptor[89] == '/'
                        && (descriptor[90] == '@' || descriptor[90] == 'C' || descriptor[90] == 'E'))
                    supplementary = descriptor;
                if (type == 255) break;
            }
            if (primary == null) throw new IOException("ISO primary descriptor missing");
            joliet = supplementary != null;
            byte[] descriptor = joliet ? supplementary : primary;
            int block = (descriptor[128] & 255) | ((descriptor[129] & 255) << 8);
            if (block != SECTOR) throw new IOException("Unsupported ISO sector size");
            walk(descriptor, 156, "", 0);
        } catch (IOException | RuntimeException error) {
            file.close();
            throw error;
        }
    }

    List<Entry> entries() { return Collections.unmodifiableList(entries); }

    private static long number(byte[] data, int at) throws IOException {
        if (at < 0 || at + 4 > data.length) throw new IOException("Truncated ISO number");
        long value = 0;
        for (int i = 0; i < 4; i++) value |= (long)(data[at + i] & 255) << (8 * i);
        return value;
    }

    private byte[] read(long offset, int size) throws IOException {
        if (offset < 0 || size < 0 || offset > length - size) throw new IOException("ISO extent outside image");
        byte[] data = new byte[size];
        file.seek(offset); file.readFully(data);
        return data;
    }

    private void walk(byte[] record, int at, String parent, int depth) throws IOException {
        if (depth > 12 || at < 0 || at + 34 > record.length) throw new IOException("Invalid ISO directory");
        long offset = number(record, at + 2) * SECTOR, size = number(record, at + 10);
        if (size > 4 * 1024 * 1024 || !visited.add(offset)) throw new IOException("Oversized or cyclic ISO directory");
        byte[] data = read(offset, (int)size);
        for (int p = 0; p < data.length;) {
            int count = data[p] & 255;
            if (count == 0) { p = (p / SECTOR + 1) * SECTOR; continue; }
            if (count < 34 || p + count > data.length) throw new IOException("Truncated ISO directory record");
            int names = data[p + 32] & 255;
            if (33 + names > count) throw new IOException("Truncated ISO filename");
            if (!(names == 1 && (data[p + 33] == 0 || data[p + 33] == 1))) {
                if (joliet && (names & 1) != 0) throw new IOException("Invalid Joliet filename");
                String name = new String(data, p + 33, names, joliet ? "UTF-16BE" : "US-ASCII");
                int version = name.indexOf(';');
                if (version >= 0) name = name.substring(0, version);
                if (name.isEmpty() || name.equals(".") || name.equals("..")
                        || name.indexOf('/') >= 0 || name.indexOf('\\') >= 0 || name.indexOf('\0') >= 0
                        || name.indexOf(':') >= 0) throw new IOException("Unsafe ISO filename");
                String path = parent.isEmpty() ? name : parent + "/" + name;
                int flags = data[p + 25] & 255;
                if ((flags & 0x80) != 0) throw new IOException("Multi-extent ISO files unsupported");
                if ((flags & 2) != 0) walk(data, p, path, depth + 1);
                else {
                    long start = number(data, p + 2) * SECTOR, bytes = number(data, p + 10);
                    if (start > length - bytes || entries.size() >= 20000) throw new IOException("Invalid ISO file extent");
                    entries.add(new Entry(path, start, bytes));
                }
            }
            p += count;
        }
    }

    byte[] bytes(Entry entry, int maximum) throws IOException {
        if (entry.size > maximum) throw new IOException("ISO file exceeds limit: " + entry.path);
        return read(entry.offset, (int)entry.size);
    }

    void copy(Entry entry, OutputStream output) throws IOException {
        file.seek(entry.offset);
        byte[] buffer = new byte[65536];
        long remaining = entry.size;
        while (remaining > 0) {
            int n = file.read(buffer, 0, (int)Math.min(buffer.length, remaining));
            if (n < 0) throw new EOFException("Truncated ISO file");
            output.write(buffer, 0, n); remaining -= n;
        }
    }

    @Override public void close() throws IOException { file.close(); }
}
