package com.ast.ut99;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.file.*;
import java.util.Arrays;
import java.util.Random;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/** Run with a local package and its UCC-compressed .uz; no game data is shipped. */
public final class RedirectDownloadAudit {
    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }

    private static int await() throws Exception {
        long deadline = System.nanoTime() + 10_000_000_000L;
        while (Ut99RedirectDownload.status() == 0 && System.nanoTime() < deadline) Thread.sleep(10);
        return Ut99RedirectDownload.status();
    }

    public static void main(String[] args) throws Exception {
        byte[] modernUz = java.util.Base64.getDecoder().decode("LhYAAAlzYW1wbGUudQAcAAAA/wAABgR4IEADA34QIIMCPRiwwYF/CBBDgjwUqKFBPwyYYcEeDtzw4H8ECCNCPBKkkSE/CpRRoR4N2ujQPwaMMWEeC9bYsB8HzrhwjwdvfPh/AgQTIjwRookRPwmSSZGeDNnkyD8FiilRngrV1KifBs20aE+Hbnr0PwOGGTGeCdPMmJ8Fy6xYz4ZtduyfA8ecOM+Fa27cz4NnXrznwzc//n8BAgsSvBChhQm/CJFFiV6M2OLEvwSJJUleitTSpF+GzLJkL0duefK/AoUVKV6J0sqUX4XKqlSvRm116l+Dxpo0r0VrbdqvQ2ddutejtz79vwGDDRneiNHGjN+EyaZMb8Zsc+bfgsWWLG/FamvWb8NmW7a3Y7c9+9+Bw44c78RpZ87vwmVXrnfjtjv378FjT5734rU37/fhsy/f+/Hbn3/AAACAoAAAAAAAAAOhIQAAAAAAnwAAAAAAgJ8A");
        boolean selfTest = args.length == 1 && "--self-test".equals(args[0]);
        byte[] expected = selfTest ? "AB".repeat(64).getBytes("US-ASCII") : Files.readAllBytes(Paths.get(args[0]));
        byte[] compressed = selfTest ? modernUz : Files.readAllBytes(Paths.get(args[1]));
        check(Arrays.equals(expected, Ut99RedirectDownload.decodeUz(compressed, expected.length)), "UZ bytes differ");
        check(Arrays.equals(expected, Ut99RedirectDownload.decodeDiscUz(compressed, expected.length)), "Disc UZ bytes differ");
        try {
            Ut99RedirectDownload.decodeDiscUz(compressed, expected.length - 1);
            throw new AssertionError("Disc expansion limit was ignored");
        } catch (IOException expectedFailure) { }
        // Large real packages can be checked with -Xmx256m without also
        // retaining the HTTP fixture server's buffers and concurrent jobs.
        if (args.length > 2 && "--decode-only".equals(args[2])) {
            System.out.println("PASS: exact UZ bytes within configured Java heap");
            return;
        }
        for (int length : new int[]{0, 1, 4, 20, compressed.length / 2}) {
            try {
                Ut99RedirectDownload.decodeUz(Arrays.copyOf(compressed, length), expected.length);
                throw new AssertionError("Accepted truncated UZ");
            } catch (IOException correct) { }
        }
        // Synthetic AB repetition uses the extra RLE stage of UZ signature 5678.
        check(Arrays.equals("AB".repeat(64).getBytes("US-ASCII"),
                Ut99RedirectDownload.decodeUz(modernUz, 128)), "UZ 5678 differs");
        Random random = new Random(469);
        for (int i = 0; i < 1000; i++) {
            byte[] invalid = new byte[128];
            random.nextBytes(invalid);
            invalid[0] = (byte)0xd2; invalid[1] = 4; invalid[2] = invalid[3] = invalid[4] = 0;
            invalid[5] = 64; invalid[6] = invalid[7] = invalid[8] = 0;
            try { Ut99RedirectDownload.decodeUz(invalid, 4096); }
            catch (IOException correct) { }
        }
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/raw", exchange -> {
            exchange.sendResponseHeaders(200, expected.length);
            exchange.getResponseBody().write(expected); exchange.close();
        });
        server.createContext("/uz", exchange -> {
            exchange.sendResponseHeaders(200, compressed.length);
            exchange.getResponseBody().write(compressed); exchange.close();
        });
        server.createContext("/redirect", exchange -> {
            exchange.getResponseHeaders().set("Location", "/uz");
            exchange.sendResponseHeaders(302, -1); exchange.close();
        });
        server.createContext("/missing", exchange -> { exchange.sendResponseHeaders(404, -1); exchange.close(); });
        CountDownLatch[] gates = {new CountDownLatch(1), new CountDownLatch(1), new CountDownLatch(1)};
        String[] slowRoutes = {"/slow-raw", "/slow-uz", "/slow-chunked-uz"};
        for (int index = 0; index < slowRoutes.length; index++) {
            final int test = index;
            server.createContext(slowRoutes[index], exchange -> {
                byte[] payload = test == 0 ? expected : compressed;
                exchange.sendResponseHeaders(200, test == 2 ? 0 : payload.length);
                try {
                    int half = payload.length / 2;
                    exchange.getResponseBody().write(payload, 0, half);
                    exchange.getResponseBody().flush();
                    gates[test].await(5, TimeUnit.SECONDS);
                    exchange.getResponseBody().write(payload, half, payload.length - half);
                } catch (InterruptedException interrupted) { Thread.currentThread().interrupt(); }
                finally { exchange.close(); }
            });
        }
        server.start();
        Path output = Files.createTempFile("ut99-redirect-audit-", ".tmp");
        try {
            String root = "http://127.0.0.1:" + server.getAddress().getPort();
            for (String route : new String[]{"/raw", "/uz", "/redirect"}) {
                check(Ut99RedirectDownload.start(root + route, output.toString(), expected.length, !route.equals("/raw")), "Start failed");
                check(await() == 1, "HTTP transfer failed: " + route);
                check(Arrays.equals(expected, Files.readAllBytes(output)), "HTTP bytes differ");
                check(Ut99RedirectDownload.total() == (route.equals("/raw") ? expected.length : compressed.length), "Wrong payload total: " + route);
                Ut99RedirectDownload.cancel();
                check(!Files.exists(output), "Cancel left temporary file");
            }
            for (int index = 0; index < slowRoutes.length; index++) {
                check(Ut99RedirectDownload.start(root + slowRoutes[index], output.toString(), expected.length, index != 0), "Slow start failed");
                try {
                    long deadline = System.nanoTime() + 3_000_000_000L;
                    while (Ut99RedirectDownload.progress() == 0 && System.nanoTime() < deadline) Thread.sleep(10);
                    int received = Ut99RedirectDownload.progress();
                    int total = Ut99RedirectDownload.total();
                    check(received > 0 && Ut99RedirectDownload.status() == 0, "Missing in-flight progress");
                    if (index == 2) check(total == -1, "Chunked compressed total must be unknown while transferring");
                    else {
                        check(total == (index == 0 ? expected.length : compressed.length), "Wrong in-flight total");
                        long percent = 100L * received / total;
                        check(percent > 0 && percent < 100, "Invalid in-flight percentage: " + percent);
                    }
                } finally { gates[index].countDown(); }
                check(await() == 1, "Slow transfer failed");
                check(Arrays.equals(expected, Files.readAllBytes(output)), "Slow transfer bytes differ");
                check(Ut99RedirectDownload.total() == Ut99RedirectDownload.progress(), "Final payload total differs");
                Ut99RedirectDownload.cancel();
            }
            Ut99RedirectDownload.start(root + "/missing", output.toString(), expected.length, true);
            check(await() == -1, "404 was not rejected");
            Ut99RedirectDownload.start(root + "/raw", output.toString(), expected.length + 1, false);
            check(await() == -1, "Wrong length was not rejected");
            Ut99RedirectDownload.start(root + "/raw", output.toString(), expected.length, false);
            Ut99RedirectDownload.cancel();
            Thread.sleep(100);
            check(!Files.exists(output), "Cancelled transfer wrote output");
            System.out.println("PASS: exact UZ/HTTP bytes, redirects, truncation, 1000 malformed streams, 404, size, cancellation, live HTTP/UZ percentage and unknown-length progress");
        } finally {
            for (CountDownLatch gate : gates) gate.countDown();
            Ut99RedirectDownload.cancel();
            Files.deleteIfExists(output);
            server.stop(0);
        }
    }
}
