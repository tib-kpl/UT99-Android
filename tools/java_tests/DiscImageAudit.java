package com.ast.ut99;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;

/** Optional real-disc audit. The ISO and extracted game files stay in build/. */
public final class DiscImageAudit {
    public static void main(String[] args) throws Exception {
        if (args.length == 1 && "--self-test".equals(args[0])) { synthetic(); return; }
        int maps = 0, plainMaps = 0;
        Set<String> paths = new HashSet<>();
        try (Ut99DiscImage disc = new Ut99DiscImage(new File(args[0]))) {
            for (Ut99DiscImage.Entry entry : disc.entries()) {
                if (!paths.add(entry.path.toLowerCase(Locale.ROOT))) throw new AssertionError("Duplicate path");
                if (entry.path.startsWith("Maps/") && entry.path.endsWith(".unr")) plainMaps++;
                if (entry.path.startsWith("Maps/") && entry.path.endsWith(".unr.uz")) {
                    byte[] expanded = Ut99RedirectDownload.decodeDiscUz(disc.bytes(entry, 32 * 1024 * 1024), 64 * 1024 * 1024);
                    if (expanded.length < 8 || (expanded[0] & 255) != 0xc1 || (expanded[1] & 255) != 0x83
                            || (expanded[2] & 255) != 0x2a || (expanded[3] & 255) != 0x9e) throw new AssertionError("Invalid map");
                    if (args.length > 1) {
                        Path target = Paths.get(args[1]).resolve(entry.path.substring(0, entry.path.length() - 3));
                        Files.createDirectories(target.getParent()); Files.write(target, expanded);
                    }
                    maps++;
                }
            }
        }
        if (maps != 81 || plainMaps != 2 || !paths.contains("system/engine.u") || !paths.contains("textures/uwindowfonts.utx"))
            throw new AssertionError("Incomplete GOTY disc: " + maps);
        System.out.println("PASS: Joliet names, unique paths, 81 compressed + 2 plain GOTY maps and required packages");
    }

    private static void integer(byte[] data, int at, int value) {
        for (int i = 0; i < 4; i++) data[at + i] = (byte)(value >>> (8 * i));
    }

    private static byte[] fixture(String name, boolean cycle) throws Exception {
        byte[] image = new byte[24 * Ut99DiscImage.SECTOR];
        int p = 16 * 2048;
        image[p] = 1; System.arraycopy("CD001".getBytes("US-ASCII"), 0, image, p + 1, 5); image[p + 6] = 1;
        image[p + 129] = 8;
        int root = p + 156; image[root] = 34; integer(image, root + 2, 20); integer(image, root + 10, 2048);
        image[root + 25] = 2; image[root + 32] = 1;
        p = 17 * 2048; image[p] = (byte)255;
        System.arraycopy("CD001".getBytes("US-ASCII"), 0, image, p + 1, 5); image[p + 6] = 1;
        p = 20 * 2048; byte[] text = name.getBytes("US-ASCII");
        image[p] = (byte)(33 + text.length); image[p + 32] = (byte)text.length;
        System.arraycopy(text, 0, image, p + 33, text.length);
        integer(image, p + 2, cycle ? 20 : 21); integer(image, p + 10, cycle ? 2048 : 4);
        if (cycle) image[p + 25] = 2;
        image[21 * 2048] = 42;
        return image;
    }

    private static void synthetic() throws Exception {
        Path dir = Files.createTempDirectory("ut99-disc-audit-");
        Path file = dir.resolve("test.iso");
        try {
            Files.write(file, fixture("Test.u", false));
            try (Ut99DiscImage disc = new Ut99DiscImage(file.toFile())) {
                if (disc.entries().size() != 1 || disc.bytes(disc.entries().get(0), 4)[0] != 42)
                    throw new AssertionError("Valid ISO read failed");
            }
            List<byte[]> bad = new ArrayList<>();
            bad.add(new byte[100]); bad.add(fixture("../escape", false)); bad.add(fixture("Cycle", true));
            byte[] outside = fixture("Test.u", false); integer(outside, 20 * 2048 + 2, 10000); bad.add(outside);
            byte[] truncated = fixture("Test.u", false); truncated[20 * 2048] = (byte)255;
            truncated[20 * 2048 + 32] = (byte)255; bad.add(truncated);
            for (byte[] image : bad) {
                Files.write(file, image);
                try (Ut99DiscImage ignored = new Ut99DiscImage(file.toFile())) {
                    throw new AssertionError("Malformed image accepted");
                } catch (IOException expected) { }
            }
            System.out.println("PASS: ISO extraction, truncation, unsafe paths, directory cycles and extent bounds");
        } finally { Files.deleteIfExists(file); Files.delete(dir); }
    }
}
