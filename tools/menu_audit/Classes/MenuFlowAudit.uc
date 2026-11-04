// Runs against the compiled production menu classes, without starting a match.
class MenuFlowAudit extends Commandlet;
var int Failures;

function Check(bool Passed, string Name)
{
    if(Passed) Log("MENU_FLOW PASS "$Name);
    else { Log("MENU_FLOW FAIL "$Name); Failures++; }
}

event int Main(string Params)
{
    local CampaignFlowFixture Screen;
    local UT99ConsoleRoot R;
    local UTConsole C;
    local int Size, i;
    Screen = new class'CampaignFlowFixture';
    // Exercise the real BuildList with different rosters, including no bots.
    for(Size = 0; Size <= 8; Size++)
    {
        Screen.Roster = new class'EnemyBrowser';
        Screen.Roster.NumNames = Size;
        Screen.Roster.NextButton = new class'NotifyButton';
        Screen.Roster.Title1 = new class'NotifyButton';
        for(i = 0; i < Size; i++) Screen.Roster.Names[i] = new class'LadderButton';
        Screen.Row = 0;
        Screen.BuildList(); Screen.SelectPrimaryAction();
        Check(Screen.ControlAt(Screen.Row) == Screen.Roster.NextButton,
              "enemy start selected, roster size="$Size);
        Check(Screen.Count == Size+3 && Screen.ControlAt(0) != None,
              "roster options retained, size="$Size);
        Check(Screen.Caption(Screen.Row) == Screen.StartMatchText, "start match caption");
    }
    Screen.Roster = new class'TeamBrowser';
    Screen.Roster.NextButton = new class'NotifyButton';
    Screen.BuildList(); Screen.SelectPrimaryAction();
    Check(Screen.Caption(Screen.Row) == Screen.ContinueText, "team continue selected");
    Screen.Roster = None;
    Screen.Objectives = new class'ObjectiveBrowser';
    Screen.Objectives.NumNames = 3;
    for(i = 0; i < 3; i++) Screen.Objectives.Names[i] = new class'LadderButton';
    Screen.Objectives.NextButton = new class'NotifyButton';
    Screen.BuildList(); Screen.SelectPrimaryAction();
    Check(Screen.ControlAt(Screen.Row) == Screen.Objectives.NextButton, "objectives continue selected");
    Check(Screen.Count == 5, "all objectives and back retained");
    R = new class'UT99ConsoleRoot';
    C = new class'UTConsole';
    R.Console = C;
    C.bUWindowActive = False; C.bShowMessage = True;
    Check(!R.ShouldPaintBackdrop(), "tutorial message keeps world sharp");
    C.bShowSpeech = True;
    Check(!R.ShouldPaintBackdrop(), "speech overlay keeps world sharp");
    C.bUWindowActive = True; C.bQuickKeyEnable = False;
    Check(R.ShouldPaintBackdrop(), "real menu retains backdrop");
    C.bQuickKeyEnable = True;
    Check(!R.ShouldPaintBackdrop(), "quick-key overlay keeps world sharp");
    Log("MENU_FLOW failures="$Failures);
    return Failures;
}

defaultproperties
{
    IsClient=False
    IsServer=False
    IsEditor=True
    LogToStdout=True
    ShowErrorCount=True
}
