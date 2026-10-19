<img width="2172" height="724" alt="Unreal Tournament" src="https://github.com/Andiweli/UT99-Android/blob/master/images/unreal-header.jpg" />

# Unreal Tournament (UT99) Android

Unofficial Android port of Unreal Tournament (1999), based on the **v400**
engine and forked from [Andiweli/UT99-Android](https://github.com/Andiweli/UT99-Android).
It runs v400 game data, and this fork also adds support for OldUnreal 469 game
files, an in-app installer for the official GOTY data, the French localization
and a controller-first console menu.

<p align="left">
  <a href="https://github.com/tib-kpl/UT99-Android/releases/latest"><b>DOWNLOAD</b></a>
  &nbsp;|&nbsp;
  <a href="CHANGELOG.md">CHANGELOG</a>
  &nbsp;|&nbsp;
  <a href="ROADMAP.md">ROADMAP</a>
  &nbsp;|&nbsp;
  <a href="docs/GOTY_COMPATIBILITY.md">GOTY / OldUnreal compatibility</a>
</p>

![OS](https://img.shields.io/badge/Android-4.1%20to%2016-green)
![Architecture](https://img.shields.io/badge/ABI-armeabi--v7a%20%2F%20arm64--v8a-orange.svg)
![Controller](https://img.shields.io/badge/Controls-Gamepad%2FTouch%2FKeyb-blueviolet)
![Multiplayer](https://img.shields.io/badge/Multiplayer-LAN%20%2B%20Internet%20(436)-blueviolet)
![AI](https://img.shields.io/badge/AI-assisted%20coding-6e7781)

> [!NOTE]
> **French translation.** The game plays in French when the app's language is French
> (device language, or the per-app language setting on Android 13+), using the official
> French localization (`.frt`) of the game data.
>
> Le jeu passe en français quand l'app est en français (langue du téléphone, ou langue
> par application sous Android 13+), avec la traduction officielle (`.frt`).

> [!IMPORTANT]
> No game data is included. You need a legally obtained copy of Unreal Tournament.
> This project is not official and is not endorsed by Epic Games. Unreal Tournament,
> Unreal Engine and related trademarks are owned by Epic Games.

---

## ▣ Screenshots

<img width="1920" height="1080" alt="ut99-0" src="https://github.com/user-attachments/assets/e7b74300-e685-47fb-82f8-4a81405855e2" />
<img width="1920" height="1080" alt="ut99-1" src="https://github.com/user-attachments/assets/81ffadd5-bf30-4444-ab3b-698c4e56430f" />
<img width="1920" height="1080" alt="ut99-2" src="https://github.com/user-attachments/assets/516263cf-caba-44e3-95f4-4b0852e79780" />

---

## ◈ Two variants, one engine

Each release ships two signed APKs built from the same `master` branch:

| APK | Menu |
|---|---|
| `…-console-menu-release.apk` | Console/phone menu: large entries, D-pad navigation, map previews, text entry kept above the Android keyboard. Recommended with a gamepad. |
| `…-classic-menu-release.apk` | Original UT99 menu (UWindow). |

Both share the same native engine, fixes and game data. Installing one variant
replaces the other and keeps your data and settings.

---

## ◈ Features

**Game data**
- **Official GOTY install from the app**: downloads the GOTY disc (OldUnreal
  mirrors or archive.org, MD5 checked) and the latest OldUnreal patch. Only data
  files are kept: no `.exe` or `.dll`.
- Language chosen at install time: English, French, German, Spanish, Italian,
  Dutch, Portuguese, Russian, Chinese, Greek. The disc's localized voices
  (French, Spanish, Italian) are kept for the chosen language.
- Import your own files (folder or ZIP), v400 or 469.
- Install to internal storage, a microSD card or **any folder**. A folder that
  already holds a valid game can be used in place, without copying.

**In-game Android settings** (gear icon, top right)
- Touch controller: "Automatic (without a physical controller)", "Always show"
  or "Hide"; opacity from 20 to 100 %; edit and reset the layout.
- Game language (restarts automatically).
- Game data location.

**Controls**
- Android gamepads (Xbox, AYN handhelds, Retroid, OUYA…).
- *RetroTouch* touch controller for playing without a gamepad.
- Keyboard and mouse (tested on Chromebook).

**Multiplayer**
- LAN games and Internet games through the server browser.
- The client advertises network version 436: it joins 432 and 436 servers
  (and 469 servers that accept 436 clients).
- Join by IP address; missing packages are downloaded from the server.

**OldUnreal 469 compatibility**
- The Android engine is a v400 base that also loads 469f system packages. The
  fixes (map loading, interface sounds, newer script parameters, networking…)
  are documented in [docs/GOTY_COMPATIBILITY.md](docs/GOTY_COMPATIBILITY.md).

> [!NOTE]
> Known limitations: some mods and server protections (anti-cheat, recent mods)
> do not work; servers that require a 469 client are not reachable; some map
> triggers and events may still not start correctly. Rendering uses OpenGL ES
> (no Vulkan).

---

## ◎ Installation

1. Download and install either APK from
   [the latest release](https://github.com/tib-kpl/UT99-Android/releases/latest).
2. Start **Unreal Tournament**.
3. If no game data is found, the installer screen offers:
   - **Download and install GOTY (OldUnreal)**: choose the language and the
     location, then the app downloads the GOTY disc (about 650 MB) and the
     OldUnreal patch;
   - **Select UT99 folder** or **Select UT99 ZIP** for your own files. If the
     selected folder already holds a valid game, **Use this folder** keeps it
     in place.
4. The game starts automatically once the data is in place.

Required folders for a manual import:

```text
UnrealTournament/
├── System/
├── Maps/
├── Textures/
├── Sounds/
└── Music/
```

The folders can sit at the selected root or inside one top-level Unreal
Tournament folder.

---

## ◇ Default controller layout

| Control | Action |
|---|---|
| Left Stick | Move forward / backward / strafe |
| Right Stick | Look / turn |
| Left Trigger | Alternate Fire |
| Right Trigger | Fire |
| Left Shoulder | Previous Weapon |
| Right Shoulder | Next Weapon |
| A / right face button | Jump |
| B / bottom face button / OUYA O | Crouch |
| Y / left face button / OUYA U | Walk |
| X / top face button / OUYA Y | Wave |
| D-Pad | Menu navigation / in-game navigation depending on context |
| Start | Pause / menu |
| Back | Back / cancel depending on context |

> [!NOTE]
> Button names differ between controllers. Controls can be reassigned in the
> in-game controls menu.

---

## ◈ Building from source

Requirements: JDK 17, Android SDK 35, NDK 23.2.8568313, CMake 3.22.1.
The project uses Android Gradle Plugin 8.6.1 and Gradle 8.7.

```text
./gradlew assembleNormalRelease assembleClassicRelease
python tools/check_menu_variants.py
```

`normal` builds the console menu and `classic` the original UT99 menu.
`tools/check_menu_variants.py` checks that both APKs share the same native
libraries, resources, assets and manifest. The console menu package
(`UT99ConsoleMenu.u`) is rebuilt with `tools/build_console_menu.ps1` and a v400
UCC. See also [BUILD-FLAVORS.md](BUILD-FLAVORS.md).

| | |
|---|---|
| Application ID | `com.ast.ut99` |
| Minimum SDK | 16 (Android 4.1) |
| Target SDK | 35 |
| ABI | armeabi-v7a, arm64-v8a |
| Renderer | OpenGL ES |

Every commit on `master` is built by GitHub Actions, which signs both APKs and
publishes a release.

---

## ▣ Credits

- Original Android port: [Andiweli/UT99-Android](https://github.com/Andiweli/UT99-Android)
  ([support Andiweli via PayPal](https://paypal.me/andiweli)).
- [OldUnreal](https://www.oldunreal.com/) for the 469 patch and for hosting the
  GOTY data.
- The Unreal Engine 1 preservation and porting community.

---

## ◎ Legal

Unreal Tournament, Unreal Engine and related names, assets and trademarks are
property of Epic Games. This repository does **not** include commercial game
data; you must own a legal copy of Unreal Tournament. This project is not
official and is not endorsed by Epic Games. Non-commercial use only.
