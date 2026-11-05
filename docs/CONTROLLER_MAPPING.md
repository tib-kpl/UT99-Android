# Android controller profiles

Available in Unreal 2.4.15 and UT99 2.3.26, under Android settings > Controller
(Manette). Select + Start still opens the overlay in either order.

- Select a connected physical controller and change A/B/X/Y, L1/R1 or L3/R3.
- Each button can send another supported button, show scores while held, or be
  disabled. The listed game actions are defaults: existing in-game bindings
  remain authoritative for remapped button outputs.
- Profiles use Android's stable device descriptor, rather than its temporary
  connection ID. They persist across restarts/reconnections and are separate
  for different devices and for each APK. Identical devices with an identical
  Android descriptor share a profile.
- Reset this controller restores only the selected profile. Android settings
  reset and touch layout reset retain controller profiles.
- Sticks, D-pad and analogue/digital triggers keep their current routing.
  Select, Start, Back and system keys are reserved. The Android dialog always
  keeps its physical A/B, L1/R1 and Select + Start navigation.
- In UT99, hold Select to show scores; release to return to gameplay. The
  settings chord suppresses the single-button action during its 250 ms grace
  period. A single Select press does nothing in game menus.
- In Unreal, Select retains the translator. An assignable score output is
  provided for multiplayer; it does not create a single-player score screen.

Input releases retain the mapping used at press time. Buttons/devices sharing
an output release it only after the last source releases it. Focus loss, pause,
device removal and native engine resets clear held state. The native score
helper only writes at controller transitions, preserving keyboard scores while
the pad is idle, and handles pawn replacement without dereferencing stale pawns.

## Validation

- `python tools/test_controller_mapping.py`: production Java with JVM input
  fakes; defaults, remapping, disabled/corrupt values, press-time releases,
  merged buttons, device isolation/reconnection, unplug release, reserved keys,
  touch/keyboard exclusion, UI selection and per-controller reset.
- `python tools/test_settings_chord.py`: both chord orders and delayed release.
- `controller_scores.cpp`: production native state helper; hold/release,
  menu/reset, null/replaced pawns and idle keyboard coexistence.
- Local release builds: Unreal normal/automotive, both engines and both ABIs;
  UT99 normal/classic, both ABIs, plus automotive Java compilation. APK content
  and menu-variant parity checks pass.
- Odin: UT99 overlay opened with Select + Start, Controller page displayed and
  Xbox Wireless Controller detected. The console switched to another UT2004
  session before the match input test. Actual scoreboard rendering in a match
  and a physical remapped-button round trip are not yet validated on device.

No console gameplay validation is claimed for Unreal in this change.
