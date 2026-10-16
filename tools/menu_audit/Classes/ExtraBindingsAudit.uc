class ExtraBindingsAudit extends Mutator;
var int Step;
var string OriginalKey;
var UMenuOptionsWindow Options;
var int OriginalCount;
function PostBeginPlay() { SetTimer(0.5,True); }
function Timer()
{
 local PlayerPawn P;
 local WindowConsole C;
 local UT99ConsoleRoot R;
 local UT99ConsoleDialog D;
 local string Value;
 local int Padding;
 foreach AllActors(class'PlayerPawn',P)
  if(P.Player != None)
  {
   C=WindowConsole(P.Player.Console);
   if(C == None) return;
   if(C.Root == None) { C.LaunchUWindow(); return; }
   R=UT99ConsoleRoot(C.Root);
   if(R == None) return;
   if(Step == 0)
   {
    Value=P.ConsoleCommand("ANDROID_EXTRA_BINDING RelicsBindings.ExtraRelicsBindings 0");
    if(InStr(Caps(Value),"MUTATE TOSSRELIC")<0) Log("EXTRA_BINDINGS FAIL metadata=" $ Value);
    else Log("EXTRA_BINDINGS PASS metadata=" $ Value);
    Log("EXTRA_BINDINGS registry=" $ P.GetNextInt("UTMenu.UTExtraKeyBindings",0));
    C.LaunchUWindow();
    Options=UMenuOptionsWindow(R.CreateWindow(class'UMenuOptionsWindow',0,0,300,300));
    Step=1; return;
   }
   D=R.DialogScreen;
   if(D == None) return;
   if(Step == 1)
   {
    D.Row=3; D.ActivateRow();
    Step=2; return;
   }
   if(Step == 2)
   {
    D.Row=D.Count-2; D.FirstRow=Max(0,D.Row-4);
    Log("EXTRA_BINDINGS row=" $ D.Caption(D.Row) $ " extra=" $ D.ExtraKeys $ " count=" $ D.Count);
    OriginalCount=D.Count;
    OriginalKey=P.ConsoleCommand("KEYBINDING J");
    D.ActivateRow(); D.HotKeyDown(0x4A,0,0);
    Value=P.ConsoleCommand("KEYBINDING J");
    if(Value ~= "mutate tossrelic") Log("EXTRA_BINDINGS PASS binding=" $ Value);
    else Log("EXTRA_BINDINGS FAIL binding=" $ Value);
    D.Finish();
    Options.Close();
    Options=UMenuOptionsWindow(R.CreateWindow(class'UMenuOptionsWindow',0,0,300,300));
    Step=3; return;
   }
   if(Step == 3)
   {
    D.Row=3; D.ActivateRow(); Step=4; return;
   }
   if(Step == 4)
   {
    D.Row=D.Count-2; D.FirstRow=Max(0,D.Row-4);
    Value=D.Caption(D.Row);
    if(D.Count == OriginalCount && InStr(Value," : J")>=0)
     Log("EXTRA_BINDINGS PASS reopen=" $ Value);
    else Log("EXTRA_BINDINGS FAIL reopen=" $ Value $ " count=" $ D.Count);
    Step=5; SetTimer(10,True); return;
   }
   P.ConsoleCommand("SET Input J "$OriginalKey);
   D.RefreshExtraBindings();
   Log("EXTRA_BINDINGS restored temporary J binding");
   for(Padding=0; Padding<100; Padding++) Log("EXTRA_BINDINGS flush log padding 012345678901234567890123456789012345678901234567890123456789");
   SetTimer(0,False); return;
  }
}
defaultproperties
{
 bAlwaysTick=True
 bHidden=True
 RemoteRole=ROLE_None
}