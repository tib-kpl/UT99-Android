// A console-style browser of the actual UMenu lists, not duplicated game logic.
class UT99ConsoleHome extends UWindowWindow;

var UWindowPulldownMenu Page;
var UWindowPulldownMenu History[16];
var int HistoryRow[16], Depth, Row, FirstRow, Count, VisibleRows;
var UWindowList Entries[128];
var float Left, Top, Width, RowHeight;
var bool bActionThisTick;
var localized string BackText, HintText, CampaignText;

function Created()
{
    Super.Created();
    SetAcceptsHotKeys(True);
    BuildList();
}

function BuildList()
{
    local UWindowList I;
    local int j;
    for(j = 0; j < 128; j++)
        Entries[j] = None;
    Count = 0;
    if(Page == None)
        I = UT99ConsoleRoot(Root).MenuBar.Items.Next;
    else
        I = Page.Items.Next;
    while(I != None && Count < 128)
    {
        if(Page == None || UWindowPulldownMenuItem(I).Caption != "-")
            Entries[Count++] = I;
        I = I.Next;
    }
    Row = Clamp(Row, 0, Max(0, Count-1));
}

function BeforePaint(Canvas C, float X, float Y)
{
    Left = WinWidth*0.08;
    Top = WinHeight*0.25;
    Width = WinWidth*0.65;
    RowHeight = FClamp(WinHeight*0.09, 22, 44);
    VisibleRows = Max(1, int((WinHeight*0.60)/RowHeight));
    if(Row < FirstRow) FirstRow = Row;
    if(Row >= FirstRow+VisibleRows) FirstRow = Row-VisibleRows+1;
}

function string Caption(int Index)
{
    local string S;
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
    local float YPos;
    C.Font = Root.Fonts[F_Large];
    C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
    ClipText(C, Left, WinHeight*0.09, "UNREAL TOURNAMENT");
    C.Font = Root.Fonts[F_Normal];
    C.DrawColor.R = 180; C.DrawColor.G = 50; C.DrawColor.B = 42;
    DrawStretchedTexture(C, Left, WinHeight*0.18, Width, 2, Texture'UWindow.WhiteTexture');
    C.Font = Root.Fonts[F_Large];
    for(i = FirstRow; i < Min(Count, FirstRow+VisibleRows); i++)
    {
        YPos = Top+(i-FirstRow)*RowHeight;
        if(i == Row)
        {
            C.DrawColor.R = 100; C.DrawColor.G = 22; C.DrawColor.B = 26;
            DrawStretchedTexture(C, Left, YPos, Width, RowHeight-2, Texture'UWindow.WhiteTexture');
            C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
            DrawStretchedTexture(C, Left, YPos, 3, RowHeight-2, Texture'UWindow.WhiteTexture');
        }
        C.DrawColor.R = 225; C.DrawColor.G = 220; C.DrawColor.B = 205;
        if(Page != None && UWindowPulldownMenuItem(Entries[i]).bDisabled)
        { C.DrawColor.R = 105; C.DrawColor.G = 105; C.DrawColor.B = 105; }
        ClipText(C, Left+12, YPos+6, Caption(i));
    }
    C.Font = Root.Fonts[F_Normal];
    C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
    ClipText(C, Left, WinHeight*0.88, BackText);
    C.DrawColor.R = 160; C.DrawColor.G = 160; C.DrawColor.B = 165;
    ClipText(C, Left, WinHeight*0.94, HintText);
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
    if(bActionThisTick) return;
    bActionThisTick = True;
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
    if(X < Left || X > Left+Width || Y < Top) return;
    Index = FirstRow+int((Y-Top)/RowHeight);
    if(Index < Count && Index < FirstRow+VisibleRows) Row = Index;
}

function LMouseDown(float X, float Y)
{
    // Down is used by both native pointer and the Android direct touch router.
    if(Y >= WinHeight*0.86 && Y < WinHeight*0.93) { GoBack(); return; }
    if(X >= Left && X <= Left+Width && Y >= Top && Y < Top+Min(Count-FirstRow, VisibleRows)*RowHeight)
    {
        MouseMove(X, Y);
        ActivateRow();
    }
}

function Close(optional bool bByParent)
{
    if(bByParent) Super.Close(bByParent);
    else GoBack();
}

defaultproperties
{
    BackText="< BACK"
    HintText="UP/DOWN: select   ENTER / A: confirm   ESC / B: back"
    CampaignText="TOURNAMENT / GAME"
    bAcceptsFocus=True
}
