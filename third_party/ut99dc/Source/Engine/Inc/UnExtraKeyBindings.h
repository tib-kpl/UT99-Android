#pragma once

#if defined(PLATFORM_ANDROID)
// Data-only bonus-pack metadata, absent from the original v400 UTMenu.
// Kept native/transient so the original UTMenu.u remains unchanged.
class ENGINE_API UUTExtraKeyBindings : public UObject
{
    DECLARE_CLASS(UUTExtraKeyBindings,UObject,0)
public:
    FString SectionName;
    FString LabelList[30];
    FString AliasNames[30];
    UUTExtraKeyBindings() {}
    void StaticConstructor();
};

ENGINE_API UBOOL AndroidExtraBindingsExec(const TCHAR* Cmd,FOutputDevice& Ar,UGameEngine* Engine);
#endif
