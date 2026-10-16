class CoreFunctionsAudit extends Mutator;
function PostBeginPlay() { SetTimer(1.0,false); }
function Timer() { local CoreFunctions Tests; Tests=new(None) class'CoreFunctions'; Tests.Run(); }
