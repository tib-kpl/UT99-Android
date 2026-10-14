// A console-style browser of the actual UMenu lists, not duplicated game logic.
class UT99ConsoleHome extends UWindowWindow;

#exec TEXTURE IMPORT NAME=UT99Logo FILE=Textures\UT99Logo.pcx FLAGS=2 MIPS=OFF

var UWindowPulldownMenu Page;
var UWindowPulldownMenu History[16];
var int HistoryRow[16], Depth, Row, FirstRow, Count, VisibleRows;
var UWindowList Entries[512];
var float MenuLeft, Top, Width, RowHeight;
var bool bActionThisTick;
var float UIClock, NextActionTime;
var localized string BackText, HintText, CampaignText;
var Font MenuFont;
var bool bScrollDrag;
var int LeaveRow;
var localized string ResumeText, LeaveText, MainLocation, PauseLocation;

function string PageName(UWindowPulldownMenu P)
{
    if(P == None) return "";
    if(UWindowMenuBarItem(P.Owner) != None)
        return RemoveAmpersand(UWindowMenuBarItem(P.Owner).Caption);
    return RemoveAmpersand(UWindowPulldownMenuItem(P.Owner).Caption);
}

function string GetLocation()
{
    local string S;
    local int i;
    S = MainLocation;
    if(UT99ConsoleRoot(Root).IsGameplayMenu()) S = PauseLocation;
    for(i = 0; i < Depth; i++)
        if(History[i] != None) S = S$" / "$PageName(History[i]);
    if(Page != None) S = S$" / "$PageName(Page);
    return S;
}

function DrawLocation(Canvas C, float Y)
{
    local float W, H;
    local string S;
    S = GetLocation();
    C.Font = Root.Fonts[F_Bold];
    C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
    TextSize(C, S, W, H);
    ClipText(C, FMax(8, (WinWidth-W)*0.5), Y, S);
}

function Created()
{
    Super.Created();
    SetAcceptsHotKeys(True);
    MenuFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
    BuildList();
    Log("UT99Console home created rows="@Count);
}

function WindowShown()
{
    Super.WindowShown();
    UT99ConsoleRoot(Root).ChooseMapBackdrop();
    if(Page != None)
    {
        Page.ShowWindow();
        Page.HideWindow();
        BuildList();
    }
}

function BuildList()
{
    local UWindowList I;
    local int j;
    for(j = 0; j < 512; j++)
        Entries[j] = None;
    Count = 0;
    if(Page == None)
        I = UT99ConsoleRoot(Root).MenuBar.Items.Next;
    else
        I = Page.Items.Next;
    while(I != None && Count < 511)
    {
        if(Page == None || UWindowPulldownMenuItem(I).Caption != "-")
            Entries[Count++] = I;
        I = I.Next;
    }
    LeaveRow = -1;
    if(Page == None && UT99ConsoleRoot(Root).IsGameplayMenu()) LeaveRow = Count++;
    Count++; // The final row is always Back.
    Row = Clamp(Row, 0, Max(0, Count-1));
}

function BeforePaint(Canvas C, float X, float Y)
{
    Width = FMin(WinWidth*0.70, WinHeight*1.20);
    MenuLeft = (WinWidth-Width)*0.5;
    Top = WinHeight*0.39;
    RowHeight = FClamp(WinHeight*0.075, 24, 44);
    VisibleRows = Max(1, int((WinHeight*0.48)/RowHeight));
    if(Row < FirstRow) FirstRow = Row;
    if(Row >= FirstRow+VisibleRows) FirstRow = Row-VisibleRows+1;
}

