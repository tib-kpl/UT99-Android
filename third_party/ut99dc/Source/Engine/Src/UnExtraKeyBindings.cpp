#include "EnginePrivate.h"
#include "UnExtraKeyBindings.h"

#if defined(PLATFORM_ANDROID)
// Register in UTMenu, matching the public bonus-pack metadata class identity.
UClass UUTExtraKeyBindings::PrivateStaticClass
(
    EC_NativeConstructor,sizeof(UUTExtraKeyBindings),0,UObject::StaticClass(),
    UObject::StaticClass(),FGuid(0,0,0,0),TEXT("UTExtraKeyBindings"),TEXT("UTMenu"),UObject::StaticConfigName(),
    RF_Public|RF_Standalone|RF_Transient|RF_Native,
    UUTExtraKeyBindings::InternalConstructor,
    (void(UObject::*)())&UUTExtraKeyBindings::StaticConstructor
);

void UUTExtraKeyBindings::StaticConstructor()
{
    new(GetClass(),TEXT("SectionName"),RF_Public)UStrProperty(CPP_PROPERTY(SectionName),TEXT(""),CPF_Localized);
    UStrProperty* Labels=new(GetClass(),TEXT("LabelList"),RF_Public)UStrProperty(CPP_PROPERTY(LabelList),TEXT(""),CPF_Localized);
    Labels->ArrayDim=30;
    UStrProperty* Aliases=new(GetClass(),TEXT("AliasNames"),RF_Public)UStrProperty(CPP_PROPERTY(AliasNames),TEXT(""),0);
    Aliases->ArrayDim=30;
}

static FString ExtraBindingText(UClass* Provider,UUTExtraKeyBindings* Data,INT Index)
{
    FString Value=Index<0 ? Data->SectionName : Data->LabelList[Index];
    FString Key=Index<0 ? FString(TEXT("SectionName")) : FString::Printf(TEXT("LabelList[%i]"),Index);
    const TCHAR* Text=Localize(Provider->GetName(),*Key,Provider->GetOuter()->GetName(),NULL,1);
    UStrProperty* Type=FindField<UStrProperty>(UUTExtraKeyBindings::StaticClass(),Index<0 ? TEXT("SectionName") : TEXT("LabelList"));
    if(*Text && Type) Type->ImportText(Text,(BYTE*)&Value,0);
    return Value;
}

