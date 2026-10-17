# Android data and download audits

The CI compiles the Java helpers with JDK 17 and the Android 35 API jar. It runs
`SystemPackageAudit`, `RedirectDownloadAudit --self-test` and
`DiscImageAudit --self-test` without downloading or distributing any game data.

These cover package versions and menu preservation, HTTP/UZ bytes and progress,
malformed compressed streams, cancellation, and ISO path/extent validation.

For an optional real-disc check, compile `Ut99DiscImage.java`,
`Ut99RedirectDownload.java` and `DiscImageAudit.java`, then run:

```
java -Xmx256m -cp <compiled-classes> com.ast.ut99.DiscImageAudit <GOTY-CD1.iso>
```

It checks the original disc's 81 compressed maps, two uncompressed maps and
required package names. An optional second argument writes expanded maps to
that directory. Keep these local files in an ignored build directory.

Device checks additionally cover a fresh French install to microSD, an English
install to internal app storage, retained language at engine startup, and
cancellation without replacing an existing installation. Android app storage
is removed when its owning app is uninstalled.
