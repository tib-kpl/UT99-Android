#ifndef ANDROID_SCOREBOARD_H
#define ANDROID_SCOREBOARD_H

// Only change the game's score flag at controller edges. Keyboard scores keep
// working independently while the controller is idle. Never retain a pawn to
// dereference later: respawns and level changes may destroy it.
struct AndroidScoreboardState
{
    const void* owner;
    bool active;
    AndroidScoreboardState() : owner(0), active(false) {}

    template<class Player> void Update(Player* player, bool requested)
    {
        if(owner != player) { owner=player; active=false; }
        if(player && requested != active) player->bShowScores=requested;
        active=player && requested;
    }
};
#endif
