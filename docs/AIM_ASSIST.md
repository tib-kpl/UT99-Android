# Controller aim assistance

Android settings → Comfort → Aim assist offers Off, Light, Medium (default), and Strong.
The saved level applies when the overlay closes and on the next launch. Reset Android
settings restores Medium. It is shared by normal/classic/automotive variants.

This is gentle camera tracking, independent of the original UT firing correction
(`MyAutoAim`). It does not change shot damage, projectile trajectories, or weapon spread.
Only real controller motion enables it. Touch/mouse input or activity resume clears
controller ownership until another controller motion event.

Eligible targets are living, visible player pawns (including bots) within 4096 units;
spectators, hidden actors and teammates are excluded. Unknown team rules disable
target selection. A collision trace to the upper torso rejects obscured targets.
There is no assistance in menus, console text input, third-person/spectator views,
or while dead/unarmed. Stick deflection above 65% overrides tracking.

| Level | Capture cone | Response / second | Maximum speed |
| --- | --- | --- | --- |
| Off | — | — | 0°/s |
| Light | 4° | 4 | 24°/s |
| Medium | 7° | 7 | 48°/s |
| Strong | 10° | 11 | 84°/s |

The previous target gets 1.5° capture tolerance and a small selection bias to reduce
switching. Corrections use the shortest rotation, exponentially approach the target,
respect speed limits and cap frame time at 50 ms. JNI publishes settings/input ownership through atomics (also before SDL startup);
only the game thread accesses pawns and the target pointer is never dereferenced
outside the current live pawn list.

`tools/native_tests/aim_assist.cpp` exercises the production math and team policy:
disable/override, rotation wrap, strength ordering, convergence, long-frame limits,
deathmatch/teamplay and spectator exclusion. Compile with the NDK clang++ using
`--target=aarch64-linux-android21 -static-libstdc++` and the include directory
`third_party/ut99dc/Source/NSDLDrv/Src`, then run the binary through ADB.

## SDL routing regression (2.3.20)

Controller ownership and right-stick magnitude must be observed in
`Activity.dispatchGenericMotionEvent`, before delegating to SDL. SDL's focused
SurfaceView consumes joystick events, bypassing Activity.onGenericMotionEvent.
The v47 axis mirrors are updated only in menus on that path, so they cannot be
used to implement the firm-stick override during gameplay. JNI publishes the
dispatched axes atomically along with input ownership.

Validated on Odin2 Portal with input injected through the physical Xbox controller
device node: ownership changes to controller on stick motion. In a standalone
DM-Deck16][ bot match, a temporary game-thread integration fixture aimed 300
rotation units away from a visible live bot, then called the production assistance
for 120 frames at 60 Hz. Remaining yaw error: Off 300, Light 12, Medium 7, Strong 5.
The fixture restored the view/settings and was removed from release builds.

The final routing/axis implementation was rechecked with the same fixture. Off/Light/Medium/Strong again left errors of 300/12/7/5 units. Disabling controller ownership or supplying 80% stick deflection both left the error at 300 units (no correction).

## Strength tuning (2.3.21)

All active levels use wider capture cones and faster tracking; Strong doubles the
speed limit from 42 to 84 degrees/second. A moving-target regression verifies
that Strong keeps up with a target crossing at 45 degrees/second instead of
falling behind. Off, teammate/visibility filtering and the 65% stick override
are unchanged. The integration measurements above describe the older tuning.

## Smoothing update

Camera correction now uses a filtered angular velocity (18/s response) with an
acceleration limit of eight times the selected maximum speed per second. This
ramps acquisition and target-direction changes instead of instantly applying the
full correction. A smoothstep curve fades assistance between 20% and 65% stick
deflection; at 65% it stops immediately. Fractional rotation is accumulated with
symmetric rounding, preventing tiny corrections from being discarded every frame.

Target loss, occlusion, menus, input-mode changes and settings changes clear all
motion history immediately; there is no continued tracking behind an obstacle.
The existing capture cones and intensity speed limits are preserved.

`aim_smoothing.cpp` exercises the production header on the host in CI: acquisition,
acceleration-limited reversal, convergence without overshoot, fractional motion,
override, reset, and a 45°/s moving target at 30/60/120 Hz. Local measured errors
with UT99 Strong parameters (11/s response, 84 degrees/s limit) were 3.390° / 3.731° / 3.907° after three seconds.
Subjective feel validation remains separate from the controlled on-device measurements below.

## Level ordering correction

The menu/persistence/JNI mapping is Off=0, Light=1, Medium=2, Strong=3; labels
were not reversed. The extra fixed 18/s velocity filter introduced phase lag:
ten matched reversal scenarios had a higher RMS error at a higher level.
That second filter is removed. Exponential position response, acceleration
limits, fractional motion and the smooth stick taper remain in effect.

Profiles now come from the shared production `ProfileFor` table, used directly
by both the runtime selector and the comparison tests. Existing strength values
are retained. `aim_levels.cpp` compares 192 scenarios (both games, 30/60/120 Hz,
four stick deflections, stationary/linear/reversing trajectories), with zero
level-order inversions after correction. A 0.01 degree tolerance covers rotation
quantization. These comparisons exclude target selection, which is audited
separately in the on-device engine fixture.

### Odin2 Portal level audit

The real game-thread selection/visibility/camera path was exercised with a live
bot in a local UT99 Deck16 match and a spawned Skaarj in Unreal Gold Chizra.
The temporary fixture used the same initial yaw offset (182 rotation units),
120 updates at 60 Hz, and measured mean absolute error over the last 60 updates.
For the relative-motion case it injected a 9-unit view offset before each update
(about 3 degrees/second); the pawn position stayed fixed, so selection and traces
still ran against a real actor. Controller ownership was forced only inside the
fixture. These are controlled engine measurements, not a subjective hands-on test.

| Game / scenario | Off | Light | Medium | Strong |
| --- | ---: | ---: | ---: | ---: |
| UT99 stationary | 182 | 0.683 | 0 | 0 |
| UT99 relative motion | 996.500 | 130.783 | 72.783 | 44.733 |
| Unreal Gold stationary | 182 | 5.433 | 0.683 | 0 |
| Unreal Gold relative motion | 996.500 | 210.700 | 130.783 | 85.633 |

Lower error is better. UT99 menu selections were also cycled through all four
values and checked against the native profile log. Initial saved levels were
preserved (UT99 Strong, Unreal Medium). The fixture restored view/state and was
removed, along with its direct map startup, before the final release build.
UT99 used separate cloned test INIs to avoid writing tournament progress.
The v200 runtime was compiled but not exercised with a separate data set.
