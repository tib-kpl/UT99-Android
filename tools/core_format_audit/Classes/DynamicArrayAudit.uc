class DynamicArrayAudit extends Mutator;
function PostBeginPlay() { SetTimer(1.0,false); }
function Timer() { local DynamicArrayProbe Tests; local StaticArrayProbe LegacyArrays; Tests=new(None) class'DynamicArrayProbe'; Tests.Run(True); LegacyArrays=new(None) class'StaticArrayProbe'; LegacyArrays.Run(); }
