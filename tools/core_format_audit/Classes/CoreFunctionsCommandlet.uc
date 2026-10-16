class CoreFunctionsCommandlet extends Commandlet;
event int Main(string Parms) { local CoreFunctions Tests; Tests=new(None) class'CoreFunctions'; Tests.Run(); return 0; }
defaultproperties { LogToStdout=True IsClient=False IsServer=False IsEditor=True LazyLoad=True }
