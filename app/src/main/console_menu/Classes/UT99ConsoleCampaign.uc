// Adapt the existing tournament windows; the ladder inventory remains authoritative.
class UT99ConsoleCampaign extends UT99ConsoleMatch;

var NotifyWindow CampaignWindow;
var NewCharacterWindow Character;
var ManagerWindow Manager;
var UTLadder LevelScreen;
var localized string CharacterLocation, TypesLocation, LevelsLocation, ContinueText, LockedText;
var UWindowEditControl NameProxy;
var bool bFinished;
var byte WasLocked[32];
var float UnlockUntil;
var int UnlockRow;
var localized string UnlockText;
var UTFadeTextArea DetailArea;

function Created()
{
    CampaignWindow = NotifyWindow(OwnerWindow);
    Character = NewCharacterWindow(CampaignWindow);
    Manager = ManagerWindow(CampaignWindow);
    LevelScreen = UTLadder(CampaignWindow);
    CampaignWindow.HideWindow();
    SetAcceptsHotKeys(True);
    MenuFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
    if(Character != None)
    {
        Character.MeshWindow.SetParent(Self);
        NameProxy = UWindowEditControl(CreateWindow(class'UWindowEditControl', 0, 0, 1, 1));
        NameProxy.SetText(Character.NameText);
        NameProxy.SetValue(Character.NameEdit.GetValue());
        NameProxy.HideWindow();
        NoPreviewText = "";
        DetailArea = Character.TeamDescArea;
        DetailArea.SetParent(Self);
    }
    if(LevelScreen != None)
    {
        DetailArea = LevelScreen.MapInfoArea;
        DetailArea.SetParent(Self);
    }
    BuildList();
    for(UnlockRow = 0; UnlockRow < Min(32, Count-1); UnlockRow++) WasLocked[UnlockRow] = byte(IsLocked(UnlockRow));
    if(LevelScreen != None && LevelScreen.PendingPos > LevelScreen.ArrowPos)
    {
        UnlockRow = LevelScreen.PendingPos;
        Row = UnlockRow;
        UnlockUntil = UIClock+4;
    }
    NextActionTime = UIClock+0.20;
    FocusWindow();
}

function Tick(float Delta)
{
    if(bFinished) return;
    UIClock += Delta;
    bActionThisTick = False;
    CampaignWindow.Tick(Delta);
    if(Character != None && InputField == None && NameProxy.GetValue() != Character.NameEdit.GetValue())
    {
        Character.NameEdit.SetValue(NameProxy.GetValue());
        Character.NameChanged();
    }
}

function BuildList()
{
    local int i;
    local UWindowList Item;
    for(i = 0; i < 512; i++) { Entries[i] = None; Controls[i] = None; }
    Count = 0;
    if(Picker != None)
    {
        for(Item = Picker.List.Items.Next; Item != None && Count < 511; Item = Item.Next)
            Entries[Count++] = Item;
    }
    else if(Character != None)
    {
        Controls[Count++] = NameProxy;
        Controls[Count++] = Character.SexButton;
        Controls[Count++] = Character.TeamButton;
        Controls[Count++] = Character.FaceButton;
        Controls[Count++] = Character.SkillButton;
        Controls[Count++] = Character.NextButton;
    }
    else if(Manager != None)
    {
        Controls[Count++] = Manager.DMLadderButton;
        Controls[Count++] = Manager.DOMLadderButton;
        Controls[Count++] = Manager.CTFLadderButton;
        Controls[Count++] = Manager.ASLadderButton;
        Controls[Count++] = Manager.ChallengeLadderButton;
        Controls[Count++] = Manager.TrophyButton;
    }
    else if(LevelScreen != None && LevelScreen.LadderObj != None)
        for(i = 0; i < LevelScreen.LadderObj.CurrentLadder.Default.Matches; i++)
            Controls[Count++] = LevelScreen.Matches[i];
    Count++;
    Row = Clamp(Row, 0, Count-1);
}

function bool IsLocked(int Index)
{
    if(Index == Count-1) return False;
    if(Manager != None)
    {
        if(Index == 1) return Manager.DOMDoor != None && Manager.DOMDoor.bClosed;
        if(Index == 2) return Manager.CTFDoor != None && Manager.CTFDoor.bClosed;
        if(Index == 3) return Manager.ASDoor != None && Manager.ASDoor.bClosed;
        if(Index == 4) return Manager.ChalDoor != None && Manager.ChalDoor.bClosed;
        if(Index == 5) return Manager.TrophyDoor != None && Manager.TrophyDoor.bClosed;
    }
    if(LevelScreen != None) return UWindowButton(Controls[Index]).bDisabled;
    return False;
}

function string Caption(int Index)
{
    local string S;
    if(Index == Count-1) return BackText;
    if(NotifyButton(Controls[Index]) != None)
    {
        if(Character != None)
        {
            if(Index == 1) S = Character.SexText$" : "$Character.SexButton.Text;
            if(Index == 2) S = Character.TeamText$" : "$Character.TeamButton.Text;
            if(Index == 3) S = Character.FaceText$" : "$Character.FaceButton.Text;
            if(Index == 4) S = Character.SkillsText$" : "$Character.SkillButton.Text;
            if(Index == 5) S = ContinueText;
        }
        else S = NotifyButton(Controls[Index]).Text;
        if(IsLocked(Index)) S = S$"  ["$LockedText$"]";
        return RemoveAmpersand(S);
    }
    if(MatchButton(Controls[Index]) != None)
    {
        if(IsLocked(Index)) return string(Index+1)$". "$LockedText;
        return string(Index+1)$". "$LevelScreen.LadderObj.CurrentLadder.Static.GetMapTitle(Index);
    }
    return Super.Caption(Index);
}

