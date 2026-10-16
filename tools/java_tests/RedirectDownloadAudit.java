package com.ast.ut99;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.file.*;
import java.util.Arrays;
import java.util.Random;

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
        byte[] expected = Files.readAllBytes(Paths.get(args[0]));
        byte[] compressed = Files.readAllBytes(Paths.get(args[1]));
        check(Arrays.equals(expected, Ut99RedirectDownload.decodeUz(compressed, expected.length)), "UZ bytes differ");
        for (int length : new int[]{0, 1, 4, 20, compressed.length / 2}) {
            try {
                Ut99RedirectDownload.decodeUz(Arrays.copyOf(compressed, length), expected.length);
                throw new AssertionError("Accepted truncated UZ");
            } catch (IOException correct) { }
        }
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
        server.start();
        Path output = Files.createTempFile("ut99-redirect-audit-", ".tmp");
        try {
            String root = "http://127.0.0.1:" + server.getAddress().getPort();
            for (String route : new String[]{"/raw", "/uz", "/redirect"}) {
                check(Ut99RedirectDownload.start(root + route, output.toString(), expected.length, !route.equals("/raw")), "Start failed");
                check(await() == 1, "HTTP transfer failed: " + route);
                check(Arrays.equals(expected, Files.readAllBytes(output)), "HTTP bytes differ");
                Ut99RedirectDownload.cancel();
                check(!Files.exists(output), "Cancel left temporary file");
            }
            Ut99RedirectDownload.start(root + "/missing", output.toString(), expected.length, true);
            check(await() == -1, "404 was not rejected");
            Ut99RedirectDownload.start(root + "/raw", output.toString(), expected.length + 1, false);
            check(await() == -1, "Wrong length was not rejected");
            Ut99RedirectDownload.start(root + "/raw", output.toString(), expected.length, false);
            Ut99RedirectDownload.cancel();
            Thread.sleep(100);
            check(!Files.exists(output), "Cancelled transfer wrote output");
            System.out.println("PASS: exact UZ/HTTP bytes, redirects, truncation, 1000 malformed streams, 404, size, cancellation");
        } finally {
            Ut99RedirectDownload.cancel();
            Files.deleteIfExists(output);
            server.stop(0);
        }
    }
}
