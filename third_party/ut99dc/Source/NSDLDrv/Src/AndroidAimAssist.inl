// Controller camera assistance. All state and actor access stays on SDL's game thread.
#ifdef PLATFORM_ANDROID
#include "AndroidAimAssistMath.h"

// SDL may not have initialized its event queue when Activity.onResume runs.
// Atomics preserve the initial preference and avoid UI/game-thread data races.
#include "AndroidAimSmoothing.h"
static std::atomic<int> AndroidAimRequestedLevel(2);
static std::atomic<int> AndroidAimRequestedController(0);
static std::atomic<float> AndroidAimRequestedStickX(0.f), AndroidAimRequestedStickY(0.f);
static INT AndroidAimLevel = -1;
static APawn* AndroidAimPrevious = NULL; // only compared with entries from the live PawnList

static AndroidAimMotion::Axis AndroidAimYawMotion, AndroidAimPitchMotion;
static void AndroidResetAim() {
    AndroidAimPrevious = NULL;
    AndroidAimYawMotion.Reset(); AndroidAimPitchMotion.Reset();
}
extern "C" JNIEXPORT void JNICALL Java_com_ast_ut99_GameActivity_nativeAimAssistSettings(JNIEnv*, jclass, jint Level)
{
    AndroidAimRequestedLevel.store(Clamp<INT>(Level, 0, 3));
}
extern "C" JNIEXPORT void JNICALL Java_com_ast_ut99_GameActivity_nativeAimAssistInput(JNIEnv*, jclass, jboolean Controller, jfloat RightX, jfloat RightY)
{
    AndroidAimRequestedStickX.store(Clamp<FLOAT>(RightX, -1.f, 1.f));
    AndroidAimRequestedStickY.store(Clamp<FLOAT>(RightY, -1.f, 1.f));
    AndroidAimRequestedController.store(Controller ? 1 : 0);
}

static void AndroidApplyAimAssist(UNSDLViewport* Viewport, FLOAT DeltaTime)
{
    INT Requested = AndroidAimRequestedLevel.load();
    if (AndroidAimLevel != Requested) {
        AndroidAimLevel = Requested;
        AndroidResetAim();
        UT99_ANDROID_SDL_LOGI("Android aim assist level=%d", AndroidAimLevel);
    }
    UBOOL AndroidAimController = AndroidAimRequestedController.load() != 0;
    static INT LastController = -1;
    if (LastController != AndroidAimController) {
        LastController = AndroidAimController;
        UT99_ANDROID_SDL_LOGI("Android aim controller=%d", LastController);
    }
    APlayerPawn* Player = Viewport->Actor;
    // These axes come from dispatch, before SDL consumes the motion event.
    // The legacy v47 mirrors are only updated in menus on the SDL input path.
    FLOAT Stick = Max(Abs(AndroidAimRequestedStickX.load()), Abs(AndroidAimRequestedStickY.load()));
    if (!AndroidAimLevel || !AndroidAimController || Stick > .65f || !Player
        || Player->Health <= 0 || !Player->Weapon || Player->bBehindView || Player->ViewTarget
        || Player->bShowMenu || Viewport->bShowWindowsMouse || !Player->PlayerReplicationInfo
        || Player->PlayerReplicationInfo->bIsSpectator)
    { AndroidResetAim(); return; }
    UObject* Console = (UObject*)Viewport->Console;
    if (Console && Console->GetStateFrame() && Console->GetStateFrame()->StateNode)
    {
        FName State = Console->GetStateFrame()->StateNode->GetFName();
        if (State == FName(TEXT("Typing")) || State == FName(TEXT("MenuTyping"))
            || State == FName(TEXT("KeyMenuing")) || State == FName(TEXT("Menuing")))
        { AndroidResetAim(); return; }
    }
    // Fail closed when team rules are unknown (e.g. during network map setup).
    if (!Player->GameReplicationInfo) { AndroidResetAim(); return; }
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
    if (!Best) { AndroidResetAim(); return; }
    FRotator Aim = BestDirection.Rotation();
    const float Response[] = {0.f, 4.f, 7.f, 11.f};
    const float Speed[] = {0.f, 24.f, 48.f, 84.f};
    INT Yaw = AndroidAimYawMotion.Step(AndroidAim::Angle(Aim.Yaw - Player->ViewRotation.Yaw), Response[AndroidAimLevel], Speed[AndroidAimLevel], DeltaTime, Stick);
    INT Pitch = AndroidAimPitchMotion.Step(AndroidAim::Angle(Aim.Pitch - Player->ViewRotation.Pitch), Response[AndroidAimLevel], Speed[AndroidAimLevel], DeltaTime, Stick);
    Player->ViewRotation.Yaw = (Player->ViewRotation.Yaw + Yaw) & 65535;
    Player->ViewRotation.Pitch = (Player->ViewRotation.Pitch + Pitch) & 65535;
}
#endif
