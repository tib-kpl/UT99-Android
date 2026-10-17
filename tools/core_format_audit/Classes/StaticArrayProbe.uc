class StaticArrayProbe extends Object;
var array<string,4> Values;
static function Check(bool Good,string Label)
{
    if(Good) Log("STATIC_ARRAY PASS"@Label);
    else Log("STATIC_ARRAY FAIL"@Label);
}
function Run()
{
    local string Value;
    Check(Values.Length==0,"initial-empty");
    Value=Values[2];
    Check(Values.Length==4 && Value=="","read-restores-extent");
    Values[2]="stored";
    Check(Values.Length==4 && Values[2]=="stored","write-in-extent");
    Values[5]="outside";
    Check(Values.Length==4 && Values[3]=="outside","legacy-clamped-write");
    Values.Length=8;
    Values[6]="extended";
    Check(Values.Length==8 && Values[6]=="extended" && Values[3]=="outside","explicit-growth");
    Values.Length=1;
    Value=Values[0];
    Check(Values.Length==4 && Values[2]=="","shrink-and-restore");
    Log("STATIC_ARRAY COMPLETE");
}
