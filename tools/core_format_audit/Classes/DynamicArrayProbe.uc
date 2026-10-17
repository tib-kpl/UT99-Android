class DynamicArrayProbe extends Object;
var array<int> Values;
var array<string> Strings;
var array<string> Copy;
struct Row { var string Label; var int Value; };
var array<Row> Rows;
var array<Row> RowCopy;
var array<Object> Objects;
function Check(bool Good,string Label)
{
    if (Good) Log("DYN_ARRAY PASS"@Label);
    else Log("DYN_ARRAY FAIL"@Label);
}
function Run(optional bool Android)

{
    local int N,I,J;
    local bool Good;
    Values.Length=3; Values[0]=1; Values[1]=2; Values[2]=3;
    Strings.Length=2; Strings[0]="first"; Strings[1]="second";
    Log("DYN_ARRAY PROBE initial"@Values.Length@Values[0]@Values[2]);
    Values[1]=17;
    Values.Length=5;
    Log("DYN_ARRAY PROBE grow"@Values.Length@Values[1]@Values[4]);
    Values.Insert(1,2);
    Log("DYN_ARRAY PROBE insert"@Values.Length@Values[1]@Values[3]);
    Values.Remove(1,1);
    Log("DYN_ARRAY PROBE remove"@Values.Length@Values[1]@Values[2]);
    Values[8]=88;
    Log("DYN_ARRAY PROBE far-write"@Values.Length@Values[8]);
    N=Values[12];
    Log("DYN_ARRAY PROBE far-read"@Values.Length@N);
    N=Values[-1];
    Log("DYN_ARRAY PROBE negative-read"@Values.Length@N);
    Values.Length=-2;
    Log("DYN_ARRAY PROBE negative-length"@Values.Length);
    Copy=Strings;
    Copy[0]="copy";
    if (Android) { Strings=Strings; Check(Strings.Length==2 && Strings[0]=="first","self-copy"); }
    Log("DYN_ARRAY PROBE strings-copy"@Strings.Length@Strings[0]@Strings[1]@Copy.Length@Copy[0]);
    Strings.Remove(0,1);
    Strings.Insert(0,2);
    Log("DYN_ARRAY PROBE strings-edit"@Strings.Length@Strings[0]@Strings[2]);
    Values.Insert(-1,1);
    Log("DYN_ARRAY PROBE negative-insert"@Values.Length@Values[0]);
    Values.Insert(100,1);
    Log("DYN_ARRAY PROBE far-insert"@Values.Length);
    Values.Remove(1,100);
    Log("DYN_ARRAY PROBE far-remove-count"@Values.Length@Values[0]);
    Check(Values.Length==1 && Values[0]==0,"integer-edits-and-bounds");
    Check(Strings.Length==3 && Strings[0]=="" && Strings[2]=="second" && Copy[0]=="copy","string-deep-copy-edit");
    Rows.Length=2;
    Rows[0].Label="alpha"; Rows[0].Value=10;
    Rows[1].Label="beta"; Rows[1].Value=20;
    RowCopy=Rows;
    Rows.Insert(1,1);
    Check(Rows.Length==3 && Rows[1].Label=="" && Rows[1].Value==0 && Rows[2].Label=="beta","struct-insert-zero");
    Rows.Remove(0,1);
    Rows.Length=1;
    Check(Rows.Length==1 && Rows[0].Label=="" && RowCopy[0].Label=="alpha" && RowCopy[1].Value==20,"struct-deep-copy-shrink");
    Objects.Length=3; Objects[1]=Self;
    Objects.Insert(0,1); Objects.Remove(0,1);
    Check(Objects.Length==3 && Objects[1]==Self && Objects[0]==None && Objects[2]==None,"object-pointer-width");
    Objects.Length=0;
    Good=true;
    for (I=0;I<64;I++)
    {
        Strings.Length=16;
        for (J=0;J<16;J++) Strings[J]=string(I)$":"$string(J);
        Copy=Strings;
        Strings.Length=0;
        if (Copy.Length!=16 || Copy[15]!=(string(I)$":15")) Good=false;
        Strings=Copy;
        Copy.Length=0;
        if (Strings[15]!=(string(I)$":15")) Good=false;
    }
    Check(Good,"repeated-string-ownership");
    if (Android)
    {
        N=Strings.Length;
        Strings[1000]="discarded-owned-string";
        Check(Strings.Length==N && Strings[15]=="63:15","invalid-string-write");
        Values.Length=2147483647;
        Check(Values.Length==1,"overflow-size-rejected");
    }
    Strings.Length=0;
    Rows.Length=0; RowCopy.Length=0;
    Log("DYN_ARRAY COMPLETE");
}
defaultproperties { Values=(1,2,3) Strings=("first","second") }
