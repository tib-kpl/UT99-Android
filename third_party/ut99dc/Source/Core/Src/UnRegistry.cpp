#include "CorePrivate.h"

#if defined(PLATFORM_ANDROID)
IMPLEMENT_CLASS(URegistry);

namespace
{
#pragma pack(push,4)
struct FAndroidRegistryProperty
{
    FString Object, Class, Title, Description;
    TArray<FString> Values, ValueDescriptions;
    FLOAT RangeMin, RangeMax, Step;
    DWORD Flags;
    FAndroidRegistryProperty(): RangeMin(0), RangeMax(0), Step(0), Flags(0) {}
};
#pragma pack(pop)

static FString RegistryTrim(const FString& Text)
{
    INT First=0, Last=Text.Len();
    while(First<Last && (*Text)[First]<=' ') ++First;
    while(Last>First && (*Text)[Last-1]<=' ') --Last;
    return Text.Mid(First,Last-First);
}

// Split only at the outer level: descriptions and value labels can contain commas.
static TArray<FString> RegistryTokens(const FString& Text)
{
    TArray<FString> Tokens;
    INT Start=0, Depth=0;
    UBOOL Quoted=0;
    for(INT i=0;i<=Text.Len();++i)
    {
        TCHAR C=(*Text)[i];
        if(C=='"' && (i==0 || (*Text)[i-1]!='\\')) Quoted=!Quoted;
        if(!Quoted)
        {
            if(C=='(') ++Depth;
            if(C==')') --Depth;
            if((C==',' && Depth==0) || C==0)
            { new(Tokens)FString(RegistryTrim(Text.Mid(Start,i-Start))); Start=i+1; }
        }
    }
    return Tokens;
}

static FString RegistryUnquote(FString Text)
{
    Text=RegistryTrim(Text);
    if(Text.Len()>=2 && (*Text)[0]=='"' && (*Text)[Text.Len()-1]=='"')
        return Text.Mid(1,Text.Len()-2);
    return Text;
}

static void ReadRegistryProperty(const FString& Text,FAndroidRegistryProperty& Info)
{
    TArray<FString> Tokens=RegistryTokens(Text);
    for(INT i=0;i<Tokens.Num();++i)
    {
        FString Token=Tokens(i);
        if(!appStricmp(*Token,TEXT("Config"))) Info.Flags|=1;
        else if(!appStricmp(*Token,TEXT("RequireRestart"))) Info.Flags|=2;
        else if(!appStricmp(*Token,TEXT("Constant"))) Info.Flags|=4;
        else if(!appStrnicmp(*Token,TEXT("Value("),6) && Token.Right(1)==TEXT(")"))
        {
            FString Value=RegistryUnquote(Token.Mid(6,Token.Len()-7)), Description;
            INT Split=Value.InStr(TEXT("="));
            if(Split!=INDEX_NONE) { Description=Value.Mid(Split+1); Value=Value.Left(Split); }
            else Description=Value;
            new(Info.Values)FString(Value);
            new(Info.ValueDescriptions)FString(Description);
        }
        else if(!appStrnicmp(*Token,TEXT("Range("),6) && Token.Right(1)==TEXT(")"))
        {
            TArray<FString> Range=RegistryTokens(Token.Mid(6,Token.Len()-7));
            if(Range.Num()>0) Info.RangeMin=appAtof(*Range(0));
            if(Range.Num()>1) Info.RangeMax=appAtof(*Range(1));
            if(Range.Num()>2) Info.Step=appAtof(*Range(2));
        }
        else
        {
            INT Equals=Token.InStr(TEXT("="));
            if(Equals==INDEX_NONE) continue;
            FString Key=Token.Left(Equals), Value=RegistryUnquote(Token.Mid(Equals+1));
            if(!appStricmp(*Key,TEXT("Name"))) Info.Object=Value;
            else if(!appStricmp(*Key,TEXT("Class"))) Info.Class=Value;
            else if(!appStricmp(*Key,TEXT("Title"))) Info.Title=Value;
            else if(!appStricmp(*Key,TEXT("Description"))) Info.Description=Value;
        }
    }
}
}

