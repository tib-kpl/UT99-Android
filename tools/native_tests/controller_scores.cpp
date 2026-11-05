#include "AndroidScoreboard.h"
#include <stdio.h>
#include <stdlib.h>
struct Player { bool bShowScores; Player() : bShowScores(false) {} };
static void check(bool value, const char* name) {
    if(!value) { fprintf(stderr,"FAIL %s\n",name); exit(1); }
}
int main() {
    AndroidScoreboardState state;
    Player first, respawn;
    state.Update(&first,false);
    first.bShowScores=true;
    state.Update(&first,false);
    check(first.bShowScores,"idle pad preserves keyboard scoreboard");
    first.bShowScores=false;
    state.Update(&first,true); check(first.bShowScores,"controller press shows scores");
    state.Update(&first,true); check(first.bShowScores,"holding preserves scores");
    state.Update(&first,false); check(!first.bShowScores,"release closes scores");
    state.Update(&first,true);
    state.Update(&respawn,true); check(respawn.bShowScores,"new pawn receives held input");
    state.Update(&respawn,false); check(!respawn.bShowScores,"pause/menu/reset clears scores");
    state.Update((Player*)0,true); check(!state.active,"no player cannot latch a press");
    state.Update(&respawn,true); check(respawn.bShowScores,"press with new valid player");
    state.Update(&respawn,false);
    puts("Controller scores: hold, release, menu/reset, respawn and keyboard coexistence passed");
}
