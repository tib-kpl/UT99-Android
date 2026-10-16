class OblivionWallAudit extends Mutator;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if(DeathMatchPlus(Level.Game)!=None)
    {
        DeathMatchPlus(Level.Game).MinPlayers=0;
        DeathMatchPlus(Level.Game).RemainingBots=0;
        DeathMatchPlus(Level.Game).InitialBots=0;
    }
    SetTimer(1.0, False);
}

function RunCase(PlayerPawn P, int Side, int Route, int Offset, int FPS, int Mode)
{
    local vector Start, Finish, Direction, Before;
    local float Dt, Distance, Progress, WorstStall, Stall;
    local int I;
    Start=vect(0,-543.1790,-157.3358); Start.X=Side*494.7016;
    Finish=Start+vect(0,-400,0);
    Finish.Z = Start.Z;
    Direction = Normal(Finish - Start);
    if(Route==1) Direction.X=Side*0.01;
    if(Route==2) Direction.X=Side*0.1;
    if(Route==3) Direction.X=Side*0.5;
    Direction=Normal(Direction);
    P.GroundSpeed=400;
    P.bIsWalking=(Mode==1);
    if(Mode==2) P.GroundSpeed=40;
    if(Mode==3) P.GroundSpeed=120;
    Distance = VSize(Finish - Start);
    Dt = 1.0 / FPS;
    P.Velocity=vect(0,0,0);
    P.Acceleration=vect(0,0,0);
    P.SetPropertyText("bHitSlopedWall","False");
    if(!P.SetLocation(Start)) { Log("OBLIVION_WALL_AUDIT invalid-start"@Side@Route@Offset@Start); return; }

    Log("OBLIVION_WALL_START requested="@Start@"actual="@P.Location); Start=P.Location;
    P.SetPhysics(PHYS_Walking);
    for(I=0; I<FPS*24; I++)
    {
        Before=P.Location;
        P.Acceleration=Direction*P.AccelRate;
        P.AutonomousPhysics(Dt);
        Progress=Abs(P.Location.Y-Start.Y);
        if(Progress>=Distance-10) break;
        if(VSize(P.Location-Before)<0.01) Stall+=Dt;
        else Stall=0;
        WorstStall=FMax(WorstStall,Stall);
        if(Stall>0.5) break;
    }
    Log("OBLIVION_WALL_AUDIT result side=" $ Side $ " route=" $ Route $ " offset=" $ Offset $ " mode=" $ Mode $ " fps=" $ FPS $ " progress=" $ Progress $ " distance=" $ Distance $ " stall=" $ WorstStall $ " location=" $ P.Location $ " physics=" $ P.Physics);
}

function Timer()
{
    local PlayerPawn P;
    local int Side, Route, Offset, Rate, Mode;
    P=Spawn(class'TMale2',,,vect(448,-160,-50));
    if(P==None) { Log("OBLIVION_WALL_AUDIT spawn-failed"); return; }
    P.GotoState('');
    P.SetCollision(True,True,True);
    P.ReducedDamageType='All';
    P.Health=100000;
    for(Side=-1; Side<=1; Side+=2)
        for(Route=0; Route<4; Route++)
            for(Mode=0; Mode<4; Mode++)
                for(Rate=0; Rate<6; Rate++)
                {
                    if(Rate==0) RunCase(P,Side,Route,0,30,Mode);
                    if(Rate==1) RunCase(P,Side,Route,0,60,Mode);
                    if(Rate==2) RunCase(P,Side,Route,0,90,Mode);
                    if(Rate==3) RunCase(P,Side,Route,0,120,Mode);
                    if(Rate==4) RunCase(P,Side,Route,0,144,Mode);
                    if(Rate==5) RunCase(P,Side,Route,0,200,Mode);
                }
    P.Destroy();
    Log("OBLIVION_WALL_AUDIT complete" );
    // Flush the legacy engine's buffered test log before collecting it with ADB.
    for(Rate=0; Rate<120; Rate++) Log("OBLIVION_WALL_AUDIT flush padding........................................");
}

defaultproperties { bHidden=True RemoteRole=ROLE_None }
