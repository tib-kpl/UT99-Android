/*=============================================================================
	UnCon.cpp: Implementation of UConsole class
	Copyright 1997-1999 Epic Games, Inc. All Rights Reserved.
=============================================================================*/

#include "EnginePrivate.h"
#if defined(PLATFORM_ANDROID)
#include "UnNativeLayoutMacros.h"
void UConsole::StaticConstructor()
{
    typedef UConsole FLayoutClass;
    BYTE Before[sizeof(FLayoutClass)];
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("AvgText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,AvgText),sizeof(AvgText),0,UT99NativeFieldCapacity(AvgText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("Border"),TEXT("ObjectProperty"),STRUCT_OFFSET(FLayoutClass,Border),sizeof(Border),0,UT99NativeFieldCapacity(Border));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("BorderLines"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,BorderLines),sizeof(BorderLines),0,UT99NativeFieldCapacity(BorderLines));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("BorderPixels"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,BorderPixels),sizeof(BorderPixels),0,UT99NativeFieldCapacity(BorderPixels));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("BorderSize"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,BorderSize),sizeof(BorderSize),0,UT99NativeFieldCapacity(BorderSize));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ConBackground"),TEXT("ObjectProperty"),STRUCT_OFFSET(FLayoutClass,ConBackground),sizeof(ConBackground),0,UT99NativeFieldCapacity(ConBackground));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ConnectingMessage"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,ConnectingMessage),sizeof(ConnectingMessage),0,UT99NativeFieldCapacity(ConnectingMessage));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ConsoleDest"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,ConsoleDest),sizeof(ConsoleDest),0,UT99NativeFieldCapacity(ConsoleDest));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ConsoleLines"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,ConsoleLines),sizeof(ConsoleLines),0,UT99NativeFieldCapacity(ConsoleLines));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ConsolePos"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,ConsolePos),sizeof(ConsolePos),0,UT99NativeFieldCapacity(ConsolePos));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("ExtraTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,ExtraTime),sizeof(ExtraTime),0,UT99NativeFieldCapacity(ExtraTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("FrameCount"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,FrameCount),sizeof(FrameCount),0,UT99NativeFieldCapacity(FrameCount));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("FrameRateText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,FrameRateText),sizeof(FrameRateText),0,UT99NativeFieldCapacity(FrameRateText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("FrameX"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,FrameX),sizeof(FrameX),0,UT99NativeFieldCapacity(FrameX));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("FrameY"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,FrameY),sizeof(FrameY),0,UT99NativeFieldCapacity(FrameY));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("FramesText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,FramesText),sizeof(FramesText),0,UT99NativeFieldCapacity(FramesText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("History"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,History),sizeof(History),0,UT99NativeFieldCapacity(History));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("HistoryBot"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,HistoryBot),sizeof(HistoryBot),0,UT99NativeFieldCapacity(HistoryBot));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("HistoryCur"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,HistoryCur),sizeof(HistoryCur),0,UT99NativeFieldCapacity(HistoryCur));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("HistoryTop"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,HistoryTop),sizeof(HistoryTop),0,UT99NativeFieldCapacity(HistoryTop));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LastFrameTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,LastFrameTime),sizeof(LastFrameTime),0,UT99NativeFieldCapacity(LastFrameTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LastSecFPS"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,LastSecFPS),sizeof(LastSecFPS),0,UT99NativeFieldCapacity(LastSecFPS));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LastSecText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,LastSecText),sizeof(LastSecText),0,UT99NativeFieldCapacity(LastSecText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LastSecondFrameCount"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,LastSecondFrameCount),sizeof(LastSecondFrameCount),0,UT99NativeFieldCapacity(LastSecondFrameCount));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LastSecondStartTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,LastSecondStartTime),sizeof(LastSecondStartTime),0,UT99NativeFieldCapacity(LastSecondStartTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("LoadingMessage"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,LoadingMessage),sizeof(LoadingMessage),0,UT99NativeFieldCapacity(LoadingMessage));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MaxFPS"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,MaxFPS),sizeof(MaxFPS),0,UT99NativeFieldCapacity(MaxFPS));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MaxText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,MaxText),sizeof(MaxText),0,UT99NativeFieldCapacity(MaxText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MinFPS"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,MinFPS),sizeof(MinFPS),0,UT99NativeFieldCapacity(MinFPS));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MinText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,MinText),sizeof(MinText),0,UT99NativeFieldCapacity(MinText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgPlayer"),TEXT("ObjectProperty"),STRUCT_OFFSET(FLayoutClass,MsgPlayer),sizeof(MsgPlayer),0,UT99NativeFieldCapacity(MsgPlayer));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,MsgText),sizeof(MsgText),0,UT99NativeFieldCapacity(MsgText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgTick"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,MsgTick),sizeof(MsgTick),0,UT99NativeFieldCapacity(MsgTick));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgTickTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,MsgTickTime),sizeof(MsgTickTime),0,UT99NativeFieldCapacity(MsgTickTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,MsgTime),sizeof(MsgTime),0,UT99NativeFieldCapacity(MsgTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("MsgType"),TEXT("NameProperty"),STRUCT_OFFSET(FLayoutClass,MsgType),sizeof(MsgType),0,UT99NativeFieldCapacity(MsgType));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("PausedMessage"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,PausedMessage),sizeof(PausedMessage),0,UT99NativeFieldCapacity(PausedMessage));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("PrecachingMessage"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,PrecachingMessage),sizeof(PrecachingMessage),0,UT99NativeFieldCapacity(PrecachingMessage));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("SavingMessage"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,SavingMessage),sizeof(SavingMessage),0,UT99NativeFieldCapacity(SavingMessage));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("Scrollback"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,Scrollback),sizeof(Scrollback),0,UT99NativeFieldCapacity(Scrollback));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("SecondsText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,SecondsText),sizeof(SecondsText),0,UT99NativeFieldCapacity(SecondsText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("StartTime"),TEXT("FloatProperty"),STRUCT_OFFSET(FLayoutClass,StartTime),sizeof(StartTime),0,UT99NativeFieldCapacity(StartTime));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("TextLines"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,TextLines),sizeof(TextLines),0,UT99NativeFieldCapacity(TextLines));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("TimeDemoFont"),TEXT("ObjectProperty"),STRUCT_OFFSET(FLayoutClass,Font),sizeof(Font),0,UT99NativeFieldCapacity(Font));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("TopLine"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,TopLine),sizeof(TopLine),0,UT99NativeFieldCapacity(TopLine));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("TypeCursorOffset"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,TypeCursorOffset),sizeof(TypeCursorOffset),0,UT99NativeFieldCapacity(TypeCursorOffset));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("TypedStr"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,TypedStr),sizeof(TypedStr),0,UT99NativeFieldCapacity(TypedStr));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("Viewport"),TEXT("ObjectProperty"),STRUCT_OFFSET(FLayoutClass,Viewport),sizeof(Viewport),0,UT99NativeFieldCapacity(Viewport));
    UT99_LAYOUT_BOOL(bControlDown)
    UT99_LAYOUT_BOOL(bNoDrawWorld)
    UT99_LAYOUT_BOOL(bNoStuff)
    UT99_LAYOUT_BOOL(bRestartTimeDemo)
    UT99_LAYOUT_BOOL(bSaveTimeDemoToFile)
    UT99_LAYOUT_BOOL(bStartTimeDemo)
    UT99_LAYOUT_BOOL(bTimeDemo)
    UT99_LAYOUT_BOOL(bTyping)
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("fpsText"),TEXT("StrProperty"),STRUCT_OFFSET(FLayoutClass,fpsText),sizeof(fpsText),0,UT99NativeFieldCapacity(fpsText));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("numLines"),TEXT("IntProperty"),STRUCT_OFFSET(FLayoutClass,numLines),sizeof(numLines),0,UT99NativeFieldCapacity(numLines));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("vtblOut"),TEXT("IntProperty"),(BYTE*)(FOutputDevice*)this-(BYTE*)this,sizeof(void*));
    UT99RegisterNativeFieldLayout(GetClass(),TEXT("vtblOut"),TEXT("PointerProperty"),(BYTE*)(FOutputDevice*)this-(BYTE*)this,sizeof(void*));
}
#undef UT99_LAYOUT_BOOL
#undef UT99_LAYOUT_FIELD
#endif


