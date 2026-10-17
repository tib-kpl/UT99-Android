class RegistryAudit extends Mutator;
function PostBeginPlay() { SetTimer(1.0,false); }
function Timer() { local RegistryProbe Tests; Tests=new(None) class'RegistryProbe'; Tests.Run(); }
