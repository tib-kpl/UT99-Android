#include "AndroidAimAssistMath.h"
#include <stdio.h>
#include <math.h>

static int failures = 0;
static void check(bool pass, const char* name) {
    if (!pass) { printf("FAIL %s\n", name); ++failures; }
}
int main() {
    check(AndroidAim::Angle(65530) == -6 && AndroidAim::Angle(-65530) == 6, "rotation wrap takes shortest path");
    check(AndroidAim::Cone(1) < AndroidAim::Cone(2) && AndroidAim::Cone(2) < AndroidAim::Cone(3), "capture cones increase with strength");
    check(!AndroidAim::Opponent(true, 0, 0, false), "same team excluded");
    check(AndroidAim::Opponent(true, 0, 1, false), "opposing team included");
    check(AndroidAim::Opponent(false, 255, 255, false), "deathmatch opponents included without team IDs");
    check(!AndroidAim::Opponent(true, 255, 1, false), "unknown teams fail closed");
    check(!AndroidAim::Opponent(false, 0, 1, true), "spectators excluded");
    printf("%s aim assistance\n", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
