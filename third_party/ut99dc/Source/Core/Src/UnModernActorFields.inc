// Data fields added after v400. Network flags are omitted on the legacy API.
    if(!appStricmp(Owner->GetName(),TEXT("LevelInfo")))
    {
        FParam Additional[]={
        {TEXT("bLowRes"),Bool,NULL,0x00004000},
        {TEXT("VisibleGroups"),String,NULL,0x00400000},
        {TEXT("ServerMoveVersion"),Int,NULL,0x00000000},
        {TEXT("EngineRevision"),String,NULL,0x00400000},
        {TEXT("EngineArchitecture"),String,NULL,0x00400000},
        {TEXT("bNextURLAbsolute"),Bool,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("Pawn")))
    {
        FParam Additional[]={
        {TEXT("bPawnLink"),Bool,NULL,0x00000002},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("PlayerPawn")))
    {
        FParam Additional[]={
        {TEXT("ReceivedSecretChecksum"),Bool,NULL,0x00000000},
        {TEXT("LastMessageWindow"),Float,NULL,0x00000000},
        {TEXT("bCyclingView"),Bool,NULL,0x00000000},
        {TEXT("ViewDelay"),Float,NULL,0x00000000},
        {TEXT("LastView"),Float,NULL,0x00000000},
        {TEXT("LoginAttempts"),Int,NULL,0x00000000},
        {TEXT("MaxNameChanges"),Int,NULL,0x00000000},
        {TEXT("MinFOV"),Float,NULL,0x00000000},
        {TEXT("MaxFOV"),Float,NULL,0x00000000},
        {TEXT("NameChanges"),Int,NULL,0x00000000},
        {TEXT("SpeechDelay"),Float,NULL,0x00000000},
        {TEXT("LastTaunt"),Float,NULL,0x00000000},
        {TEXT("TauntDelay"),Float,NULL,0x00000000},
        {TEXT("NextLoginTime"),Float,NULL,0x00000000},
        {TEXT("bLoginDisabled"),Bool,NULL,0x00000000},
        {TEXT("LastSpeech"),Float,NULL,0x00000000},
        {TEXT("bNoMouseSmoothing"),Bool,NULL,0x00044001},
        {TEXT("AdjustLocationOffset"),Vector,NULL,0x00002000},
        {TEXT("AdjustLocationAlpha"),Float,NULL,0x00002000},
        {TEXT("LastClientTimestamp"),Float,NULL,0x00002000},
        {TEXT("LastClientLocation"),Vector,NULL,0x00002000},
        {TEXT("PreAdjustLocation"),Vector,NULL,0x00002000},
        {TEXT("bDisableMovementBuffering"),Bool,NULL,0x00044001},
        {TEXT("AccumulatedVTurn"),Float,NULL,0x00002000},
        {TEXT("bPausePressed"),Bool,NULL,0x00002000},
        {TEXT("AccumulatedHTurn"),Float,NULL,0x00002000},
        {TEXT("ClientMovementVersion"),Int,NULL,0x00000000},
        {TEXT("ServerMovementVersion"),Int,NULL,0x00000000},
        {TEXT("StoredCanvasY"),Int,NULL,0x00002000},
        {TEXT("StoredCanvasX"),Int,NULL,0x00002000},
        {TEXT("DesiredNarrowFOV"),Float,NULL,0x00046000},
        {TEXT("FOVFix"),Byte,NULL,0x00046000},
        {TEXT("WeaponFOVScale"),Float,NULL,0x00046000},
        {TEXT("CheatFlyingSpeed"),Float,NULL,0x00000000},
        {TEXT("bLegacyVolumeBoost"),Bool,NULL,0x00044000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("GameInfo")))
    {
        FParam Additional[]={
        {TEXT("MessageMutator"),Object,TEXT("Mutator"),0x00000000},
        {TEXT("bExternalBatcher"),Bool,NULL,0x00044000},
        {TEXT("EnabledMutators"),String,NULL,0x00400000},
        {TEXT("bLogAdminActions"),Bool,NULL,0x00044000},
        {TEXT("MinFOV"),Float,NULL,0x00004000},
        {TEXT("MaxFOV"),Float,NULL,0x00004000},
        {TEXT("ActionToTake"),Byte,NULL,0x00044000},
        {TEXT("MaxLoginAttempts"),Int,NULL,0x00044000},
        {TEXT("PlayerViewDelay"),Float,NULL,0x00044000},
        {TEXT("PlayerSpeechDelay"),Float,NULL,0x00044000},
        {TEXT("PlayerTauntDelay"),Float,NULL,0x00044000},
        {TEXT("MaxNameChanges"),Int,NULL,0x00004000},
        {TEXT("LoginDelaySeconds"),Float,NULL,0x00044000},
        {TEXT("NoLockdown"),Int,NULL,0x00044000},
        {TEXT("bFixFeignDeathZoomBug"),Bool,NULL,0x00004000},
        {TEXT("bFixMultiWeaponBug"),Bool,NULL,0x00004000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("Inventory")))
    {
        FParam Additional[]={
        {TEXT("bCalcDrawOffsetFOV"),Bool,NULL,0x00002000},
        {TEXT("bDefaultInventory"),Bool,NULL,0x00002000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("Mover")))
    {
        FParam Additional[]={
        {TEXT("oldRot"),Rotator,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("StatLog")))
    {
        FParam Additional[]={
        {TEXT("bWorldBatcherError"),Bool,NULL,0x00044000},
        {TEXT("bLogTypingEvents"),Bool,NULL,0x00044001},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("StatLogFile")))
    {
        FParam Additional[]={
        {TEXT("Encoding"),Byte,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("SavedMove")))
    {
        FParam Additional[]={
        {TEXT("SavedLocation"),Vector,NULL,0x00000000},
        {TEXT("SavedVelocity"),Vector,NULL,0x00000000},
        {TEXT("SavedViewRotation"),Rotator,NULL,0x00000000},
        {TEXT("MergeCount"),Byte,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("Mutator")))
    {
        FParam Additional[]={
        {TEXT("bHUDMutator"),Bool,NULL,0x00000000},
        {TEXT("NextHUDMutator"),Object,TEXT("Mutator"),0x00000000},
        {TEXT("NextMessageMutator"),Object,TEXT("Mutator"),0x00000000},
        {TEXT("bAddToPackageMap"),Bool,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("NavigationPoint")))
    {
        FParam Additional[]={
        {TEXT("bAutoBuilt"),Bool,NULL,0x00000000},
        {TEXT("bTwoWay"),Bool,NULL,0x00000000},
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
    if(!appStricmp(Owner->GetName(),TEXT("Trigger")))
    {
        FParam Additional[]={
        };
        for(INT Index=0;Index<ARRAY_COUNT(Additional);++Index)
            if(!FindObject<UProperty>(Owner,Additional[Index].Name))
            { *Tail=Property(Owner,Additional[Index]); Tail=&(*Tail)->Next; }
        return;
    }
