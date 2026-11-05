#include "AndroidAimSmoothing.h"
#include <math.h>
#include <stdio.h>

static double errorFor(const AndroidAimMotion::Profile& profile, int fps, float stick, int pattern) {
    AndroidAimMotion::Axis axis;
    double view = 0, squared = 0;
    for (int frame = 0; frame < fps*8; ++frame) {
        double t = (frame+1.)/fps, target;
        if (pattern == 0) target = 2;
        else if (pattern < 5) target = t*(pattern == 1 ? 3 : pattern == 2 ? 10 : pattern == 3 ? 20 : 45);
        else target = 3*sin(t*(pattern == 5 ? 2 : pattern == 6 ? 5 : 10));
        view += axis.Step((int)((target-view)*65536/360), profile.response, profile.speed, 1.f/fps, stick)*360./65536;
        if (frame > fps) squared += (target-view)*(target-view);
    }
    return sqrt(squared/(fps*7-1));
}
int main() {
    const int rates[] = {30,60,120};
    const float sticks[] = {0,.25f,.45f,.6f};
    int failures = 0, scenarios = 0;
    for (int game = 0; game < 2; ++game) {
        const AndroidAimMotion::Profile& off = AndroidAimMotion::ProfileFor(0,game != 0);
        if (off.response != 0 || off.speed != 0) ++failures;
        for (int fps : rates) for (float stick : sticks) for (int pattern = 0; pattern < 8; ++pattern) {
            double errors[3];
            for (int level = 1; level <= 3; ++level)
                errors[level-1] = errorFor(AndroidAimMotion::ProfileFor(level,game != 0),fps,stick,pattern);
            ++scenarios;
            if (errors[2] > errors[1]+.01 || errors[1] > errors[0]+.01) {
                ++failures;
                printf("FAIL levels game=%d fps=%d stick=%.2f trajectory=%d RMS=%.4f/%.4f/%.4f\n",
                       game,fps,stick,pattern,errors[0],errors[1],errors[2]);
            }
        }
    }
    printf("%s aim levels: %d matched scenarios, %d inversions\n",failures ? "FAIL" : "PASS",scenarios,failures);
    return failures ? 1 : 0;
}
