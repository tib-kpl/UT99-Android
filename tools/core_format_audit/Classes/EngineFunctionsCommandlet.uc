class EngineFunctionsCommandlet extends Commandlet;
function Probe(string PackageName, string MeshName)
{
    Log("SKIN_API " $ PackageName $ " | " $ MeshName $ " = " $ class'Pawn'.static.CheckValidSkinPackage(PackageName, MeshName));
}
event int Main(string Parms)
{
    local string Value, Returned;
    local StaticArrayProbe Arrays;
    local RegistryProbe RegistryTests;
    local array<Registry.RegistryPropertyInfo> Properties;
    local int I;
    RegistryTests=new(None) class'RegistryProbe'; RegistryTests.Run();
    Properties=class'Registry'.static.GetRegistryProperties("OpenGLDrv.OpenGLRenderDevice");
    Log("REGISTRY_API count " $ Properties.Length);
    for(I=0;I<Min(Properties.Length,4);I++)
        Log("REGISTRY_API entry " $ Properties[I].Object $ " | " $ Properties[I].Class $ " | " $ Properties[I].Title $ " | " $ Properties[I].Config $ " | " $ Properties[I].Values.Length);

    Arrays=new(None) class'StaticArrayProbe'; Arrays.Run();
    Value="AbABA"; Returned=(Value -= "ab"); Log("STRING_API remove " $ Value $ " | " $ Returned);
    Value="abcabc"; Value -= "bc"; Log("STRING_API repeated " $ Value);
    Value="ab"; Value @= ""; Log("STRING_API empty-space [" $ Value $ "]");
    Value=""; Value @= "ab"; Log("STRING_API empty-left [" $ Value $ "]");
    Probe("SoldierSkins", "Soldier");
    Probe("SoldierSkins", "Commando");
    Probe("CommandoSkins", "Soldier");
    Probe("Botpack", "Soldier");
    Probe("Engine", "Soldier");
    Probe("Core", "Soldier");
    Probe("UnrealShare", "Soldier");
    Probe("NonexistentSkinPackage", "Soldier");
    Probe("", "Soldier");
    Probe("SoldierSkins", "");
    Probe("soldierskins", "soldier");
    Probe("../SoldierSkins", "Soldier");
    Probe("SoldierSkins.sldr1", "Soldier");
    return 0;
}
defaultproperties { LogToStdout=True IsClient=False IsServer=False IsEditor=True LazyLoad=True }
