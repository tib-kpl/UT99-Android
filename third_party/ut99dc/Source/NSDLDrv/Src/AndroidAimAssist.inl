// Controller camera assistance. All state and actor access stays on SDL's game thread.
#ifdef PLATFORM_ANDROID
#include "AndroidAimAssistMath.h"

// SDL may not have initialized its event queue when Activity.onResume runs.
// Atomics preserve the initial preference and avoid UI/game-thread data races.
static std::atomic<int> AndroidAimRequestedLevel(2);
static std::atomic<int> AndroidAimRequestedController(0);
static INT AndroidAimLevel = -1;
static APawn* AndroidAimPrevious = NULL; // only compared with entries from the live PawnList

extern "C" JNIEXPORT void JNICALL Java_com_ast_ut99_GameActivity_nativeAimAssistSettings(JNIEnv*, jclass, jint Level)
{
    AndroidAimRequestedLevel.store(Clamp<INT>(Level, 0, 3));
}
extern "C" JNIEXPORT void JNICALL Java_com_ast_ut99_GameActivity_nativeAimAssistInput(JNIEnv*, jclass, jboolean Controller)
{
    AndroidAimRequestedController.store(Controller ? 1 : 0);
}

static void AndroidApplyAimAssist(UNSDLViewport* Viewport, FLOAT DeltaTime)
{
    INT Requested = AndroidAimRequestedLevel.load();
    if (AndroidAimLevel != Requested) {
        AndroidAimLevel = Requested;
        AndroidAimPrevious = NULL;
        UT99_ANDROID_SDL_LOGI("Android aim assist level=%d", AndroidAimLevel);
    }
    UBOOL AndroidAimController = AndroidAimRequestedController.load() != 0;
    APlayerPawn* Player = Viewport->Actor;
    FLOAT Stick = Max(Abs(GUT99V47RX), Abs(GUT99V47RY));
    if (!AndroidAimLevel || !AndroidAimController || Stick > .65f || !Player
        || Player->Health <= 0 || !Player->Weapon || Player->bBehindView || Player->ViewTarget
        || Player->bShowMenu || Viewport->bShowWindowsMouse || !Player->PlayerReplicationInfo
        || Player->PlayerReplicationInfo->bIsSpectator)
    { AndroidAimPrevious = NULL; return; }
    UObject* Console = (UObject*)Viewport->Console;
    if (Console && Console->GetStateFrame() && Console->GetStateFrame()->StateNode)
    {
        FName State = Console->GetStateFrame()->StateNode->GetFName();
        if (State == FName(TEXT("Typing")) || State == FName(TEXT("MenuTyping"))
            || State == FName(TEXT("KeyMenuing")) || State == FName(TEXT("Menuing")))
        { AndroidAimPrevious = NULL; return; }
    }
    // Fail closed when team rules are unknown (e.g. during network map setup).
    if (!Player->GameReplicationInfo) { AndroidAimPrevious = NULL; return; }
    const UBOOL TeamGame = Player->GameReplicationInfo->bTeamGame;
    FVector Eye = Player->Location + FVector(0, 0, Player->EyeHeight);
    FVector Forward = Player->ViewRotation.Vector();
    APawn* Best = NULL;
    FVector BestDirection(0, 0, 0);
    FLOAT BestScore = -1.f;
    for (APawn* Target = Player->Level->PawnList; Target; Target = Target->nextPawn)
    {
        if (Target == Player || Target->bDeleteMe || Target->bHidden || Target->Health <= 0
            || !Target->bProjTarget || !Target->bIsPlayer || !Target->PlayerReplicationInfo) continue;
        APlayerReplicationInfo* PRI = Target->PlayerReplicationInfo;
        if (!AndroidAim::Opponent(TeamGame, Player->PlayerReplicationInfo->Team, PRI->Team, PRI->bIsSpectator)) continue;
        FVector Point = Target->Location + FVector(0, 0, Target->CollisionHeight * .35f);
        FVector Direction = Point - Eye;
        FLOAT Distance = Direction.Size();
        if (Distance < 1.f || Distance > 4096.f) continue;
        Direction /= Distance;
        FLOAT Dot = Forward | Direction;
        UBOOL Previous = Target == AndroidAimPrevious;
        FLOAT Threshold = appCos((AndroidAim::Cone(AndroidAimLevel) + (Previous ? 1.5f : 0.f)) * PI / 180.f);
        FLOAT Score = Dot + (Previous ? .003f : 0.f);
        if (Dot < Threshold || Score <= BestScore) continue;
        FCheckResult Hit(1.f);
        Player->GetLevel()->SingleLineCheck(Hit, Player, Point, Eye, TRACE_AllColliding);
        if (Hit.Time < 1.f && Hit.Actor != Target) continue;
        Best = Target; BestScore = Score; BestDirection = Point - Eye;
    }
    AndroidAimPrevious = Best;
    if (!Best) return;
    FRotator Aim = BestDirection.Rotation();
    Player->ViewRotation.Yaw = (Player->ViewRotation.Yaw + appRound(AndroidAim::Step(Aim.Yaw - Player->ViewRotation.Yaw, AndroidAimLevel, DeltaTime, Stick))) & 65535;
    Player->ViewRotation.Pitch = (Player->ViewRotation.Pitch + appRound(AndroidAim::Step(Aim.Pitch - Player->ViewRotation.Pitch, AndroidAimLevel, DeltaTime, Stick))) & 65535;
}
#endif
