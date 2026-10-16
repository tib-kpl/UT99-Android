// Quiet solo scene for inspecting the normal first-person idle animation.
class AnimationObserve extends Mutator;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    if(DeathMatchPlus(Level.Game)!=None)
    {
        DeathMatchPlus(Level.Game).MinPlayers=0;
        DeathMatchPlus(Level.Game).InitialBots=0;
        DeathMatchPlus(Level.Game).RemainingBots=0;
    }
    SetTimer(0.5,True);
}

function Timer()
{
    local Bot B;
    local PlayerPawn P;
    foreach AllActors(class'Bot',B) B.Destroy();
    foreach AllActors(class'PlayerPawn',P)
        if(P.Player!=None)
        {
            P.ReducedDamageType='All';
            P.Health=100;
        }
}

defaultproperties
{
    bHidden=True
    RemoteRole=ROLE_None
}