#include "UnRender.h"

/*------------------------------------------------------------------------------
	UConsole object implementation.
------------------------------------------------------------------------------*/

IMPLEMENT_CLASS(UConsole);

/*------------------------------------------------------------------------------
	Console.
------------------------------------------------------------------------------*/

//
// Constructor.
//
UConsole::UConsole()
{}

//
// Init console.
//
void UConsole::_Init( UViewport* InViewport )
{
	guard(UConsole::_Init);
	VERIFY_CLASS_SIZE(UConsole);

	// Set properties.
	Viewport		= InViewport;
	TopLine			= MAX_LINES-1;
	BorderSize		= 1; 

	// Init scripting.
	InitExecution();

	// Start console log.
	Logf(LocalizeGeneral("Engine",TEXT("Core")));
	Logf(LocalizeGeneral("Copyright",TEXT("Core")));
	Logf(TEXT(" "));
	Logf(TEXT(" "));

	unguard;
}

/*------------------------------------------------------------------------------
	Viewport console output.
------------------------------------------------------------------------------*/

//
// Print a message on the playing screen.
// Time = time to keep message going, or 0=until next message arrives, in 60ths sec
//
void UConsole::Serialize( const TCHAR* Data, EName ThisType )
{
	guard(UConsole::Serialize);
	eventMessage( 0, Data, 0, ThisType );
	unguard;
}

