#pragma once
#include <math.h>
#include "AndroidAimSmoothing.h"

// Engine-independent policy, also exercised by the native regression test.
namespace AndroidAim {
inline int Angle(int value) { return ((value + 32768) & 65535) - 32768; }
inline float Cone(int level) {
    return AndroidAimMotion::ProfileFor(level, true).cone;
}
inline bool Opponent(bool teamGame, int ownTeam, int targetTeam, bool spectator) {
    return !spectator && (!teamGame || (ownTeam < 4 && targetTeam < 4 && ownTeam != targetTeam));
}
}
