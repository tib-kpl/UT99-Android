// Controlled dedicated-server fixture for original Relics inventory replication.
class RelicsNetworkAudit extends Mutator;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(1,True);
}

simulated function Timer()
{
    local PlayerPawn P;
    local Inventory Item;
    local class<Inventory> RelicClass;
    if(Level.NetMode != NM_Client)
        RelicClass=class<Inventory>(DynamicLoadObject("Relics.RelicRegenInventory",class'Class'));
    foreach AllActors(class'PlayerPawn',P)
        if(P.Player != None && P.Health > 0)
        {
            if(Level.NetMode != NM_Client && P.FindInventoryType(RelicClass) == None)
            {
                Item=Spawn(RelicClass,,,P.Location+vect(0,0,80));
                if(Item != None)
                {
                    Item.Touch(P);
                    if(Item.Owner == P) P.Health=40;
                }
            }
            if(Level.NetMode == NM_Client && P.myHUD != None)
                Log("RELICS_NETWORK_CLIENT health=" $ P.Health
                    $ " HUD=" $ P.myHUD.HUDMutator
                    $ " registered=" $ P.myHUD.HUDMutator.GetPropertyText("bHUDMutator"));
            else if(Level.NetMode != NM_Client)
                Log("RELICS_NETWORK_SERVER player=" $ P.PlayerReplicationInfo.PlayerID
                    $ " health=" $ P.Health $ " relic=" $ P.FindInventoryType(RelicClass));
        }
}

defaultproperties
{
    bAlwaysRelevant=True
    bHidden=True
    RemoteRole=ROLE_SimulatedProxy
}