UBOOL AndroidExtraBindingsExec(const TCHAR* Cmd,FOutputDevice& Ar,UGameEngine* Engine)
{
    const TCHAR* Add=Cmd;
    if(ParseCommand(&Add,TEXT("ANDROID_MOD_KEY_ADD")))
    {
        TCHAR WindowName[256],LabelName[256],ButtonName[256],ClassName[256];
        if(!ParseToken(Add,WindowName,ARRAY_COUNT(WindowName),0)
        || !ParseToken(Add,LabelName,ARRAY_COUNT(LabelName),0)
        || !ParseToken(Add,ButtonName,ARRAY_COUNT(ButtonName),0)
        || !ParseToken(Add,ClassName,ARRAY_COUNT(ClassName),0)) return 1;
        INT Index=appAtoi(Add);
        if(Index<0 || Index>=30) return 1;
        UClass* Provider=UObject::StaticLoadClass(UUTExtraKeyBindings::StaticClass(),NULL,ClassName,NULL,LOAD_NoWarn,NULL);
        UClass* KeysClass=UObject::StaticLoadClass(UObject::StaticClass(),NULL,TEXT("UMenu.UMenuCustomizeClientWindow"),NULL,LOAD_NoWarn,NULL);
        UObject* Window=KeysClass ? UObject::StaticFindObject(KeysClass,ANY_PACKAGE,WindowName) : NULL;
        if(!Provider || !Window) return 1;
        UUTExtraKeyBindings* Data=(UUTExtraKeyBindings*)Provider->GetDefaultObject();
        UStrProperty* Aliases=FindField<UStrProperty>(Window->GetClass(),TEXT("AliasNames"));
        UStrProperty* Labels=FindField<UStrProperty>(Window->GetClass(),TEXT("LabelList"));
        UObjectProperty* Names=FindField<UObjectProperty>(Window->GetClass(),TEXT("KeyNames"));
        UObjectProperty* Buttons=FindField<UObjectProperty>(Window->GetClass(),TEXT("KeyButtons"));
        UIntProperty* Count=FindField<UIntProperty>(Window->GetClass(),TEXT("AliasCount"));
        if(!Aliases || !Labels || !Names || !Buttons || !Count || !Data->AliasNames[Index].Len()) return 1;
        INT& Num=*(INT*)((BYTE*)Window+Count->Offset);
        if(Num<0 || Num>=Aliases->ArrayDim || Num>=Labels->ArrayDim || Num>=Names->ArrayDim || Num>=Buttons->ArrayDim) return 1;
        for(INT i=0; i<Num; i++)
            if(appStricmp(**(FString*)((BYTE*)Window+Aliases->Offset+i*Aliases->ElementSize),*Data->AliasNames[Index])==0)
            { Ar.Logf(TEXT("%i"),-i-1); return 1; }
        UObject* Label=UObject::StaticFindObject(Names->PropertyClass,ANY_PACKAGE,LabelName);
        UObject* Button=UObject::StaticFindObject(Buttons->PropertyClass,ANY_PACKAGE,ButtonName);
        if(!Label || !Button) return 1;
        UObjectProperty* LabelParent=FindField<UObjectProperty>(Label->GetClass(),TEXT("ParentWindow"));
        UObjectProperty* ButtonParent=FindField<UObjectProperty>(Button->GetClass(),TEXT("ParentWindow"));
        if(!LabelParent || !ButtonParent
        || *(UObject**)((BYTE*)Label+LabelParent->Offset)!=Window
        || *(UObject**)((BYTE*)Button+ButtonParent->Offset)!=Window) return 1;
        *(FString*)((BYTE*)Window+Aliases->Offset+Num*Aliases->ElementSize)=Data->AliasNames[Index];
        *(FString*)((BYTE*)Window+Labels->Offset+Num*Labels->ElementSize)=ExtraBindingText(Provider,Data,-1)+TEXT(" / ")+ExtraBindingText(Provider,Data,Index);
        *(UObject**)((BYTE*)Window+Names->Offset+Num*Names->ElementSize)=Label;
        *(UObject**)((BYTE*)Window+Buttons->Offset+Num*Buttons->ElementSize)=Button;
        Num++;
        Ar.Logf(TEXT("%i"),Num);
        return 1;
    }
    const TCHAR* Sync=Cmd;
    if(ParseCommand(&Sync,TEXT("ANDROID_MOD_KEYS_SYNC")))
    {
        TCHAR Name[256]=TEXT("");
        if(!ParseToken(Sync,Name,ARRAY_COUNT(Name),0)) return 1;
        INT First=appAtoi(Sync);
        UClass* KeysClass=UObject::StaticLoadClass(UObject::StaticClass(),NULL,TEXT("UMenu.UMenuCustomizeClientWindow"),NULL,LOAD_NoWarn,NULL);
        UObject* Window=KeysClass ? UObject::StaticFindObject(KeysClass,ANY_PACKAGE,Name) : NULL;
        if(!Window || !Engine->Client || !Engine->Client->Viewports.Num()) return 1;
        UInput* Input=Engine->Client->Viewports(0)->Input;
        UIntProperty* One=FindField<UIntProperty>(Window->GetClass(),TEXT("BoundKey1"));
        UIntProperty* Two=FindField<UIntProperty>(Window->GetClass(),TEXT("BoundKey2"));
        UIntProperty* Count=FindField<UIntProperty>(Window->GetClass(),TEXT("AliasCount"));
        UStrProperty* Aliases=FindField<UStrProperty>(Window->GetClass(),TEXT("AliasNames"));
        if(!Input || !One || !Two || !Count || !Aliases) return 1;
        INT Num=*(INT*)((BYTE*)Window+Count->Offset);
        if(First<0 || Num>One->ArrayDim || Num>Two->ArrayDim || Num>Aliases->ArrayDim) return 1;
        for(INT i=First; i<Num; i++)
        {
            INT* A=(INT*)((BYTE*)Window+One->Offset+i*One->ElementSize);
            INT* B=(INT*)((BYTE*)Window+Two->Offset+i*Two->ElementSize);
            const FString& Alias=*(FString*)((BYTE*)Window+Aliases->Offset+i*Aliases->ElementSize);
            *A=*B=0;
            for(INT Key=1; Key<Min<INT>(255,IK_MAX); Key++)
                if(Alias.Len() && appStricmp(*Input->Bindings[Key],*Alias)==0)
                {
                    if(!*A) *A=Key;
                    else if(!*B) *B=Key;
                }
        }
        return 1;
    }
    if(!ParseCommand(&Cmd,TEXT("ANDROID_EXTRA_BINDING"))) return 0;
    TCHAR Name[256]=TEXT("");
    if(!ParseToken(Cmd,Name,ARRAY_COUNT(Name),0)) return 1;
    INT Index=appAtoi(Cmd);
    if(Index<0 || Index>=30) return 1;
    UClass* C=UObject::StaticLoadClass(UUTExtraKeyBindings::StaticClass(),NULL,Name,NULL,LOAD_NoWarn,NULL);
    if(C && C->IsChildOf(UUTExtraKeyBindings::StaticClass()))
    {
        UUTExtraKeyBindings* Data=(UUTExtraKeyBindings*)C->GetDefaultObject();
        if(Data->LabelList[Index].Len() && Data->AliasNames[Index].Len())
            Ar.Logf(TEXT("%s\t%s\t%s"),*ExtraBindingText(C,Data,-1),*ExtraBindingText(C,Data,Index),*Data->AliasNames[Index]);
    }
    return 1;
}
#endif
