// Controlled two-client fixture. Never enable on a public or normal game server.
class NetworkPlayAudit extends Mutator;

var bool Positioned;
var int TickCount;
var int FirstID, SecondID;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(2.0, True);
}

function Timer()
{
    local PlayerPawn P, First, Second;
    local int Count, InventoryCount;
    local Inventory Item;

    TickCount++;
    foreach AllActors(class'PlayerPawn', P)
        if(P.Player != None && P.Health > 0)
        {
            Count++;
            if(First == None) First=P;
            else if(Second == None) Second=P;
            InventoryCount=0;
            for(Item=P.Inventory; Item!=None; Item=Item.Inventory) InventoryCount++;
            Log("NETWORK_PLAY_AUDIT player=" $ P.PlayerReplicationInfo.PlayerID
                $ " health=" $ P.Health $ " location=" $ P.Location
                $ " weapon=" $ P.Weapon $ " inventory=" $ InventoryCount);
        }

    if(First!=None && Second!=None && First.Weapon!=None && Second.Weapon!=None &&
       (!Positioned || FirstID!=First.PlayerReplicationInfo.PlayerID || SecondID!=Second.PlayerReplicationInfo.PlayerID))
    {
        First.SetLocation(vect(-448,-800,-180));
        First.Velocity=vect(0,0,0);
        First.ClientSetLocation(First.Location,rot(-1500,-16384,0));
        Second.SetLocation(vect(-448,-950,-180));
        Second.Velocity=vect(0,0,0);
        Second.ClientSetLocation(Second.Location,rot(-1500,16384,0));
        Positioned=True;
        FirstID=First.PlayerReplicationInfo.PlayerID;
        SecondID=Second.PlayerReplicationInfo.PlayerID;
        Log("NETWORK_PLAY_AUDIT positioned-two-clients");
    }
    if(TickCount%5==0) Log("NETWORK_PLAY_AUDIT clients=" $ Count);
}

defaultproperties
{
    bHidden=True
    RemoteRole=ROLE_None
}
