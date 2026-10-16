class HookProbe extends Mutator;

var bool bForward;
var int EndCalls, RestartCalls;

function bool HandleEndGame()
{
    EndCalls++;
    if (bForward) return Super.HandleEndGame();
    return true;
}
function bool HandleRestartGame()
{
    RestartCalls++;
    if (bForward) return Super.HandleRestartGame();
    return true;
}
function bool HandlePickupQuery(Pawn Other, Inventory item, out byte bAllowPickup)
{
    if (bForward) return Super.HandlePickupQuery(Other, item, bAllowPickup);
    bAllowPickup=7;
    return true;
}
function bool HandlePauseRequest(PlayerPawn Other)
{
    if (bForward) return Super.HandlePauseRequest(Other);
    return Other != None;
}
function bool PreventDeath(Pawn Killed, Pawn Killer, name damageType, vector HitLocation)
{
    if (bForward) return Super.PreventDeath(Killed,Killer,damageType,HitLocation);
    return damageType=='AuditDamage' && HitLocation==vect(1,2,3);
}
function ModifyLogin(out class<playerpawn> SpawnClass, out string Portal, out string Options)
{
    if (bForward) Super.ModifyLogin(SpawnClass,Portal,Options);
    else
    {
        SpawnClass=class'Botpack.TMale2';
        Portal="AuditPortal";
        Options=Options$"?Audit=1";
    }
}
function bool MutatorTeamMessage(Actor Sender, Pawn Receiver, PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
    if (bForward) return Super.MutatorTeamMessage(Sender,Receiver,PRI,S,Type,bBeep);
    return S=="audit" && Type=='AuditType' && bBeep;
}
function bool MutatorBroadcastMessage(Actor Sender, Pawn Receiver, out coerce string Msg, optional bool bBeep, out optional name Type)
{
    if (bForward) return Super.MutatorBroadcastMessage(Sender,Receiver,Msg,bBeep,Type);
    Msg=Msg$"-forwarded";
    Type='AuditReply';
    return bBeep;
}
function bool MutatorBroadcastLocalizedMessage(Actor Sender, Pawn Receiver, out class<LocalMessage> Message, out optional int MessageSwitch, out optional PlayerReplicationInfo RelatedPRI_1, out optional PlayerReplicationInfo RelatedPRI_2, out optional Object OptionalObject)
{
    if (bForward) return Super.MutatorBroadcastLocalizedMessage(Sender,Receiver,Message,MessageSwitch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
    Message=class'LocalMessage';
    MessageSwitch=469;
    OptionalObject=Self;
    return false;
}