void URegistry::execGetRegistryObjects(FFrame& Stack,RESULT_DECL)
{
    P_GET_STR(ClassName);
    P_GET_STR_OPTX(MetaClassName,TEXT(""));
    P_FINISH;
    CacheDrivers(0);
    TArray<FRegistryObjectInfo> Results;
    for(INT i=0;i<GObjDrivers.Num();++i)
        if(!appStricmp(*GObjDrivers(i).Class,*ClassName)
        && !appStricmp(*GObjDrivers(i).MetaClass,*MetaClassName))
            new(Results)FRegistryObjectInfo(GObjDrivers(i));
    *(TArray<FRegistryObjectInfo>*)Result=Results;
}
IMPLEMENT_FUNCTION(URegistry,INDEX_NONE,execGetRegistryObjects);

void URegistry::execGetPreferences(FFrame& Stack,RESULT_DECL)
{
    P_GET_STR_OPTX(ParentCaption,TEXT(""));
    P_FINISH;
    TArray<FPreferencesInfo> Results;
    UObject::GetPreferences(Results,*ParentCaption,0);
    *(TArray<FPreferencesInfo>*)Result=Results;
}
IMPLEMENT_FUNCTION(URegistry,INDEX_NONE,execGetPreferences);

void URegistry::execGetRegistryProperties(FFrame& Stack,RESULT_DECL)
{
    P_GET_STR(ClassName);
    P_FINISH;
    TArray<FAndroidRegistryProperty> Results;
    TArray<FString> Visited;
    for(INT Path=0;Path<GSys->Paths.Num();++Path)
    {
        INT Star=GSys->Paths(Path).InStr(TEXT("*."));
        if(Star==INDEX_NONE) continue;
        FString Directory=GSys->Paths(Path).Left(Star);
        TArray<FString> Files=GFileManager->FindFiles(*(Directory+TEXT("*.int")),1,0);
        for(INT File=0;File<Files.Num();++File)
        {
            FString Base=Directory+Files(File).Left(Files(File).Len()-4);
            if(Visited.FindItemIndex(Base)!=INDEX_NONE) continue;
            new(Visited)FString(Base);
            FString Localized=Base+TEXT(".")+UObject::GetLanguage();
            TMultiMap<FString,FString>* Section=GConfig->GetSectionPrivate(TEXT("Public"),0,1,*Localized);
            if(!Section) Section=GConfig->GetSectionPrivate(TEXT("Public"),0,1,*(Base+TEXT(".int")));
            if(!Section) continue;
            for(TMultiMap<FString,FString>::TIterator It(*Section);It;++It)
            {
                if(appStricmp(*It.Key(),TEXT("Property"))) continue;
                FString Value=It.Value();
                if(Value.Len()<2 || Value.Left(1)!=TEXT("(") || Value.Right(1)!=TEXT(")")) continue;
                FAndroidRegistryProperty Info;
                ReadRegistryProperty(Value.Mid(1,Value.Len()-2),Info);
                if(Info.Object.Len() && !appStricmp(*Info.Class,*ClassName))
                    new(Results)FAndroidRegistryProperty(Info);
            }
        }
    }
    *(TArray<FAndroidRegistryProperty>*)Result=Results;
}
IMPLEMENT_FUNCTION(URegistry,INDEX_NONE,execGetRegistryProperties);

void URegistry::execLoadRegistryProperty(FFrame& Stack,RESULT_DECL)
{
    P_GET_STRUCT(FAndroidRegistryProperty,Info);
    P_FINISH;
    *(UProperty**)Result=NULL;
    UClass* Class=LoadObject<UClass>(NULL,*Info.Class,NULL,LOAD_NoWarn,NULL);
    if(!Class) return;
    for(TFieldIterator<UProperty> It(Class);It;++It)
        if(!appStricmp(It->GetName(),*Info.Object)) { *(UProperty**)Result=*It; return; }
}
IMPLEMENT_FUNCTION(URegistry,INDEX_NONE,execLoadRegistryProperty);
#endif
