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
| Light | 2.5° | 2.5 | 12°/s |
| Medium | 4° | 4 | 24°/s |
| Strong | 6° | 6 | 42°/s |

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
