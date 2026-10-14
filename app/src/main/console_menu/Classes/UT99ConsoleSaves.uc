// Keep SlotWindow's serialization, restore path and deletion notification.
class UT99ConsoleSaves extends UT99ConsoleHome;

var SlotWindow Slots;
var KillGameQueryClient DeleteQuery;
var int SelectedSlot;
var localized string SavesLocation, RestoreText, DeleteText;

function Created()
{
    Slots = SlotWindow(OwnerWindow);
    Slots.HideWindow();
    SelectedSlot = -1;
    Super.Created();
    NextActionTime = UIClock+0.20;
    FocusWindow();
}

function Tick(float Delta)
{
    UIClock += Delta; bActionThisTick = False;
}

function BuildList()
{
    if(DeleteQuery != None) Count = 3;
    else if(SelectedSlot >= 0) Count = 3;
    else Count = 6;
    Row = Clamp(Row, 0, Count-1);
}

function BeforePaint(Canvas C, float X, float Y)
{
    local int i;
    Slots.BeforePaint(C, X, Y);
    for(i = 0; i < 5; i++)
        if(Slots.Saves[i] != "")
        {
            Slots.SlotButton[i].WinWidth = WinWidth;
            Slots.SetSaveText(i, C);
        }
    Super.BeforePaint(C, X, Y);
}

function string Caption(int Index)
{
    if(Index == Count-1) return BackText;
    if(DeleteQuery != None)
    {
        if(Index == 0) return DeleteQuery.NoText;
        return DeleteQuery.YesText;
    }
    if(SelectedSlot >= 0)
    {
        if(Index == 0) return RestoreText;
        return DeleteText;
    }
    return string(Index+1)$". "$Slots.SlotButton[Index].Text;
}

function string GetLocation()
{
    local string S;
    S = CampaignText$" / "$SavesLocation;
    if(SelectedSlot >= 0) S = S$" / "$Slots.SlotButton[SelectedSlot].Text;
    return S;
}

function Paint(Canvas C, float X, float Y)
{
    local float W, H;
    Super.Paint(C, X, Y);
    if(DeleteQuery != None)
    {
        C.Font = Root.Fonts[F_Bold];
        C.DrawColor.R = 255; C.DrawColor.G = 220; C.DrawColor.B = 150;
        TextSize(C, DeleteQuery.QueryText, W, H);
        ClipText(C, (WinWidth-W)*0.5, WinHeight*0.88, DeleteQuery.QueryText);
    }
}

function ActivateRow()
{
    local KillGameQueryWindow Query;
    if(bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True; NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(DeleteQuery != None)
    {
        if(Row == 1) DeleteQuery.YesPressed();
        else DeleteQuery.NoPressed();
        DeleteQuery = None; Slots.ModalWindow = None;
        SelectedSlot = -1; Row = 0; BuildList();
        return;
    }
    if(SelectedSlot < 0)
    {
        if(Slots.Saves[Row] == "") return;
        SelectedSlot = Row; Row = 0; FirstRow = 0; BuildList();
    }
    else if(Row == 0)
    {
        Slots.RestoreGame(SelectedSlot);
        HideWindow();
    }
    else
    {
        Slots.KillGame(SelectedSlot);
        Query = KillGameQueryWindow(Root.FindChildWindow(class'KillGameQueryWindow'));
        if(Query != None)
        {
            DeleteQuery = KillGameQueryClient(Query.ClientArea);
            Query.HideWindow(); Slots.ModalWindow = None;
            Row = 0; BuildList(); FocusWindow();
        }
    }
}

function GoBack()
{
    if(DeleteQuery != None)
    {
        DeleteQuery.NoPressed(); DeleteQuery = None; Slots.ModalWindow = None;
        Row = 0; BuildList();
    }
    else if(SelectedSlot >= 0)
    {
        SelectedSlot = -1; Row = 0; FirstRow = 0; BuildList();
    }
    else
    {
        Slots.Close(); HideWindow();
    }
}

defaultproperties
{
    SavesLocation="SAVED TOURNAMENTS"
    RestoreText="RESUME TOURNAMENT"
    DeleteText="DELETE SAVE"
}
