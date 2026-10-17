package com.ast.ut99;

import org.json.*;
import java.io.*;
import java.net.*;
import java.security.*;
import java.util.*;
import java.util.zip.*;

/** Installs official game media as data only; never executes desktop binaries. */
final class Ut99GotyInstaller {
    interface Progress { void update(String phase, int percent); }
    static final String RELEASE = "https://api.github.com/repos/OldUnreal/UnrealTournamentPatches/releases/latest";
    private static final long ISO_SIZE = 649633792L;
    private static final String ISO_MD5 = "e5127537f44086f5ed36a9d29f992c00";
    private static final String[] MIRRORS = {"https://files.oldunreal.net/UT_GOTY_CD1.ISO",
            "https://files2.oldunreal.net/UT_GOTY_CD1.ISO", "https://files3.oldunreal.net/UT_GOTY_CD1.ISO",
            "https://archive.org/download/ut-goty/UT_GOTY_CD1.iso"};

    static void install(File cache, File destination, String language, Progress progress) throws Exception {
        if (!Arrays.asList("ctt", "det", "elt", "est", "frt", "int", "itt", "nlt", "ptt", "rut").contains(language))
            throw new IOException("Unsupported language");
        if (destination.exists()) throw new IOException("Choose a new folder; existing files are preserved");
        mkdir(cache);
        progress.update("OldUnreal", 0);
        JSONObject release;
        HttpURLConnection connection = connect(RELEASE);
        try (InputStream in = connection.getInputStream()) {
            release = new JSONObject(new String(read(in, 4 * 1024 * 1024), "UTF-8"));
        } finally { connection.disconnect(); }
        if (release.optBoolean("draft") || release.optBoolean("prerelease")) throw new IOException("No stable patch available");
        JSONObject patch = null;
        JSONArray assets = release.getJSONArray("assets");
        for (int i = 0; i < assets.length(); i++) {
            JSONObject asset = assets.getJSONObject(i);
            if (asset.getString("name").endsWith("-Windows-x86.zip")) { patch = asset; break; }
        }
        if (patch == null) throw new IOException("Official data patch not found");
        File iso = new File(cache, "UT_GOTY_CD1.ISO");
        if (!iso.isFile() && cache.getUsableSpace() > 0 && cache.getUsableSpace() < ISO_SIZE + patch.getLong("size"))
            throw new IOException("Not enough internal space for the game downloads");
        if (!valid(iso, ISO_SIZE, "MD5", ISO_MD5)) {
            IOException last = null;
            for (String mirror : MIRRORS) {
                try { download(mirror, iso, ISO_SIZE, "MD5", ISO_MD5, "GOTY", progress); last = null; break; }
                catch (IOException error) {
                    if (Thread.currentThread().isInterrupted()) throw error;
                    // Android's HTTP implementation can clear the interrupt
                    // flag. The UI callback also checks its durable cancel flag.
                    progress.update("GOTY", 0);
                    last = error;
                }
            }
            if (last != null) throw last;
        }
        String digest = patch.optString("digest", "");
        String hash = digest.startsWith("sha256:") ? digest.substring(7) : null;
        File zip = child(cache, patch.getString("name"));
        download(patch.getString("browser_download_url"), zip, patch.getLong("size"), "SHA-256", hash,
                release.getString("tag_name"), progress);
        File parent = destination.getCanonicalFile().getParentFile();
        mkdir(parent);
        if (parent.getUsableSpace() > 0 && parent.getUsableSpace() < 1500L * 1024 * 1024)
            throw new IOException("At least 1.5 GB free is required at the destination");
        File stage = new File(parent, ".ut99-install-" + UUID.randomUUID());
        mkdir(stage);
        try {
            extractDisc(iso, stage, progress);
            extractPatch(zip, stage, language, progress);
            UT99Paths.normalizeInstalledDataRoot(stage);
            if (!UT99Paths.hasLaunchableGameData(stage)) throw new IOException("Installed game data failed validation");
            if (!"int".equals(language) && !new File(stage, "System/Botpack." + language).isFile())
                throw new IOException("The selected translation is missing from the official patch");
            write(new File(stage, ".ut99-install-source"),
                    ("OldUnreal GOTY\n" + release.getString("tag_name") + "\nLanguage=" + language + "\n").getBytes("UTF-8"));
            if (destination.exists() || !stage.renameTo(destination)) throw new IOException("Cannot finalize installation");
        } finally { if (stage.exists()) removeOwnedStage(stage); }
        // Keep downloads for retries, but release their storage after success.
        iso.delete(); zip.delete();
        progress.update("OK", 100);
    }