function string Caption(int Index)
{
    local string S;
    if(Index == Count-1)
    {
        if(Page == None && UT99ConsoleRoot(Root).IsGameplayMenu()) return ResumeText;
        return BackText;
    }
    if(Index == LeaveRow) return LeaveText;
    if(Page == None)
    {
        if(Entries[Index] == UT99ConsoleRoot(Root).MenuBar.GameItem)
            return CampaignText;
        S = UWindowMenuBarItem(Entries[Index]).Caption;
    }
    else
    {
        S = UWindowPulldownMenuItem(Entries[Index]).Caption;
        if(UWindowPulldownMenuItem(Entries[Index]).bChecked) S = "[+] "$S;
        if(UWindowPulldownMenuItem(Entries[Index]).SubMenu != None) S = S$"  >";
    }
    return RemoveAmpersand(S);
}

function Paint(Canvas C, float X, float Y)
{
    local int i;
    local float YPos, TextW, TextH, LogoW, LogoX;
    local string S;
    LogoW = FMin(WinWidth*0.70, WinHeight*0.82);
    LogoX = (WinWidth-LogoW)*0.5;
    C.Style = 2;
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    DrawStretchedTexture(C, LogoX, WinHeight*0.02, LogoW, LogoW*0.5, Texture'UT99Logo');
    C.Style = 1;
    DrawLocation(C, WinHeight*0.35);
    C.Font = MenuFont;
    if(C.Font == None) C.Font = Root.Fonts[F_LargeBold];
    for(i = FirstRow; i < Min(Count, FirstRow+VisibleRows); i++)
    {
        YPos = Top+(i-FirstRow)*RowHeight;
        if(i == Row)
        {
            C.DrawColor.R = 90; C.DrawColor.G = 15; C.DrawColor.B = 20;
            DrawStretchedTexture(C, MenuLeft, YPos, Width, RowHeight-2, Texture'UWindow.WhiteTexture');
            C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
            DrawStretchedTexture(C, MenuLeft, YPos, Width, 1, Texture'UWindow.WhiteTexture');
            DrawStretchedTexture(C, MenuLeft, YPos+RowHeight-3, Width, 1, Texture'UWindow.WhiteTexture');
        }
        C.DrawColor.R = 225; C.DrawColor.G = 220; C.DrawColor.B = 205;
        if(Page != None && Entries[i] != None && UWindowPulldownMenuItem(Entries[i]).bDisabled)
        { C.DrawColor.R = 105; C.DrawColor.G = 105; C.DrawColor.B = 105; }
        if(i == Row)
        { C.DrawColor.R = 255; C.DrawColor.G = 208; C.DrawColor.B = 100; }
        S = Caption(i);
        TextSize(C, S, TextW, TextH);
        ClipText(C, MenuLeft+(Width-TextW)*0.5, YPos+(RowHeight-TextH)*0.5, S);
    }
    C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
    DrawScrollIndicator(C);
    C.Font = Root.Fonts[F_Normal];
    C.DrawColor.R = 160; C.DrawColor.G = 160; C.DrawColor.B = 165;
    TextSize(C, HintText, TextW, TextH);
    ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.94, HintText);
}

