#pragma once
#include <math.h>

namespace AndroidAimMotion {
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
        // Filter angular velocity, and bound acceleration on acquisition and
        // target changes. Time-based coefficients keep 30/60/120 Hz consistent.
        float change = (desired - velocity) * (1.f - expf(-18.f * dt));
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
