# Changelog

Each release ships two signed APKs: **console-menu** (console/phone menu) and
**classic-menu** (original UT99 menu). Engine fixes apply to both. Releases are
published on [the releases page](https://github.com/tib-kpl/UT99-Android/releases).

## 2.3.12

- Console menu: if a campaign screen disappears after a match and only the
  blurred backdrop is left while the menu is locked, the menu brings the
  campaign screen back after 3 seconds, or falls back to the main menu, and
  logs the windows it found.
- The engine log (`System/UT99Android.log`) is written line by line, so the
  last lines are kept when Android stops a frozen game.

## 2.3.11

- Console menu: edit boxes and combos redrawn as dark panels with a gold
  outline and white text; small buttons are flat and match the menu rows,
  instead of the bevelled Windows-style controls.
- Removed the green outline Android drew around the game after gamepad or
  keyboard navigation.

## 2.3.10

- Console menu: while typing, the field, the typed text and the hint stay in
  the top quarter of the screen, above the Android keyboard.
- The field label is white instead of black.

## 2.3.9

- No more empty page after the first LAN or Internet server search: the 469
  browser's server info window is hidden.

## 2.3.8

- Faster menu opening from a microSD card: the map list is no longer reread
  for every map (about 0.6 s instead of 1.5–2.7 s on an Odin 2).

## 2.3.7

- Back to the normal Android lock screen (the automatic dismissal of a
  swipe-only lock screen added in 2.3.5 is removed).

## 2.3.6

- Faster menu opening with OldUnreal 469 data: menu input no longer walks every
  loaded object, and `.int` files are read at engine start.

## 2.3.5

- Multiplayer: the client advertises network version 436 and joins servers that
  require 436 ("Incompatible server: UT 436 required"). Servers that require
  469 remain unreachable.

## 2.3.4

- Fixed an in-match crash (players touching, taking damage) with 469 data.
- The settings gear no longer steals gamepad focus at launch or after waking.
- Brightness defaults to 6 on a fresh install.

## 2.3.3

- Localized GOTY voices kept for the chosen language (intro narration,
  announcer, players): French, Spanish, Italian.

## 2.3.2

- Engine fixes for OldUnreal 469f data: CTF-Coret, DM-Liandri, AS-Rook and
  DM-Turbine load, intro voice, UTF-8 menu text, interface sounds.
- In-game Android settings gear: touch controller (mode, opacity, layout),
  game language, data location.
- Install or import into any folder; a folder that already holds a valid game
  can be used in place.
- Console menu: whole-step sliders, stable map preview.

## 2.3.1

- Install the official GOTY data (GOTY disc and latest OldUnreal patch) with
  language and internal/microSD storage choice.

## 2.3.0

- Native Android engine support for recent UT99 system packages (OldUnreal 469).

## 2.2.3

- HTTP package download percentage restored in both menus.

## 2.2.2

- Compatibility with recent Core properties and script APIs.