function DrawScrollIndicator(Canvas C)
{
    local float TrackH, ThumbH, ThumbY, TrackX;
    if(Count <= VisibleRows) return;
    TrackX = MenuLeft+Width+12;
    TrackH = VisibleRows*RowHeight-2;
    ThumbH = FMax(18, TrackH*VisibleRows/Count);
    ThumbY = Top+(TrackH-ThumbH)*FirstRow/Max(1, Count-VisibleRows);
    C.DrawColor.R = 38; C.DrawColor.G = 27; C.DrawColor.B = 29;
    DrawStretchedTexture(C, TrackX, Top, 6, TrackH, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 190; C.DrawColor.G = 130; C.DrawColor.B = 48;
    DrawStretchedTexture(C, TrackX, ThumbY, 6, ThumbH, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 255; C.DrawColor.G = 209; C.DrawColor.B = 106;
    DrawStretchedTexture(C, TrackX+1, ThumbY+2, 2, ThumbH-4, Texture'UWindow.WhiteTexture');
}

function OpenPage(UWindowPulldownMenu NextPage)
{
    if(NextPage == None || Depth >= 16) return;
    History[Depth] = Page;
    HistoryRow[Depth++] = Row;
    Page = NextPage;
    // Let the original menu update connection/game-dependent disabled items.
    Page.ShowWindow();
    Page.HideWindow();
    Row = 0; FirstRow = 0;
    BuildList();
}

function ActivateRow()
{
    local UWindowPulldownMenuItem I;
    if(Count == 0) return;
    // Older controller paths emit Enter and a synthetic click in the same tick.
    if(bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True;
    NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(Row == LeaveRow)
    {
        UT99ConsoleRoot(Root).ResetHome();
        Root.Console.CloseUWindow();
        GetPlayerOwner().ClientTravel("UT-Logo-Map.unr?Game=Botpack.UTIntro", TRAVEL_Absolute, False);
        return;
    }
    LookAndFeel.PlayMenuSound(Self, MS_MenuPullDown);
    if(Page == None)
        OpenPage(UWindowMenuBarItem(Entries[Row]).Menu);
    else
    {
        I = UWindowPulldownMenuItem(Entries[Row]);
        if(I.bDisabled) return;
        if(I.SubMenu != None)
            OpenPage(I.SubMenu);
        else
        {
            Page.BeforeExecuteItem(I);
            Page.ExecuteItem(I);
            BuildList();
        }
    }
}

function GoBack()
{
    if(Depth == 0)
    {
        Root.Console.CloseUWindow();
        return;
    }
    Depth--;
    Page = History[Depth];
    Row = HistoryRow[Depth];
    FirstRow = 0;
    BuildList();
}

function bool HotKeyDown(int Key, float X, float Y)
{
    if(!bWindowVisible) return False;
    switch(Key)
    {
        case 0x26: Row = (Row+Count-1)%Max(1, Count); return True;
        case 0x28: Row = (Row+1)%Max(1, Count); return True;
        case 0x0D: ActivateRow(); return True;
        case 0x27: ActivateRow(); return True;
        case 0x25: GoBack(); return True;
        case 0x08: GoBack(); return True;
        case 0xC9: GoBack(); return True; // Joy2 / B, only while this home is visible.
    }
    return False;
}

function MouseMove(float X, float Y)
{
    local int Index;
    if(bScrollDrag)
    {
        Row = Clamp(int((Y-Top)*Count/(VisibleRows*RowHeight)), 0, Count-1);
        return;
    }
    if(X < MenuLeft || X > MenuLeft+Width || Y < Top) return;
    Index = FirstRow+int((Y-Top)/RowHeight);
    if(Index < Count && Index < FirstRow+VisibleRows) Row = Index;
}

function LMouseDown(float X, float Y)
{
    // Down is used by both native pointer and the Android direct touch router.
    if(Count > VisibleRows && X > MenuLeft+Width && X < MenuLeft+Width+32 &&
       Y >= Top && Y < Top+VisibleRows*RowHeight)
    {
        bScrollDrag = True;
        Root.CaptureMouse(Self);
        MouseMove(X, Y);
        return;
    }
    if(X >= MenuLeft && X <= MenuLeft+Width && Y >= Top && Y < Top+Min(Count-FirstRow, VisibleRows)*RowHeight)
    {
        MouseMove(X, Y);
        ActivateRow();
    }
}

function LMouseUp(float X, float Y)
{
    if(bScrollDrag) Root.CancelCapture();
    bScrollDrag = False;
}

function Close(optional bool bByParent)
{
    if(bByParent)
    {
        Super.Close(bByParent);
        HideWindow();
    }
    else GoBack();
}

defaultproperties
{
    BackText="BACK"
    ResumeText="RESUME GAME"
    LeaveText="LEAVE GAME"
    MainLocation="MAIN MENU"
    PauseLocation="IN GAME"
    HintText="UP/DOWN: select   ENTER / A: confirm   ESC / B: back"
    CampaignText="TOURNAMENT / GAME"
    bAcceptsFocus=True
}
