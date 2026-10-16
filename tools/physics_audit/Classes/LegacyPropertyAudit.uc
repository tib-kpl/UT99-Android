// Compile against v400: SetPropertyText is still declared void there.
class LegacyPropertyAudit extends Mutator;
var int Value;
function PostBeginPlay() { SetTimer(1.0,false); }
function Timer()
{
    local name OriginalName;
    OriginalName=Name;
    SetPropertyText("Value","400");
    SetPropertyText("Name","MustNotChange");
    if (Value==400 && Name==OriginalName) Log("LEGACY_PROPERTY PASS void-setter");
    else Log("LEGACY_PROPERTY FAIL void-setter");
}
