#pragma once
#include <math.h>

namespace AndroidAimMotion {
struct Profile { float cone, response, speed; };
inline const Profile& ProfileFor(int level, bool tournament) {
    static const Profile profiles[2][4] = {
        {{0,0,0}, {2.5f,2.5f,12.f}, {4.f,4.f,24.f}, {6.f,6.f,42.f}},
        {{0,0,0}, {4.f,4.f,24.f}, {7.f,7.f,48.f}, {10.f,11.f,84.f}}
    };
    if (level < 0 || level > 3) level = 0;
    return profiles[tournament ? 1 : 0][level];
}
inline float Weight(float stick) {
    if (stick <= .2f) return 1.f;
    if (stick >= .65f) return 0.f;
    float x = (stick - .2f) / .45f;
    return 1.f - x*x*(3.f - 2.f*x);
}
struct Axis {
    float velocity, remainder;
    Axis() : velocity(0), remainder(0) {}
    void Reset() { velocity = remainder = 0.f; }
    int Step(int error, float response, float speed, float dt, float stick) {
        float weight = Weight(stick);
        if (!(dt > 0.f) || !(response > 0.f) || weight <= 0.f) { Reset(); return 0; }
        if (dt > .05f) dt = .05f;
        if (!error) { Reset(); return 0; }
        const float units = 65536.f / 360.f;
        float limit = speed * units;
        float desired = error * (1.f - expf(-response * dt)) / dt;
        if (desired > limit) desired = limit;
        if (desired < -limit) desired = -limit;
        // Exponential position response plus bounded acceleration. A second
        // velocity low-pass added phase lag and could make higher levels worse
        // on reversals; the acceleration bound already smooths those changes.
        float change = desired - velocity;
        float acceleration = limit * 8.f * dt;
        if (change > acceleration) change = acceleration;
        if (change < -acceleration) change = -acceleration;
        velocity += change;
        float step = velocity * dt * weight;
        if ((error > 0 && step > error) || (error < 0 && step < error)) {
            Reset(); return error;
        }
        // Preserve sub-unit motion instead of discarding it every frame.
        float exact = step + remainder;
        int result = exact >= 0.f ? (int)floorf(exact + .5f) : (int)ceilf(exact - .5f);
        remainder = exact - result;
        return result;
    }
};
}
