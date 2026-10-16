class CollisionBoundaries extends Mutator;
function PostBeginPlay()
{
    Super.PostBeginPlay();
    if(DeathMatchPlus(Level.Game)!=None)
    {
        DeathMatchPlus(Level.Game).MinPlayers=0;
        DeathMatchPlus(Level.Game).RemainingBots=0;
        DeathMatchPlus(Level.Game).InitialBots=0;
    }
    SetTimer(1.0,False);
}
function Timer()
{
    local PlayerPawn P;
    local vector Start, HitLocation, HitNormal, Extent, Direction;
    local Actor HitActor;
    local float Limit, Progress, Highest;
    local int I;
    P=Spawn(class'TMale2',,,vect(-448,-800,-180));
    if(P==None) { Log("COLLISION_BOUNDARIES FAIL spawn"); return; }
    P.GotoState(''); P.SetCollision(False,False,False); P.ReducedDamageType='All';
    P.SetPhysics(PHYS_Falling);
    for(I=0;I<60;I++) P.AutonomousPhysics(1.0/60);
    Start=P.Location;
    Extent.X=P.CollisionRadius; Extent.Y=Extent.X; Extent.Z=P.CollisionHeight;
    Direction=vect(-1,0,0);
    P.SetPhysics(PHYS_None);
    P.SetLocation(Start+vect(0,0,32));
    HitActor=Trace(HitLocation,HitNormal,P.Location+Direction*512,P.Location,False,Extent);
    if(HitActor==None) Log("COLLISION_BOUNDARIES FAIL wall-fixture");
    else
    {
        Limit=(HitLocation-P.Location) Dot Direction;
        P.Move(Direction*512);
        Progress=(P.Location-Start) Dot Direction;
        if(Progress>Limit+0.5) Log("COLLISION_BOUNDARIES FAIL crossed-wall"@Progress@Limit);
        else Log("COLLISION_BOUNDARIES PASS solid-wall"@Progress@Limit);
    }
    P.SetLocation(Start); P.Acceleration=vect(0,0,0); P.Velocity=vect(0,0,600);
    HitActor=Trace(HitLocation,HitNormal,Start+vect(0,0,512),Start,False,Extent);
    if(HitActor==None || HitNormal.Z>-0.9) Log("COLLISION_BOUNDARIES FAIL ceiling-fixture");
    else
    {
        Limit=HitLocation.Z;
        Highest=Start.Z;
        P.SetPhysics(PHYS_Falling);
        for(I=0;I<180;I++)
        {
            P.AutonomousPhysics(1.0/60);
            Highest=FMax(Highest,P.Location.Z);
        }
        if(Highest>Limit+0.5) Log("COLLISION_BOUNDARIES FAIL crossed-ceiling"@Highest@Limit);
        else Log("COLLISION_BOUNDARIES PASS solid-ceiling"@Highest@Limit);
    }
    P.Velocity=vect(0,0,0); P.Acceleration=vect(0,0,0);
    for(I=0;I<180;I++) P.AutonomousPhysics(1.0/60);
    Start=P.Location;
    for(I=0;I<600;I++) P.AutonomousPhysics(1.0/60);
    if(VSize(P.Location-Start)>0.01) Log("COLLISION_BOUNDARIES FAIL idle-drift"@Start@P.Location);
    else Log("COLLISION_BOUNDARIES PASS idle-floor");
    P.Destroy();
    Log("COLLISION_BOUNDARIES complete");
    for(I=0;I<120;I++) Log("COLLISION_BOUNDARIES flush padding........................................");
}
defaultproperties { bHidden=True RemoteRole=ROLE_None }
