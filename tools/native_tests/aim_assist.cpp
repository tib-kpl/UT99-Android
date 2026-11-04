#include "AndroidAimAssistMath.h"
#include <cstdio>
#include <cmath>

static int failures = 0;
static void check(bool pass, const char* name) {
    if (!pass) { std::printf("FAIL %s\n", name); ++failures; }
}
int main() {
    check(AndroidAim::Angle(65530) == -6 && AndroidAim::Angle(-65530) == 6, "rotation wrap takes shortest path");
    check(AndroidAim::Step(1000, 0, .016f, 0) == 0, "off applies no correction");
    check(AndroidAim::Step(1000, 3, .016f, .66f) == 0, "firm stick overrides assistance");
    check(AndroidAim::Step(1000, 3, 0, 0) == 0, "paused frame does not move view");
    check(AndroidAim::Step(1000, 3, 10, 0) == AndroidAim::Step(1000, 3, .05f, 0), "long frame is capped");
    float previous = 0;
    for (int level = 1; level <= 3; ++level) {
        float step = AndroidAim::Step(1000, level, .016f, 0);
        check(step > previous && step < 1000, "levels increase strength without overshoot");
        check(AndroidAim::Step(-1000, level, .016f, 0) == -step, "symmetric correction");
        check(AndroidAim::Step(1000, level, .016f, .5f) < step, "stick reduces attraction");
        float error = 1000;
        for (int frame = 0; frame < 300; ++frame) {
            float correction = AndroidAim::Step((int)error, level, 1.f/60.f, 0);
            check(correction >= 0 && correction <= error, "tracking converges without oscillation");
            error -= correction;
        }
        check(error < 2, "all active levels converge");
        previous = step;
    }
    check(AndroidAim::Cone(1) < AndroidAim::Cone(2) && AndroidAim::Cone(2) < AndroidAim::Cone(3), "capture cones increase with strength");
    check(!AndroidAim::Opponent(true, 0, 0, false), "same team excluded");
    check(AndroidAim::Opponent(true, 0, 1, false), "opposing team included");
    check(AndroidAim::Opponent(false, 255, 255, false), "deathmatch opponents included without team IDs");
    check(!AndroidAim::Opponent(true, 255, 1, false), "unknown teams fail closed");
    check(!AndroidAim::Opponent(false, 0, 1, true), "spectators excluded");
    std::printf("%s aim assistance\n", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
