#pragma once
#include <math.h>

// Engine-independent policy, also exercised by the native regression test.
namespace AndroidAim {
inline int Angle(int value) { return ((value + 32768) & 65535) - 32768; }
inline float Cone(int level) {
    const float values[] = {0.f, 4.f, 7.f, 10.f};
    return values[level];
}
inline bool Opponent(bool teamGame, int ownTeam, int targetTeam, bool spectator) {
    return !spectator && (!teamGame || (ownTeam < 4 && targetTeam < 4 && ownTeam != targetTeam));
}
}
