class RegistryProbe extends Object;

static function Check(bool Good, string Label)
{
    if(Good) Log("REGISTRY_API PASS"@Label);
    else Log("REGISTRY_API FAIL"@Label);
}

function Run()
{
    local array<Registry.RegistryObjectInfo> Objects;
    local array<Registry.PreferencesInfo> Preferences;
    local array<Registry.RegistryPropertyInfo> Properties, Again;
    local Property Loaded;
    local int I;
    local bool Found;
    Objects=class'Registry'.static.GetRegistryObjects("Class", "Engine.Mutator");
    for(I=0;I<Objects.Length;I++)
        if(Objects[I].Object ~= "UT99CoreFormatAudit.RegistryAudit")
            Found=Objects[I].Description=="Registry audit";
    Check(Found,"objects");
    Preferences=class'Registry'.static.GetPreferences("UT99 compatibility audit");
    Check(Preferences.Length==1,"preferences-count");
    if(Preferences.Length==1)
        Check(Preferences[0].Caption=="Fixture" && Preferences[0].Category=='Audit'
            && Preferences[0].Immediate,"preferences-fields");
    Properties=class'Registry'.static.GetRegistryProperties("UT99CoreFormatAudit.ConfigData");
    Check(Properties.Length==1,"properties-count");
    if(Properties.Length==1)
    {
        Check(Properties[0].Object=="Value" && Properties[0].Title=="A, quoted title"
            && Properties[0].Description=="Fixture description","property-text");
        Check(Properties[0].Config && Properties[0].RequireRestart && !Properties[0].Constant,"property-flags");
        Check(Properties[0].RangeMin==-2 && Properties[0].RangeMax==8 && Properties[0].Step==0.5,"property-range");
        Check(Properties[0].Values.Length==2 && Properties[0].ValueDescriptions.Length==2,"value-count");
        if(Properties[0].Values.Length==2 && Properties[0].ValueDescriptions.Length==2)
            Check(Properties[0].Values[0]=="1" && Properties[0].ValueDescriptions[0]=="One"
                && Properties[0].Values[1]=="2" && Properties[0].ValueDescriptions[1]=="Two","value-labels");
        Loaded=class'Registry'.static.LoadRegistryProperty(Properties[0]);
        Check(Loaded!=None && Loaded.Name=='Value',"load-property");
        Properties[0].Title="changed";
        Again=class'Registry'.static.GetRegistryProperties("UT99CoreFormatAudit.ConfigData");
        Check(Again.Length==1 && Again[0].Title=="A, quoted title","result-ownership");
    }
    Log("REGISTRY_API COMPLETE");
}
