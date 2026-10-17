class EngineGameAudit extends Mutator;
function PostBeginPlay()
{
    if(DeathMatchPlus(Level.Game)!=None)
    {
        DeathMatchPlus(Level.Game).RemainingBots=0;
        DeathMatchPlus(Level.Game).MinPlayers=0;
    }
    SetTimer(2.0,false);
}
function Timer()
{
    local RegistryProbe RegistryTests;
    local CoreFunctions CoreTests;
    local DynamicArrayProbe DynamicArrays;
    local PointerAudit Pointers;
    local Font FontA, FontB;
    local StaticArrayProbe Arrays;
    local string Value, Returned;
    local int I;
    CoreTests=new(None) class'CoreFunctions'; CoreTests.Run();
    DynamicArrays=new(None) class'DynamicArrayProbe'; DynamicArrays.Run(true);
    Pointers=Spawn(class'PointerAudit');
    Pointers.SetTimer(0,false); Pointers.Timer(); Pointers.Destroy();
    Value="ab"; Returned=(Value $= Value);
    if(Value=="abab" && Returned=="abab") Log("STRING_API PASS concat-self"); else Log("STRING_API FAIL concat-self");
    Value=""; Returned=(Value @= "ab");
    if(Value==" ab" && Returned==" ab") Log("STRING_API PASS space-empty-left"); else Log("STRING_API FAIL space-empty-left");
    Value="ab"; Returned=(Value @= "");
    if(Value=="ab " && Returned=="ab ") Log("STRING_API PASS space-empty-right"); else Log("STRING_API FAIL space-empty-right");
    Value="AbABA"; Returned=(Value -= "ab");
    if(Value=="AbABA" && Returned=="AbABA") Log("STRING_API PASS remove-sensitive"); else Log("STRING_API FAIL remove-sensitive");
    Value="abcabc"; Returned=(Value -= "bc");
    if(Value=="aa" && Returned=="aa") Log("STRING_API PASS remove-repeated"); else Log("STRING_API FAIL remove-repeated");
    Arrays=new(None) class'StaticArrayProbe'; Arrays.Run();

    FontA=class'Canvas'.static.CreateFont(FF_Arial, 20, false, false, false, false, true);
    FontB=class'Canvas'.static.CreateFont(FF_Arial, 20, false, false, false, false, true);
    if(FontA!=None && FontA==FontB) Log("ENGINE_FONT PASS create-and-cache");
    else Log("ENGINE_FONT FAIL create-and-cache");
    RegistryTests=new(None) class'RegistryProbe';
    RegistryTests.Run();
    if(DeathMatchPlus(Level.Game)!=None)
    {
        DeathMatchPlus(Level.Game).CountDown=0;
        DeathMatchPlus(Level.Game).bRequireReady=false;
        DeathMatchPlus(Level.Game).RemainingBots=0;
        DeathMatchPlus(Level.Game).StartMatch();
        Log("ENGINE_GAME match-started");
        // Flush buffered device logs with a bounded diagnostic record block.
        for(I=0;I<100;I++) Log("ENGINE_GAME diagnostic checkpoint"@I);
    }
}
