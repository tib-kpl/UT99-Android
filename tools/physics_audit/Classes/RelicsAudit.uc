// Exercise the original bonus package through the v400 inventory and HUD APIs.
class RelicsAudit extends AnimationObserve;

var int Step;
var Inventory HeldRelic;

function Timer()
{
    local PlayerPawn P;
    local class<Inventory> RelicClass;
    local string ClassName;
    local Actor Manager, Effect;
    local class<Actor> ManagerClass;
    local bool bWave;
    if(Step == 0) Super.Timer();
    foreach AllActors(class'PlayerPawn',P)
        if(P.Player != None && P.myHUD != None)
        {
            if(Step == 0 && DeathMatchPlus(Level.Game) != None)
            {
                DeathMatchPlus(Level.Game).bRequireReady=False;
                DeathMatchPlus(Level.Game).CountDown=0;
                DeathMatchPlus(Level.Game).bNetReady=False;
                DeathMatchPlus(Level.Game).StartMatch();
            }
            if(Step == 1)
            {
                if(P.Health > 40) Log("RELICS PASS regeneration health=" $ P.Health);
                else Log("RELICS FAIL regeneration health=" $ P.Health);
            }
            if(HeldRelic != None) HeldRelic.Destroy();
            if(Step >= 6)
            {
                Log("RELICS COMPLETE samples=" $ Step);
                SetTimer(0,False);
                return;
            }
            if(Step == 0) ClassName="Relics.RelicRegenInventory";
            else if(Step == 1) ClassName="Relics.RelicSpeedInventory";
            else if(Step == 2) ClassName="Relics.RelicDefenseInventory";
            else if(Step == 3) ClassName="Relics.RelicStrengthInventory";
            else if(Step == 4) ClassName="Relics.RelicRedemptionInventory";
            else ClassName="Relics.RelicDeathInventory";
            RelicClass=class<Inventory>(DynamicLoadObject(ClassName,class'Class'));
            if(RelicClass != None) HeldRelic=Spawn(RelicClass,,,P.Location+vect(0,0,80));
            if(HeldRelic != None)
            {
                HeldRelic.Touch(P);
                if(HeldRelic.Owner == P && P.myHUD.HUDMutator != None
                    && P.myHUD.HUDMutator.GetPropertyText("bHUDMutator") == string(True))
                    Log("RELICS PASS pickup=" $ ClassName $ " HUD=" $ P.myHUD.HUDMutator);
                else Log("RELICS FAIL pickup=" $ ClassName $ " owner=" $ HeldRelic.Owner
                    $ " HUD=" $ P.myHUD.HUDMutator
                    $ " registered=" $ P.myHUD.HUDMutator.GetPropertyText("bHUDMutator"));
                if(Step == 0) P.Health=40;
                if(Step == 1)
                {
                    if(P.GroundSpeed > P.Default.GroundSpeed)
                        Log("RELICS PASS speed=" $ P.GroundSpeed);
                    else Log("RELICS FAIL speed=" $ P.GroundSpeed);
                }
                if(Step == 2)
                {
                    if(HeldRelic.ArmorAbsorbDamage(100,'shot',P.Location) == 40)
                        Log("RELICS PASS defense absorption");
                    else Log("RELICS FAIL defense absorption");
                }
                if(Step == 3)
                {
                    if(P.DamageScaling == 2) Log("RELICS PASS strength damage scaling");
                    else Log("RELICS FAIL strength damage scaling");
                }
                if(Step == 4)
                {
                    ManagerClass=class<Actor>(DynamicLoadObject("Relics.RelicRedemption",class'Class'));
                    Manager=Spawn(ManagerClass);
                    HeldRelic.SetPropertyText("MyRelic",string(Manager.Class)$"'"$string(Manager)$"'");
                    P.Health=10;
                    HeldRelic.PrioritizeArmor(1000,'shot',P.Location);
                    if(P.Health == 100 && HeldRelic.bDeleteMe)
                        Log("RELICS PASS redemption survival");
                    else Log("RELICS FAIL redemption survival");
                    Manager.Destroy();
                }
                if(Step == 5)
                {
                    P.Health=0;
                    HeldRelic.Destroy();
                    foreach AllActors(class'Actor',Effect)
                        if(Effect.IsA('DeathWave')) bWave=True;
                    P.Health=100;
                    if(bWave) Log("RELICS PASS vengeance wave");
                    else Log("RELICS FAIL vengeance wave");
                }
            }
            else Log("RELICS FAIL spawn=" $ ClassName);
            Step++;
            SetTimer(3,True);
            return;
        }
}
