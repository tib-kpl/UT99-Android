#pragma once
#include <math.h>

// Engine-independent policy, also exercised by the native regression test.
namespace AndroidAim {
inline int Angle(int value) { return ((value + 32768) & 65535) - 32768; }
inline float Cone(int level) {
    const float values[] = {0.f, 2.5f, 4.f, 6.f};
    return values[level];
}
inline float Step(int delta, int level, float dt, float stick) {
    if (level <= 0 || level > 3 || stick > .65f || !(dt > 0.f)) return 0.f;
    if (dt > .05f) dt = .05f;
    const float response[] = {0.f, 2.5f, 4.f, 6.f};
    const float speed[] = {0.f, 12.f, 24.f, 42.f};
    float step = Angle(delta) * (1.f - expf(-response[level] * dt)) * (1.f - stick);
    float limit = speed[level] * (65536.f / 360.f) * dt;
    return step < -limit ? -limit : step > limit ? limit : step;
}
inline bool Opponent(bool teamGame, int ownTeam, int targetTeam, bool spectator) {
    return !spectator && (!teamGame || (ownTeam < 4 && targetTeam < 4 && ownTeam != targetTeam));
}
}
