class CoreFunctionsCommandlet extends Commandlet;
event int Main(string Parms) { local CoreFunctions Tests; local DynamicArrayProbe Arrays; local StaticArrayProbe LegacyArrays; Tests=new(None) class'CoreFunctions'; Tests.Run(); Arrays=new(None) class'DynamicArrayProbe'; Arrays.Run(); LegacyArrays=new(None) class'StaticArrayProbe'; LegacyArrays.Run(); return 0; }
defaultproperties { LogToStdout=True IsClient=False IsServer=False IsEditor=True LazyLoad=True }