    static void extractDisc(File image, File target, Progress progress) throws IOException {
        try (Ut99DiscImage disc = new Ut99DiscImage(image)) {
            int done = 0;
            for (Ut99DiscImage.Entry entry : disc.entries()) {
                String path = selectedPath(entry.path);
                if (path != null) {
                    boolean compressed = path.toLowerCase(Locale.ROOT).endsWith(".uz");
                    if (compressed) path = path.substring(0, path.length() - 3);
                    File output = child(target, path); mkdir(output.getParentFile());
                    if (compressed) write(output, Ut99RedirectDownload.decodeDiscUz(
                            disc.bytes(entry, 64 * 1024 * 1024), 64 * 1024 * 1024));
                    else try (OutputStream out = new FileOutputStream(output)) { disc.copy(entry, out); }
                }
                progress.update("GOTY · " + entry.path, ++done * 100 / disc.entries().size());
            }
        }
    }

    static void extractPatch(File zip, File target, String language, Progress progress) throws IOException {
        try (ZipFile archive = new ZipFile(zip)) {
            Enumeration<? extends ZipEntry> entries = archive.entries();
            int done = 0; long total = 0;
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                String path = entry.getName().replace('\\', '/');
                if (path.startsWith("SystemLocalized/")) {
                    String prefix = "SystemLocalized/" + language + "/";
                    String english = "SystemLocalized/int/";
                    path = path.startsWith(prefix) ? "System/" + path.substring(prefix.length())
                            : path.startsWith(english) ? "System/" + path.substring(english.length()) : "";
                }
                String selected = path.equals("LICENSE.md") ? path : selectedPath(path);
                if (!entry.isDirectory() && selected != null) {
                    File output = child(target, selected); mkdir(output.getParentFile());
                    long bytes = 0;
                    try (InputStream in = archive.getInputStream(entry); OutputStream out = new FileOutputStream(output)) {
                        byte[] buffer = new byte[65536]; int n;
                        while ((n = in.read(buffer)) != -1) {
                            checkInterrupted();
                            bytes += n; total += n;
                            if (bytes > 256L * 1024 * 1024 || total > 2L * 1024 * 1024 * 1024)
                                throw new IOException("Patch expansion exceeds limit");
                            out.write(buffer, 0, n);
                        }
                    }
                }
                progress.update("OldUnreal · " + entry.getName(), ++done * 100 / archive.size());
            }
        }
    }

    private static String selectedPath(String path) {
        String[] parts = path.split("/", -1);
        if (parts.length != 2) return null;
        String folder = parts[0], name = parts[1].toLowerCase(Locale.ROOT);
        for (String canonical : new String[]{"Maps", "Music", "Sounds", "Textures", "System"}) {
            if (!canonical.equalsIgnoreCase(folder)) continue;
            boolean allowed = canonical.equals("System")
                    ? name.matches(".*\\.(u|ini|int|ctt|det|elt|est|frt|itt|nlt|ptt|rut)")
                    : name.matches(".*\\.(unr|utx|uax|umx)(\\.uz)?");
            return allowed ? canonical + "/" + parts[1] : null;
        }
        return null;
    }

    private static File child(File root, String path) throws IOException {
        File child = new File(root, path).getCanonicalFile();
        if (!child.getPath().startsWith(root.getCanonicalPath() + File.separator)) throw new IOException("Unsafe archive path");
        return child;
    }
    private static void mkdir(File dir) throws IOException {
        if (dir == null || (!dir.isDirectory() && !dir.mkdirs())) throw new IOException("Cannot create folder: " + dir);
    }
    private static void checkInterrupted() throws InterruptedIOException {
        if (Thread.currentThread().isInterrupted()) throw new InterruptedIOException("Installation cancelled");
    }
    private static void write(File file, byte[] data) throws IOException {
        try (OutputStream out = new FileOutputStream(file)) { out.write(data); }
    }
    private static byte[] read(InputStream in, int max) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream(); byte[] buffer = new byte[8192]; int n;
        while ((n = in.read(buffer)) != -1) {
            if (out.size() > max - n) throw new IOException("Response too large");
            out.write(buffer, 0, n);
        }
        return out.toByteArray();
    }
    private static HttpURLConnection connect(String url) throws IOException {
        URL parsed = new URL(url);
        if (!"https".equals(parsed.getProtocol())) throw new IOException("HTTPS required");
        HttpURLConnection connection = (HttpURLConnection)parsed.openConnection();
        connection.setConnectTimeout(20000); connection.setReadTimeout(30000);
        connection.setRequestProperty("User-Agent", "UT99-Android-data-installer");
        return connection;
    }
    private static boolean valid(File file, long size, String algorithm, String expected) throws IOException {
        if (!file.isFile() || file.length() != size) return false;
        if (expected == null) return true;
        try {
            MessageDigest digest = MessageDigest.getInstance(algorithm);
            try (InputStream in = new FileInputStream(file)) {
                byte[] buffer = new byte[65536]; int n;
                while ((n = in.read(buffer)) != -1) { checkInterrupted(); digest.update(buffer, 0, n); }
            }
            StringBuilder hex = new StringBuilder();
            for (byte b : digest.digest()) hex.append(String.format(Locale.ROOT, "%02x", b & 255));
            return expected.equalsIgnoreCase(hex.toString());
        } catch (NoSuchAlgorithmException error) { throw new IOException(error); }
    }
    private static void download(String url, File target, long size, String algorithm, String hash,
                                 String label, Progress progress) throws IOException {
        progress.update(label, 0);
        if (size <= 0 || size > 1024L * 1024 * 1024) throw new IOException("Invalid download size");
        if (valid(target, size, algorithm, hash)) return;
        File partial = new File(target.getPath() + ".part");
        HttpURLConnection connection = connect(url);
        try {
            if (connection.getResponseCode() != 200) throw new IOException("HTTP " + connection.getResponseCode());
            try (InputStream in = connection.getInputStream(); OutputStream out = new FileOutputStream(partial)) {
                byte[] buffer = new byte[65536]; long done = 0; int n, last = -1;
                while ((n = in.read(buffer)) != -1) {
                    checkInterrupted();
                    done += n; if (done > size) throw new IOException("Download exceeds expected size");
                    out.write(buffer, 0, n);
                    int percent = (int)(done * 100 / size);
                    if (percent != last) { progress.update(label, percent); last = percent; }
                }
            }
            if (!valid(partial, size, algorithm, hash)) throw new IOException("Download integrity check failed");
            if (target.exists() && !target.delete()) throw new IOException("Cannot replace cached download");
            if (!partial.renameTo(target)) throw new IOException("Cannot finalize download");
        } finally { connection.disconnect(); if (partial.exists()) partial.delete(); }
    }
    private static void removeOwnedStage(File file) throws IOException {
        // This receives only the newly created staging directory, never a user folder.
        File[] children = file.listFiles();
        if (children != null) for (File child : children) removeOwnedStage(child);
        if (!file.delete()) throw new IOException("Cannot remove temporary installation file");
    }
}
