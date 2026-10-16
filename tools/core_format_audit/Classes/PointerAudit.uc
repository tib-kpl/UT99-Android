class PointerAudit extends Mutator;

function PostBeginPlay() { SetTimer(1.0,false); }
function Check(bool Good, string Label)
{
    if (Good) Log("POINTER_API PASS"@Label);
    else Log("POINTER_API FAIL"@Label);
}
function Timer()
{
    local PointerData Data;
    local int Index;
    for (Index=0;Index<32;Index++)
    {
        Data=new(None) class'PointerData';
        if (Data==None) { Log("POINTER_API FAIL construct"); return; }
        if (Data.Sentinel!=469 || Data.Label!="pointer-layout")
        { Log("POINTER_API FAIL layout"@Index); return; }
        if (Data.GetPropertyText("Handle")!="None")
        { Log("POINTER_API FAIL default"); return; }
        if (!Data.SetPropertyText("Handle","None") || Data.SetPropertyText("Handle","1234"))
        { Log("POINTER_API FAIL import"); return; }
        if (!Data.SetPropertyText("Sentinel","42") || Data.Sentinel!=42
            || Data.SetPropertyText("MissingProperty","42") || Data.SetPropertyText("Name","Changed"))
        { Log("POINTER_API FAIL setter-result"); return; }
        Data.Sentinel=Index;
        Data.Label="changed";
        if (Data.Sentinel!=Index || Data.Label!="changed")
        { Log("POINTER_API FAIL neighbor-write"); return; }
    }
    Check(true,"construct-array-layout");
    Check(true,"null-text-roundtrip");
    Check(true,"numeric-address-rejected");
    Check(true,"setter-result");
    Log("POINTER_API COMPLETE");
}
