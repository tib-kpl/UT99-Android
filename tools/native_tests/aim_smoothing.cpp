#include "AndroidAimSmoothing.h"
#include <stdio.h>
#include <math.h>

static int failures = 0;
static void check(bool passed, const char* name) {
    if (!passed) { printf("FAIL %s\n", name); ++failures; }
}
static float tracking(int fps, float response = 11, float speed = 84, float rate = 45) {
    AndroidAimMotion::Axis axis;
    float view = 0, target = 5.f * 65536.f / 360.f;
    for (int frame = 0; frame < fps*3; ++frame) {
        target += rate * (65536.f / 360.f) / fps;
        view += axis.Step((int)(target-view), response, speed, 1.f/fps, 0);
    }
    return fabs(target-view) * 360.f/65536.f;
}
int main() {
    AndroidAimMotion::Axis axis;
    int first = axis.Step(2000,11,84,1.f/60.f,0);
    check(first > 0 && first < 100, "acquisition ramps instead of jumping to full speed");
    for (int i = 0; i < 60; ++i) axis.Step(2000,11,84,1.f/60.f,0);
    check(axis.Step(2000,11,84,1.f/60.f,.649f) == 0, "stick fades out before override threshold");
    check(axis.Step(2000,11,84,1.f/60.f,.65f) == 0, "firm stick immediately overrides");
    check(axis.velocity == 0 && axis.remainder == 0, "override discards stale motion");
    axis.Step(1000,11,84,1.f/60.f,0);
    check(axis.Step(1000,0,84,1.f/60.f,0) == 0 && axis.velocity == 0, "disabled assistance stops immediately");
    axis.Step(1000,11,84,1.f/60.f,0);
    check(axis.Step(1000,11,84,0,0) == 0 && axis.velocity == 0, "paused frame clears motion");
    axis.Reset();
    int tiny = 0;
    for (int i = 0; i < 1200; ++i) tiny += axis.Step(1,1,1,1.f/120.f,0);
    check(tiny > 5, "sub-unit corrections accumulate instead of sticking");
    const int rates[] = {30,60,120};
    const float responses[] = {2.5f,4.f,6.f,7.f,11.f};
    for (int fps : rates) for (float response : responses) {
        axis.Reset(); int error = 2000;
        for (int frame = 0; frame < fps*4; ++frame) {
            int delta = axis.Step(error,response,84,1.f/fps,0);
            check(delta >= 0 && delta <= error, "stationary convergence without overshoot");
            error -= delta;
        }
        check(error < 2, "stationary target converges at all frame rates");
        check(axis.Step(0,response,84,1.f/fps,0) == 0, "no residual drift on centered target");
    }
    float slow = tracking(30), medium = tracking(60), fast = tracking(120);
    printf("45 deg/s moving target errors: 30Hz=%.3f 60Hz=%.3f 120Hz=%.3f degrees\n",slow,medium,fast);
    check(slow < 6 && medium < 6 && fast < 6, "strong still follows fast moving targets");
    check(fabs(slow-fast) < 1.f, "tracking is consistent across frame rates");
    check(tracking(60,6,42,20) < 5.f, "Unreal strong profile keeps tracking moving targets");
    check(tracking(60,2.5f,12,6) < 4.f, "Unreal light profile keeps tracking moving targets");
    check(tracking(60,4,24,12) < 5.f, "UT99 light profile keeps tracking moving targets");
    axis.Reset();
    float oldVelocity = 0;
    for (int frame = 0; frame < 120; ++frame) {
        axis.Step(frame < 60 ? 4000 : -4000,11,84,1.f/60.f,0);
        check(fabs(axis.velocity-oldVelocity) <= 84.f*(65536.f/360.f)*8.f/60.f + .01f,
              "target reversal respects acceleration bound");
        oldVelocity = axis.velocity;
    }
    check(axis.velocity < 0, "target reversal eventually tracks the new direction");
    axis.Reset();
    AndroidAimMotion::Axis fresh;
    check(axis.Step(1500,11,84,1.f/60.f,0) == fresh.Step(1500,11,84,1.f/60.f,0),
          "target loss reset starts a fresh acquisition");
    printf("%s aim smoothing\n",failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
