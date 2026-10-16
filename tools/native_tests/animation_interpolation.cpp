// Compile against the production compiler abstraction, then run on Android.
#define CORE_API
#include "UnGnuG.h"
#include <cmath>
#include <cstdio>

int main()
{
    int failures=0;
    const float cases[]={-10.9f,-2.0f,-1.4f,-1.0f,-0.6f,-0.1f,0.f,0.1f,0.9f,1.f,1.4f,1.5f,1.9f,2.f,255.9f};
    for(float value:cases)
        if(appFloor(value)!=static_cast<int>(std::floor(value)))
        {
            std::printf("FAIL floor(%g)=%d expected=%d\n",value,appFloor(value),static_cast<int>(std::floor(value)));
            failures++;
        }

    // A periodic mesh track: linear interpolation must stay inside the two
    // surrounding poses and remain continuous across frame and loop boundaries.
    const float poses[]={0.f,1.f,0.f,-1.f};
    float previous=0.f, largestJump=0.f;
    int extrapolated=0;
    for(int sample=0;sample<=8000;sample++)
    {
        const float frame=sample/1000.f;
        const int index=appFloor(frame);
        const float alpha=frame-index;
        if(alpha<0.f || alpha>=1.f) extrapolated++;
        const float value=poses[index%4]+(poses[(index+1)%4]-poses[index%4])*alpha;
        largestJump=std::fmax(largestJump,std::fabs(value-previous));
        previous=value;
    }
    std::printf("mesh interpolation: extrapolated=%d largest_jump=%g\n",extrapolated,largestJump);
    if(extrapolated || largestJump>0.002f) failures++;
    std::printf("%s animation interpolation\n",failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
