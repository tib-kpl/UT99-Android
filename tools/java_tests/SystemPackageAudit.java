package com.ast.ut99;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.*;
import java.util.Arrays;
import java.util.Comparator;
import java.util.stream.Stream;

/** Header/import policy checks; generated fixtures contain no game data. */
public final class SystemPackageAudit {
    private static void check(boolean good, String label) {
        if (!good) throw new AssertionError(label);
    }

    private static void header(Path path, int version) throws Exception {
        Files.write(path, ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN)
                .putInt(0x9E2A83C1).putInt(version).array());
    }

    public static void main(String[] args) throws Exception {
        Path parent = Paths.get(args[0]).toAbsolutePath().normalize();
        Files.createDirectories(parent);
        Path root = Files.createTempDirectory(parent, "package-policy-");
        try {
            for (String name : new String[]{"System", "Maps", "Textures", "Sounds", "Music"})
                Files.createDirectory(root.resolve(name));
            Path system = root.resolve("System"), engine = system.resolve("Engine.u");
            for (int version : new int[]{68, 69}) {
                for (String name : new String[]{"Core.u", "Engine.u", "Botpack.u"}) header(system.resolve(name), version);
                header(root.resolve("Maps/CityIntro.unr"), 68);
                check(UT99Paths.hasLaunchableGameData(root.toFile()), "Supported system version " + version);
                check(UT99Paths.usesModernSystemPackages(system.toFile()) == (version == 69), "Menu generation");
            }
            for (int version : new int[]{67, 70, 69 | (1 << 16)}) {
                header(engine, version);
                check(!UT99Paths.hasUsableGameData(root.toFile()), "Rejected system version " + version);
            }
            header(engine, 69);
            Files.write(engine, new byte[]{1, 2, 3, 4});
            check(!UT99Paths.hasUsableGameData(root.toFile()), "Truncated header");
            Files.write(engine, new byte[8]);
            check(!UT99Paths.hasUsableGameData(root.toFile()), "Wrong package tag");
            header(engine, 69);
            header(root.resolve("Maps/CityIntro.unr"), 70);
            check(!UT99Paths.hasLaunchableGameData(root.toFile()), "Unsupported map format");
            for (boolean modern : new boolean[]{false, true}) {
                java.util.List<String> patches = Arrays.asList(UT99Paths.bundledSystemPatchPackages(modern));
                check(patches.contains("UMenu.u") == !modern && patches.contains("UTMenu.u") == !modern,
                        "Keep newer game menus intact");
                check(patches.containsAll(Arrays.asList("UT99ConsoleMenu.u", "UT99ConsoleMenu.int", "UT99ConsoleMenu.frt")),
                        "Both data generations receive the console menu");
            }
            System.out.println("PASS: retail/modern headers, unsupported formats, truncated/tag checks and menu preservation");
        } finally {
            check(root.toAbsolutePath().normalize().startsWith(parent), "Fixture cleanup stays inside test directory");
            try (Stream<Path> files = Files.walk(root)) {
                for (Path file : (Iterable<Path>)files.sorted(Comparator.reverseOrder())::iterator) Files.delete(file);
            }
        }
    }
}
