class CoreFunctions extends Object;

static function Check(bool Good,string Label)
{
    if (Good) Log("CORE_API PASS"@Label);
    else Log("CORE_API FAIL"@Label);
}
static function TraceProbe() { Log("CORE_API TRACE probe"); }
function Run()
{
    local int I;
    local float R;
    local bool Good;
    local string Value;
    local ConfigData Config;
    Check(Locs("AbC123")=="abc123","lowercase");
    Check(Repl("AbAba","ab","X")=="XXa","replace-insensitive");
    Check(Repl("AbAba","ab","X",true)=="AbAba","replace-sensitive");
    Check(Repl("aaaa","aa","x")=="xx","replace-overlap");
    Check(Repl("ab","a","aa")=="aab","replace-original-input");
    Check(Repl("ababa","b", "")=="aaa","replace-delete");
    Good=true;
    for (I=0;I<1000;I++)
    {
        R=RandRange(-2.0,5.0);
        if (R < -2.0 || R > 5.0) Good=false;
    }
    Check(Good && RandRange(3.0,3.0)==3.0,"random-range");
    SetUTracing(true);
    Check(IsUTracing(),"trace-enabled");
    TraceProbe();
    SetUTracing(false);
    Check(!IsUTracing(),"trace-disabled");
    Value="unchanged";
    Check(!GetDefaultValue(Value,None,"Missing") && Value=="unchanged","default-null-object");
    Config=new(None) class'ConfigData';
    Value="unchanged";
    Check(GetDefaultValue(Value,Config,"Value") && Value=="99","config-read");
    Config.Value=42;
    Value="unchanged";
    Check(GetDefaultValue(Value,Config,"Value") && Value=="99","config-not-live-value");
    Value="unchanged";
    Check(!GetDefaultValue(Value,Config,"Values",1) && Value=="unchanged","config-missing-key");
    Check(!GetDefaultValue(Value,Config,"Name") && !GetDefaultValue(Value,class'ConfigData',"Value"),"config-reject-invalid");
    Config.ClearConfig("Value");
    Value="unchanged";
    Check(!GetDefaultValue(Value,Config,"Value") && Value=="unchanged" && Config.Value==42,"config-clear-key");
    Check(GetDefaultValue(Value,Config,"Label") && Value=="current-value","config-preserve-other-key");
    Config.ClearConfig();
    Value="unchanged";
    Check(!GetDefaultValue(Value,Config,"Label") && Config.Value==42,"config-clear-all");
    Config.Value=43;
    Config.SaveConfig();
    class'ConfigData'.static.StaticClearConfig("Value");
    Check(!GetDefaultValue(Value,Config,"Value"),"config-static-clear-key");
    Log("CORE_API COMPLETE");
}
