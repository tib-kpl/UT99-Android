// Compile with a later UT compiler; never include this fixture in release APKs.
class CompatAudit extends Mutator;

var int Sentinel, NetBeginCalls;
var bool bTested;
replication
{
    reliable if (Role==ROLE_Authority) Sentinel;
}
simulated event PostBeginPlay()
{
    if (Role==ROLE_Authority) Sentinel=469;
    SetTimer(2.0,true);
}
simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();
    NetBeginCalls++;
    if (Sentinel==469 && NetBeginCalls==1) Log("NET_API PASS initial-event");
    else Log("NET_API FAIL initial-event"@Sentinel@NetBeginCalls);
}
simulated function Check(bool Good, string Label)
{
    if (Good) Log("NET_API PASS"@Label);
    else Log("NET_API FAIL"@Label);
}
simulated event Timer()
{
    local Mutator Root;
    local HookProbe Relay, Leaf;
    local byte Allow;
    local class<PlayerPawn> SpawnClass;
    local string Portal, Options, Msg;
    local name MessageType;
    local class<LocalMessage> Message;
    local int MessageSwitch;
    local PlayerReplicationInfo PRI1, PRI2;
    local Object Optional;
    local PlayerPawn P;
    local float SavedMessageTime;
    local DecalProbe D;
    local PockProbe Mark;
    local UT_ShieldBelt Belt, NewBelt;
    local Armor2 Armor;

    if (bTested) return;
    bTested=true;
    Root=Spawn(class'Mutator');
    Relay=Spawn(class'HookProbe');
    Leaf=Spawn(class'HookProbe');
    Check(!Root.HandleEndGame() && !Root.HandleRestartGame(),"empty-hooks");
    Check(Root.MutatorTeamMessage(Self,None,None,"",'None'),"empty-message");
    Relay.bForward=true;
    Root.NextMutator=Relay;
    Relay.NextMutator=Leaf;
    Root.NextMessageMutator=Relay;
    Relay.NextMessageMutator=Leaf;
    Check(Root.HandleEndGame() && Relay.EndCalls==1 && Leaf.EndCalls==1,"end-chain");
    Check(Root.HandleRestartGame() && Relay.RestartCalls==1 && Leaf.RestartCalls==1,"restart-chain");
    Check(Root.HandlePickupQuery(None,None,Allow) && Allow==7,"pickup-out");
    Check(Root.PreventDeath(None,None,'AuditDamage',vect(1,2,3)),"death-parameters");
    Options="start";
    Root.ModifyLogin(SpawnClass,Portal,Options);
    Check(SpawnClass==class'Botpack.TMale2' && Portal=="AuditPortal" && Options=="start?Audit=1","login-out");
    Check(Root.MutatorTeamMessage(Self,None,None,"audit",'AuditType',true),"team-parameters");
    Msg="audit";
    Check(Root.MutatorBroadcastMessage(Self,None,Msg,true,MessageType) && Msg=="audit-forwarded" && MessageType=='AuditReply',"broadcast-out");
    Check(!Root.MutatorBroadcastLocalizedMessage(Self,None,Message,MessageSwitch,PRI1,PRI2,Optional) && MessageSwitch==469 && Message==class'LocalMessage' && Optional==Leaf,"localized-out");
    foreach AllActors(class'PlayerPawn',P)
        if (P.Player!=None && P.myHUD!=None)
        {
            Check(Root.HandlePauseRequest(P),"pause-parameters");
            Check(!P.myHUD.ProcessKeyEvent(0,0,0),"hud-key-base");
            SavedMessageTime=P.LastMessageWindow;
            P.LastMessageWindow=123.5;
            Check(P.LastMessageWindow==123.5,"message-window-field");
            P.LastMessageWindow=SavedMessageTime;
            Root.RegisterHUDMutator();
            Root.RegisterHUDMutator();
            Check(P.myHUD.HUDMutator==Root && Root.NextHUDMutator!=Root && Root.bHUDMutator,"hud-register-once");
            P.myHUD.HUDMutator=Root.NextHUDMutator;
            break;
        }
    D=Spawn(class'DecalProbe');
    if(D!=None) { D.Texture=None; D.AttachToSurface(); }
    Check(D!=None && D.bDeleteMe,"decal-no-surface-destroys");
    Mark=Spawn(class'PockProbe');
    if(Mark!=None) { Mark.Texture=None; Mark.AttachToSurface(); }
    Check(Mark!=None && !Mark.bDeleteMe && !Mark.bAttached,"pock-no-surface-defers-destroy");
    if(Mark!=None) Mark.Destroy();
    Belt=Spawn(class'UT_ShieldBelt');
    NewBelt=Spawn(class'UT_ShieldBelt');
    Armor=Spawn(class'Armor2');
    if(Belt!=None && NewBelt!=None && Armor!=None)
    {
        Belt.SetOwner(Root);
        Armor.SetOwner(Root);
        Root.Inventory=Belt;
        Belt.Inventory=Armor;
        Check(Belt.HandlePickupQuery(NewBelt) && Armor.bDeleteMe && !Belt.bDeleteMe,"shield-removes-other-armor");
        Belt.Destroy(); NewBelt.Destroy();
        Root.Inventory=None;
    }
    else Check(false,"shield-removes-other-armor");
    Root.Destroy(); Relay.Destroy(); Leaf.Destroy();
    Log("NET_API COMPLETE");
}
defaultproperties
{
    bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
}
