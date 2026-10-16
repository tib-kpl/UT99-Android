/* Narrow additions to the v400 script API. No on-disk package is changed.
 * RF_Native keeps synthetic imports valid across EndLoad: they have no export
 * index from which a cleared linker import could be reconstructed. It does not
 * make a script function native (that is controlled by FUNC_Native). */
#pragma once
#if defined(PLATFORM_ANDROID)
namespace LegacyScriptCompat
{
enum EType { Object, Class, Bool, Byte, Int, Float, Name, String, Vector };
struct FParam { const TCHAR* Name; EType Type; const TCHAR* ClassName; DWORD Flags; };

static UProperty* Property(UStruct* Owner, const FParam& Param)
{
	UProperty* P = NULL;
	switch(Param.Type)
	{
	case Object: case Class:
	{
		UClass* Type = FindObject<UClass>(ANY_PACKAGE,Param.ClassName);
		check(Type);
		if(Param.Type==Class)
		{
			UClassProperty* C = new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UClassProperty;
			C->PropertyClass=UClass::StaticClass(); C->MetaClass=Type; P=C;
		}
		else
		{
			UObjectProperty* O = new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UObjectProperty;
			O->PropertyClass=Type; P=O;
		}
		break;
	}
	case Bool: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UBoolProperty; break;
	case Byte: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UByteProperty; break;
	case Int: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UIntProperty; break;
	case Float: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UFloatProperty; break;
	case Name: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UNameProperty; break;
	case String: P=new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UStrProperty; break;
	case Vector:
	{
		UStructProperty* S = new(Owner,Param.Name,RF_Public|RF_Native|RF_Transient)UStructProperty;
		S->Struct=FindObject<UStruct>(ANY_PACKAGE,TEXT("Vector")); check(S->Struct); P=S;
		break;
	}
	}
	P->PropertyFlags=Param.Flags;
	return P;
}

static void EmitRef(TArray<BYTE>& Code, BYTE Op, UObject* Object)
{
	Code.AddItem(Op);
	INT Index=Object->GetIndex(), Offset=Code.Add(sizeof(Index));
	appMemcpy(&Code(Offset),&Index,sizeof(Index));
}

// ReturnKind: -1=void, 0=false, 1=true. Chain=NULL gives an empty base event.
static void Function(UStruct* Owner, FArchive& Ar, UField**& Tail,
	const TCHAR* Name, const TCHAR* Chain, INT ReturnKind,
	const FParam* Params=NULL, INT Count=0, DWORD Flags=FUNC_Defined, EType ReturnType=Bool, INT NativeIndex=0)
{
	if(FindObject<UFunction>(Owner,Name)) return;
	UFunction* F=new(Owner,Name,RF_Public|RF_Native|RF_Transient)UFunction(NULL);
	F->FunctionFlags=Flags;
	F->iNative=NativeIndex;
	UField** ParamTail=&F->Children;
	for(INT i=0;i<Count;i++)
	{
		*ParamTail=Property(F,Params[i]); ParamTail=&(*ParamTail)->Next;
	}
	UProperty* Return=NULL;
	if(ReturnKind>=0)
	{
		FParam Result={TEXT("ReturnValue"),ReturnType,NULL,CPF_Parm|CPF_OutParm|CPF_ReturnParm};
		Return=Property(F,Result); *ParamTail=Return;
	}
	F->Link(Ar,1);
	F->NumParms=Count+(Return!=NULL);
	F->ParmsSize=F->PropertiesSize;
	F->ReturnValueOffset=Return ? Return->Offset : MAXWORD;
	if(!(Flags&FUNC_Native))
	{
		TArray<BYTE>& Code=F->Script;
		if(Chain)
		{
			UProperty* Next=FindObject<UProperty>(Owner,Chain); check(Next);
			Code.AddItem(EX_JumpIfNot); Code.AddZeroed(2);
			Code.AddItem(EX_ObjectToBool); EmitRef(Code,EX_InstanceVariable,Next);
			if(Return) Code.AddItem(EX_Return);
			Code.AddItem(EX_Context); EmitRef(Code,EX_InstanceVariable,Next);
			INT Skip=Code.AddZeroed(2); Code.AddItem(Return ? sizeof(UBOOL) : 0);
			Code.AddItem(EX_VirtualFunction);
			FName FunctionName(Name);
			INT Offset=Code.Add(sizeof(FName)); appMemcpy(&Code(Offset),&FunctionName,sizeof(FName));
			UField* Param=F->Children;
			for(INT i=0;i<Count;i++,Param=Param->Next)
			{
				if(Params[i].Type==Bool) Code.AddItem(EX_BoolVariable);
				EmitRef(Code,EX_LocalVariable,Param);
			}
			Code.AddItem(EX_EndFunctionParms);
			_WORD SkipSize=Code.Num()-Skip-3, FalseOffset=Code.Num();
			appMemcpy(&Code(Skip),&SkipSize,2); appMemcpy(&Code(1),&FalseOffset,2);
		}
		Code.AddItem(EX_Return); Code.AddItem(Return ? (ReturnKind ? EX_True : EX_False) : EX_Nothing);
	}
	F->Bind(); *Tail=F; Tail=&F->Next;
}

static void Extend(UStruct* Owner, FArchive& Ar, UBOOL Props)
{
	if(!Props || !Ar.IsLoading() || Ar.Ver()!=68 || !Owner->GetOuter()
	) return;
	// Later scripts test SetPropertyText's boolean result. The v400 native
	// function has the same inputs but no return property. Add only that
	// result slot; callers compiled against the old void API still ignore it.
	if(Owner->IsA(UFunction::StaticClass())
	&& !appStricmp(Owner->GetName(),TEXT("SetPropertyText"))
	&& Owner->GetOuter()==UObject::StaticClass())
	{
		UField** Tail=&Owner->Children;
		while(*Tail)
		{
			Ar.Preload(*Tail);
			UProperty* P=Cast<UProperty>(*Tail);
			if(P && (P->PropertyFlags&CPF_ReturnParm)) return;
			Tail=&(*Tail)->Next;
		}
		FParam Result={TEXT("ReturnValue"),Bool,NULL,CPF_Parm|CPF_OutParm|CPF_ReturnParm};
		*Tail=Property(Owner,Result);
		return;
	}
    if(Owner==UObject::StaticClass())
    {
        UField** Tail=&Owner->Children;
        while(*Tail) { Ar.Preload(*Tail); Tail=&(*Tail)->Next; }
        const DWORD StaticNative=FUNC_Native|FUNC_Static|FUNC_Final;
        FParam Text[]={{TEXT("S"),String,NULL,CPF_Parm|CPF_CoerceParm}};
        Function(Owner,Ar,Tail,TEXT("Locs"),NULL,0,Text,ARRAY_COUNT(Text),StaticNative,String,238);
        FParam Replace[]={{TEXT("Src"),String,NULL,CPF_Parm|CPF_CoerceParm},
            {TEXT("Match"),String,NULL,CPF_Parm|CPF_CoerceParm},
            {TEXT("With"),String,NULL,CPF_Parm|CPF_CoerceParm},
            {TEXT("bCaseSensitive"),Bool,NULL,CPF_Parm|CPF_OptionalParm}};
        Function(Owner,Ar,Tail,TEXT("Repl"),NULL,0,Replace,ARRAY_COUNT(Replace),StaticNative,String,239);
        FParam Prop[]={{TEXT("PropName"),String,NULL,CPF_Parm|CPF_OptionalParm}};
        Function(Owner,Ar,Tail,TEXT("ClearConfig"),NULL,-1,Prop,ARRAY_COUNT(Prop),FUNC_Native|FUNC_Final,Bool,537);
        Function(Owner,Ar,Tail,TEXT("StaticClearConfig"),NULL,-1,Prop,ARRAY_COUNT(Prop),StaticNative);
        FParam Default[]={{TEXT("PropValue"),String,NULL,CPF_Parm|CPF_OutParm},
            {TEXT("Obj"),Object,TEXT("Object"),CPF_Parm},
            {TEXT("PropName"),String,NULL,CPF_Parm},
            {TEXT("ArrayIndex"),Int,NULL,CPF_Parm|CPF_OptionalParm}};
        Function(Owner,Ar,Tail,TEXT("GetDefaultValue"),NULL,0,Default,ARRAY_COUNT(Default),StaticNative);
        FParam Trace[]={{TEXT("bNewUTracing"),Bool,NULL,CPF_Parm}};
        Function(Owner,Ar,Tail,TEXT("SetUTracing"),NULL,-1,Trace,ARRAY_COUNT(Trace),StaticNative);
        Function(Owner,Ar,Tail,TEXT("IsUTracing"),NULL,0,NULL,0,StaticNative);
        return;
    }
	if(!appStricmp(Owner->GetOuter()->GetName(),TEXT("Botpack"))
	&& !appStricmp(Owner->GetName(),TEXT("ChallengeHUD")))
	{
		UField** Tail=&Owner->Children;
		while(*Tail) { Ar.Preload(*Tail); Tail=&(*Tail)->Next; }
		FParam Fields[]={{TEXT("FaceTexture"),Object,TEXT("Texture"),0},
			{TEXT("FaceTime"),Float,NULL,0},{TEXT("FontInfoClass"),String,NULL,CPF_Config|CPF_GlobalConfig}};
		for(INT i=0;i<ARRAY_COUNT(Fields);i++)
			if(!FindObject<UProperty>(Owner,Fields[i].Name))
			{ *Tail=Property(Owner,Fields[i]); Tail=&(*Tail)->Next; }
		if(!FindObject<UProperty>(Owner,TEXT("FaceTeam")))
		{
			UStructProperty* P=new(Owner,TEXT("FaceTeam"),RF_Public|RF_Native|RF_Transient)UStructProperty;
			P->Struct=FindObject<UStruct>(ANY_PACKAGE,TEXT("Color")); check(P->Struct); *Tail=P;
		}
		return;
	}
	if(appStricmp(Owner->GetOuter()->GetName(),TEXT("Engine"))) return;
	const TCHAR* Type=Owner->GetName();
	if(appStricmp(Type,TEXT("Mutator")) && appStricmp(Type,TEXT("Actor"))
	&& appStricmp(Type,TEXT("HUD")) && appStricmp(Type,TEXT("PlayerPawn"))) return;
	UField** Tail=&Owner->Children;
	while(*Tail) { Ar.Preload(*Tail); Tail=&(*Tail)->Next; }
	if(!appStricmp(Type,TEXT("Actor")))
	{
		Function(Owner,Ar,Tail,TEXT("PostNetBeginPlay"),NULL,-1,NULL,0,FUNC_Event|FUNC_Simulated);
		return;
	}
	if(!appStricmp(Type,TEXT("PlayerPawn")))
	{
		if(!FindObject<UProperty>(Owner,TEXT("LastMessageWindow")))
		{
			FParam P={TEXT("LastMessageWindow"),Float,NULL,0}; *Tail=Property(Owner,P);
		}
		return;
	}
	if(!appStricmp(Type,TEXT("HUD")))
	{
		FParam Keys[]={{TEXT("Key"),Int,NULL,CPF_Parm},{TEXT("Action"),Int,NULL,CPF_Parm},{TEXT("Delta"),Float,NULL,CPF_Parm}};
		Function(Owner,Ar,Tail,TEXT("ProcessKeyEvent"),NULL,0,Keys,ARRAY_COUNT(Keys));
		return;
	}
	FParam Fields[]={{TEXT("NextHUDMutator"),Object,TEXT("Mutator"),0},
		{TEXT("bHUDMutator"),Bool,NULL,0},{TEXT("NextMessageMutator"),Object,TEXT("Mutator"),0}};
	for(INT i=0;i<ARRAY_COUNT(Fields);i++)
		if(!FindObject<UProperty>(Owner,Fields[i].Name))
		{ *Tail=Property(Owner,Fields[i]); Tail=&(*Tail)->Next; }
	Function(Owner,Ar,Tail,TEXT("HandleEndGame"),TEXT("NextMutator"),0);
	Function(Owner,Ar,Tail,TEXT("HandleRestartGame"),TEXT("NextMutator"),0);
	FParam Pickup[]={{TEXT("Other"),Object,TEXT("Pawn"),CPF_Parm},{TEXT("item"),Object,TEXT("Inventory"),CPF_Parm},
		{TEXT("bAllowPickup"),Byte,NULL,CPF_Parm|CPF_OutParm}};
	Function(Owner,Ar,Tail,TEXT("HandlePickupQuery"),TEXT("NextMutator"),0,Pickup,ARRAY_COUNT(Pickup));
	FParam Pause[]={{TEXT("Other"),Object,TEXT("PlayerPawn"),CPF_Parm}};
	Function(Owner,Ar,Tail,TEXT("HandlePauseRequest"),TEXT("NextMutator"),0,Pause,ARRAY_COUNT(Pause));
	FParam Death[]={{TEXT("Killed"),Object,TEXT("Pawn"),CPF_Parm},{TEXT("Killer"),Object,TEXT("Pawn"),CPF_Parm},
		{TEXT("damageType"),Name,NULL,CPF_Parm},{TEXT("HitLocation"),Vector,NULL,CPF_Parm}};
	Function(Owner,Ar,Tail,TEXT("PreventDeath"),TEXT("NextMutator"),0,Death,ARRAY_COUNT(Death));
	FParam Login[]={{TEXT("SpawnClass"),Class,TEXT("PlayerPawn"),CPF_Parm|CPF_OutParm},
		{TEXT("Portal"),String,NULL,CPF_Parm|CPF_OutParm},{TEXT("Options"),String,NULL,CPF_Parm|CPF_OutParm}};
	Function(Owner,Ar,Tail,TEXT("ModifyLogin"),TEXT("NextMutator"),-1,Login,ARRAY_COUNT(Login));
	FParam Team[]={{TEXT("Sender"),Object,TEXT("Actor"),CPF_Parm},{TEXT("Receiver"),Object,TEXT("Pawn"),CPF_Parm},
		{TEXT("PRI"),Object,TEXT("PlayerReplicationInfo"),CPF_Parm},{TEXT("S"),String,NULL,CPF_Parm|CPF_CoerceParm},
		{TEXT("Type"),Name,NULL,CPF_Parm},{TEXT("bBeep"),Bool,NULL,CPF_Parm|CPF_OptionalParm}};
	Function(Owner,Ar,Tail,TEXT("MutatorTeamMessage"),TEXT("NextMessageMutator"),1,Team,ARRAY_COUNT(Team));
	FParam Broadcast[]={{TEXT("Sender"),Object,TEXT("Actor"),CPF_Parm},{TEXT("Receiver"),Object,TEXT("Pawn"),CPF_Parm},
		{TEXT("Msg"),String,NULL,CPF_Parm|CPF_OutParm|CPF_CoerceParm},
		{TEXT("bBeep"),Bool,NULL,CPF_Parm|CPF_OptionalParm},{TEXT("Type"),Name,NULL,CPF_Parm|CPF_OutParm|CPF_OptionalParm}};
	Function(Owner,Ar,Tail,TEXT("MutatorBroadcastMessage"),TEXT("NextMessageMutator"),1,Broadcast,ARRAY_COUNT(Broadcast));
	FParam Localized[]={{TEXT("Sender"),Object,TEXT("Actor"),CPF_Parm},{TEXT("Receiver"),Object,TEXT("Pawn"),CPF_Parm},
		{TEXT("Message"),Class,TEXT("LocalMessage"),CPF_Parm|CPF_OutParm},
		{TEXT("Switch"),Int,NULL,CPF_Parm|CPF_OutParm|CPF_OptionalParm},
		{TEXT("RelatedPRI_1"),Object,TEXT("PlayerReplicationInfo"),CPF_Parm|CPF_OutParm|CPF_OptionalParm},
		{TEXT("RelatedPRI_2"),Object,TEXT("PlayerReplicationInfo"),CPF_Parm|CPF_OutParm|CPF_OptionalParm},
		{TEXT("OptionalObject"),Object,TEXT("Object"),CPF_Parm|CPF_OutParm|CPF_OptionalParm}};
	Function(Owner,Ar,Tail,TEXT("MutatorBroadcastLocalizedMessage"),TEXT("NextMessageMutator"),1,Localized,ARRAY_COUNT(Localized));
	Function(Owner,Ar,Tail,TEXT("RegisterHUDMutator"),NULL,-1,NULL,0,FUNC_Native|FUNC_Simulated);
}

static UBOOL Supported(const TCHAR* Owner, FName Type, const TCHAR* Name)
{
	if(!appStricmp(Owner,TEXT("Actor")))
		return Type==NAME_Function && !appStricmp(Name,TEXT("PostNetBeginPlay"));
	if(!appStricmp(Owner,TEXT("HUD")))
		return Type==NAME_Function && !appStricmp(Name,TEXT("ProcessKeyEvent"));
	if(!appStricmp(Owner,TEXT("PlayerPawn")))
		return Type==FName(TEXT("FloatProperty")) && !appStricmp(Name,TEXT("LastMessageWindow"));
	if(appStricmp(Owner,TEXT("Mutator"))) return 0;
	if(Type==FName(TEXT("ObjectProperty")))
		return !appStricmp(Name,TEXT("NextHUDMutator")) || !appStricmp(Name,TEXT("NextMessageMutator"));
	if(Type==FName(TEXT("BoolProperty"))) return !appStricmp(Name,TEXT("bHUDMutator"));
	if(Type!=NAME_Function) return 0;
	const TCHAR* Names[]={TEXT("HandleEndGame"),TEXT("HandleRestartGame"),TEXT("HandlePickupQuery"),
		TEXT("HandlePauseRequest"),TEXT("PreventDeath"),TEXT("ModifyLogin"),TEXT("MutatorTeamMessage"),
		TEXT("MutatorBroadcastMessage"),TEXT("MutatorBroadcastLocalizedMessage"),TEXT("RegisterHUDMutator")};
	for(INT i=0;i<ARRAY_COUNT(Names);i++) if(!appStricmp(Name,Names[i])) return 1;
	return 0;
}

static UBOOL SupportedCore(const TCHAR* Owner, FName Type, const TCHAR* Name)
{
    if(appStricmp(Owner,TEXT("Object")) || Type!=NAME_Function) return 0;
    const TCHAR* Names[]={TEXT("Locs"),TEXT("Repl"),TEXT("ClearConfig"),TEXT("StaticClearConfig"),
        TEXT("GetDefaultValue"),TEXT("SetUTracing"),TEXT("IsUTracing")};
    for(INT i=0;i<ARRAY_COUNT(Names);i++) if(!appStricmp(Name,Names[i])) return 1;
    return 0;
}

static UBOOL SupportedHUD(FName Type, const TCHAR* Name)
{
	return (Type==FName(TEXT("ObjectProperty")) && !appStricmp(Name,TEXT("FaceTexture")))
		|| (Type==FName(TEXT("FloatProperty")) && !appStricmp(Name,TEXT("FaceTime")))
		|| (Type==FName(TEXT("StructProperty")) && !appStricmp(Name,TEXT("FaceTeam")))
		|| (Type==FName(TEXT("StrProperty")) && !appStricmp(Name,TEXT("FontInfoClass")));
}
}
#endif