function string GetLocation()
{
    if(Character != None) return CampaignText$" / "$CharacterLocation;
    if(Manager != None) return CampaignText$" / "$TypesLocation;
    return CampaignText$" / "$LevelScreen.LadderName$" / "$LevelsLocation;
}

function BeforePaint(Canvas C, float X, float Y)
{
    local int i;
    if(LevelScreen != None && LevelScreen.LadderObj != None) LevelScreen.BeforePaint(C, X, Y);
    for(i = 0; i < Min(32, Count-1); i++)
    {
        if(WasLocked[i] != 0 && !IsLocked(i))
        {
            UnlockRow = i; Row = i; UnlockUntil = UIClock+4;
        }
        WasLocked[i] = byte(IsLocked(i));
    }
    Super.BeforePaint(C, X, Y);
    if(Manager != None) return;
    MenuLeft = WinWidth*0.06; Width = WinWidth*0.42; Top = WinHeight*0.25;
    RowHeight = FClamp(WinHeight*0.065, 22, 40);
    VisibleRows = Max(1, int(WinHeight*0.62/RowHeight));
    if(Row < FirstRow) FirstRow = Row;
    if(Row >= FirstRow+VisibleRows) FirstRow = Row-VisibleRows+1;
    if(LevelScreen != None && LevelScreen.LadderObj != None && Row != Count-1 && !IsLocked(Row))
    {
        if(LevelScreen.SelectedMatch != Row)
        {
            LevelScreen.SelectedMatch = Row;
            LevelScreen.FillInfoArea(Row);
            LevelScreen.SetMapShot(Row);
        }
        PickerPicture = LevelScreen.MapShot;
        PickerMapName = Caption(Row)$".unr";
    }
    else { PickerPicture = None; PickerMapName = ""; }
    if(DetailArea != None)
    {
        DetailArea.WinLeft = WinWidth*0.54;
        DetailArea.WinTop = WinHeight*0.71;
        DetailArea.SetSize(WinWidth*0.40, WinHeight*0.16);
        DetailArea.MyFont = Root.Fonts[F_Normal];
        DetailArea.bAutoScrolling = True;
    }
    if(Character != None)
    {
        Character.MeshWindow.MeshActor.DrawScale = Character.MeshWindow.MeshActor.Default.DrawScale*0.50;
        Character.MeshWindow.WinLeft = WinWidth*0.54;
        Character.MeshWindow.WinTop = WinHeight*0.28;
        Character.MeshWindow.SetSize(WinWidth*0.40, WinHeight*PreviewHeight);
    }
}

function Paint(Canvas C, float X, float Y)
{
    local float W, H, Progress, Pulse;
    local string S;
    if(InputField != None) Super.Paint(C, X, Y);
    else if(Manager != None) Super.Paint(C, X, Y);
    else PaintMapPicker(C);
    if(UIClock < UnlockUntil)
    {
        Progress = FMin(1, (4-UnlockUntil+UIClock)/0.8);
        Pulse = 0.7+0.3*Sin(UIClock*8);
        C.DrawColor.R = 255*Pulse; C.DrawColor.G = 208*Pulse; C.DrawColor.B = 100*Pulse;
        DrawStretchedTexture(C, MenuLeft, Top+(UnlockRow-FirstRow)*RowHeight, Width*Progress, 3, Texture'UWindow.WhiteTexture');
        C.Font = Root.Fonts[F_Bold];
        S = UnlockText$" : "$Caption(UnlockRow);
        TextSize(C, S, W, H);
        ClipText(C, (WinWidth-W)*0.5, WinHeight*0.90, S);
    }
}

function ActivateRow()
{
    local NotifyButton B;
    if(Row == Count-1) { GoBack(); return; }
    if(IsLocked(Row) || bActionThisTick || UIClock < NextActionTime) return;
    if(NameProxy == Controls[Row]) { Super.ActivateRow(); return; }
    bActionThisTick = True; NextActionTime = UIClock+0.20;
    B = NotifyButton(Controls[Row]);
    if(Character != None)
    {
        if(B == Character.NextButton)
        {
            Character.MeshWindow.SetParent(Character);
            DetailArea.SetParent(Character);
            bFinished = True; HideWindow();
        }
        Character.Notify(B, DE_Click);
    }
    else if(Manager != None)
    {
        bFinished = True; HideWindow();
        if(B == Manager.TrophyButton) Manager.Notify(B, DE_Click);
        else Manager.Notify(B, DE_DoubleClick);
    }
    else if(LevelScreen != None)
    {
        if(DetailArea != None) DetailArea.SetParent(LevelScreen);
        bFinished = True; HideWindow();
        LevelScreen.Notify(Controls[Row], DE_Click);
        LevelScreen.NextPressed();
    }
}

function ChangeValue(int Direction)
{
    if(Character != None && Row > 0 && Row < 5) ActivateRow();
    else Super.ChangeValue(Direction);
}

function GoBack()
{
    if(InputField != None || Picker != None) { Super.GoBack(); return; }
    bFinished = True; HideWindow();
    if(Character != None)
    {
        Character.MeshWindow.SetParent(Character);
        DetailArea.SetParent(Character);
        Character.BackPressed();
    }
    else if(Manager != None) Manager.Close();
    else
    {
        if(DetailArea != None) DetailArea.SetParent(LevelScreen);
        LevelScreen.BackPressed();
    }
}

defaultproperties
{
    PreviewHeight=0.38
    PreviewLabelY=0.68
    CharacterLocation="PLAYER"
    TypesLocation="GAME TYPES"
    LevelsLocation="LEVELS"
    ContinueText="CONTINUE"
    LockedText="LOCKED"
    UnlockText="UNLOCKED"
    MapPickerHint="UP/DOWN: select   ENTER / A: play   ESC / B: back"
}
