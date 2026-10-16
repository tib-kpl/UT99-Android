// Dedicated-server regression fixture; never enable during normal play.
class NetworkTravelAudit extends Mutator;
var int Stage, StableTicks;
var bool Started, Travelling;

simulated function PostBeginPlay()
{
 Super.PostBeginPlay();
 if(string(Level.Outer) ~= "DM-TravelAudit") Stage=1;
 else if(string(Level.Outer) ~= "DM-Oblivion") Stage=2;
 SetTimer(1,True);
}

simulated function Timer()
{
 local PlayerPawn P, LocalPlayer, First, Second;
 local int Players, Armed, Others;
 if(Level.NetMode==NM_Client)
 {
  foreach AllActors(class'PlayerPawn',P)
   if(P.Player!=None) LocalPlayer=P;
  if(LocalPlayer==None) return;
  foreach AllActors(class'PlayerPawn',P)
   if(P!=LocalPlayer && P.PlayerReplicationInfo!=None && P.Mesh!=None) Others++;
  if(LocalPlayer.myHUD!=None && LocalPlayer.Weapon!=None && (Stage!=2 || Others>0))
   Log("NETWORK_TRAVEL_CLIENT PASS map="$string(Level.Outer)$" class="$LocalPlayer.Class$" HUD="$LocalPlayer.myHUD$" weapon="$LocalPlayer.Weapon$" others="$Others);
  else Log("NETWORK_TRAVEL_CLIENT waiting map="$string(Level.Outer));
  return;
 }
 if(Travelling) return;
 foreach AllActors(class'PlayerPawn',P)
  if(P.Player!=None && P.Health>0)
  {
   Players++;
   if(First==None) First=P;
   else if(Second==None) Second=P;
   if(P.Weapon!=None) Armed++;
  }
 if(Players>=2 && !Started)
 {
  Started=True;
  DeathMatchPlus(Level.Game).bRequireReady=False;
  DeathMatchPlus(Level.Game).bNetReady=False;
  DeathMatchPlus(Level.Game).CountDown=0;
  DeathMatchPlus(Level.Game).StartMatch();
 }
 if(Players>=2 && Armed>=2) StableTicks++;
 else StableTicks=0;
 if(Stage==2 && StableTicks==1)
 {
  First.SetLocation(vect(-448,-800,-180));
  First.ClientSetLocation(First.Location,rot(-1500,-16384,0));
  Second.SetLocation(vect(-448,-950,-180));
  Second.ClientSetLocation(Second.Location,rot(-1500,16384,0));
 }
 if(StableTicks<8) return;
 Log("NETWORK_TRAVEL_SERVER PASS stage="$Stage$" map="$string(Level.Outer)$" players="$Players$" armed="$Armed);
 Travelling=True;
 if(Stage==0) Level.ServerTravel("DM-TravelAudit?game=Botpack.DeathMatchPlus?MinPlayers=0?mutator=UT99PhysicsAudit.NetworkTravelAudit?AuditStage=1",False);
 else if(Stage==1) Level.ServerTravel("DM-Oblivion?game=Botpack.DeathMatchPlus?MinPlayers=0?mutator=UT99PhysicsAudit.NetworkTravelAudit?AuditStage=2",False);
 else { Log("NETWORK_TRAVEL_SERVER COMPLETE"); SetTimer(0,False); }
}

defaultproperties
{
 bHidden=True
 bAlwaysRelevant=True
 RemoteRole=ROLE_SimulatedProxy
}
