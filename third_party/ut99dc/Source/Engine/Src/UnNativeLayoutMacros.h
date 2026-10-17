// Include only around an explicit native field registration block.
#define UT99_LAYOUT_FIELD(Member,Type) UT99RegisterNativeFieldLayout(GetClass(),TEXT(#Member),TEXT(#Type),STRUCT_OFFSET(FLayoutClass,Member),sizeof(Member),0,UT99NativeFieldCapacity(Member));
#define UT99_LAYOUT_BOOL(Member) \
    { \
        UBOOL Previous=Member; \
        appMemcpy(Before,this,sizeof(FLayoutClass)); \
        Member=!Previous; \
        INT Changed=0; DWORD Mask=0; \
        for(INT Byte=sizeof(UObject);Byte<sizeof(FLayoutClass);++Byte) \
            if(Before[Byte]!=((BYTE*)this)[Byte]) { Changed=Byte & ~3; Mask=(DWORD)(Before[Byte]^((BYTE*)this)[Byte])<<((Byte & 3)*8); break; } \
        Member=Previous; \
        check(Mask!=0); \
        UT99RegisterNativeFieldLayout(GetClass(),TEXT(#Member),TEXT("BoolProperty"),Changed,sizeof(DWORD),Mask); \
    }