void UConsole::execConsoleCommand( FFrame& Stack, RESULT_DECL )
{
	guardSlow(UConsole::execConsoleCommand);

	P_GET_STR(S);
	P_FINISH;

	*(DWORD*)Result = Viewport->Exec( *S, *this );

	unguardexecSlow;
}
IMPLEMENT_FUNCTION( UConsole, INDEX_NONE, execConsoleCommand );

void UConsole::execSaveTimeDemo( FFrame& Stack, RESULT_DECL )
{
	guard(UConsole::execSaveTimeDemo);
	P_GET_STR(S);
	P_FINISH;
	appSaveStringToFile( S, TEXT("fps.txt"), GFileManager );
	unguardexec;
}
IMPLEMENT_FUNCTION( UConsole, INDEX_NONE, execSaveTimeDemo );

/*------------------------------------------------------------------------------
	Rendering.
------------------------------------------------------------------------------*/

UBOOL UConsole::GetDrawWorld()
{
	guard(UConsole::GetDrawWorld);

	return !bNoDrawWorld;
	unguard;
}

//
// Called before rendering the world view.  Here, the
// Viewport console code can affect the screen's Viewport,
// for example by shrinking the view according to the
// size of the status bar.
//
FSceneNode SavedFrame;
void UConsole::PreRender( FSceneNode* Frame )
{
	guard(UConsole::PreRender);

	// Prevent status redraw due to changing.
	eventTick( Viewport->CurrentTime - Viewport->LastUpdateTime );

	// Save the Viewport.
	SavedFrame = *Frame;

	// Compute new status info.
	BorderLines		= 0;
	BorderPixels	= 0;
	ConsoleLines	= 0;

	// Compute sizing of all visible status bar components.
	if( ConsolePos > 0.0 )
	{
		// Show console.
		ConsoleLines = (INT) Min(ConsolePos * (FLOAT)Frame->Y, (FLOAT)Frame->Y);
	}

	if( BorderSize>=2 )
	{
		// Encroach on screen area.
		FLOAT Fraction = (FLOAT)(BorderSize-1) / (FLOAT)(MAX_BORDER-1);

		BorderLines = (int)Min((FLOAT)Frame->Y * 0.25f * Fraction,(FLOAT)Frame->Y);
		BorderLines = ::Max<INT>(0,BorderLines);
		Frame->Y -= 2 * BorderLines;

		BorderPixels = (int)Min((FLOAT)Frame->X * 0.25f * Fraction,(FLOAT)Frame->X) & ~3;
		Frame->X -= 2 * BorderPixels;
	}

	Frame->XB += BorderPixels;
	Frame->YB += BorderLines;
	Frame->ComputeRenderSize();

	unguard;
}

//
// Refresh the player console on the specified Viewport.  This is called after
// all in-game graphics are drawn in the rendering loop, and it overdraws stuff
// with the status bar, menus, and chat text.
//
void UConsole::PostRender( FSceneNode* Frame )
{
	guard(UConsole::PostRender);
	
	*Frame = SavedFrame;
	FrameX = Frame->X;
	FrameY = Frame->Y;

	unguard;
}

/*------------------------------------------------------------------------------
	The End.
------------------------------------------------------------------------------*/
