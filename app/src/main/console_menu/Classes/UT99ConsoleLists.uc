// Rotation and mutator lists keep the native transfer/reorder notifications.
class UT99ConsoleLists extends UT99ConsoleMatch;

var UMenuMapListCW Maps;
var UMenuMutatorCW Mutators;
var UWindowListBox Included, Excluded, CurrentList;
var UT99ConsoleMatch PreviousScreen;
var string IncludedCaption, ExcludedCaption;

function Created()
{
    NativeWindow = UWindowFramedWindow(OwnerWindow);
    Maps = UMenuMapListCW(NativeWindow.ClientArea);
    Mutators = UMenuMutatorCW(NativeWindow.ClientArea);
    if(Maps != None)
    {
        MatchClient = Maps.BotmatchParent;
        Included = Maps.Include; Excluded = Maps.Exclude;
        IncludedCaption = Maps.IncludeCaption; ExcludedCaption = Maps.ExcludeCaption;
    }
    else if(Mutators != None)
    {
        MatchClient = Mutators.BotmatchParent;
        Included = Mutators.Include; Excluded = Mutators.Exclude;
        IncludedCaption = Mutators.IncludeCaption; ExcludedCaption = Mutators.ExcludeCaption;
    }
    PreviousScreen = UT99ConsoleRoot(Root).MatchScreen;
    PreviousScreen.HideWindow();
    PreviousScreen.NativeWindow.ModalWindow = None;
    NativeWindow.HideWindow();
    SetAcceptsHotKeys(True);
    MenuFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
    BuildList();
    NextActionTime = UIClock+0.20;
    FocusWindow();
}

function string GetLocation()
{
    local string S;
    S = PreviousScreen.GetLocation()$" / "$RemoveAmpersand(NativeWindow.WindowTitle);
    if(CurrentList == Included) S = S$" / "$IncludedCaption;
    else if(CurrentList == Excluded) S = S$" / "$ExcludedCaption;
    return S;
}

function BuildList()
{
    local UWindowList Item;
    local int i;
    if(Picker != None) { Super.BuildList(); return; }
    for(i = 0; i < 512; i++) { Entries[i] = None; Controls[i] = None; }
    Count = 0;
    if(CurrentList != None)
    {
        for(Item = CurrentList.Items.Next; Item != None && Count < 511; Item = Item.Next)
            Entries[Count++] = Item;
    }
    else
    {
        Count = 2;
        if(Maps != None) Controls[Count++] = Maps.DefaultCombo;
        else if(Mutators != None) Controls[Count++] = Mutators.KeepCheck;
    }
    Count++;
    Row = Clamp(Row, 0, Max(0, Count-1));
}

function string Caption(int Index)
{
    if(Index == Count-1) return BackText;
    if(Picker != None) return Super.Caption(Index);
    if(CurrentList != None)
    {
        if(Maps != None) return UMenuMapList(Entries[Index]).DisplayName;
        return UMenuMutatorList(Entries[Index]).MutatorName;
    }
    if(Index == 0) return IncludedCaption;
    if(Index == 1) return ExcludedCaption;
    return Super.Caption(Index);
}

function ActivateRow()
{
    if(Picker != None || (CurrentList == None && Row >= 2))
    { Super.ActivateRow(); return; }
    if(Count == 0 || bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True; NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(CurrentList != None)
        CurrentList.DoubleClickItem(UWindowListBoxItem(Entries[Row]));
    else if(Row == 0) { CurrentList = Included; Row = 0; FirstRow = 0; }
    else if(Row == 1) { CurrentList = Excluded; Row = 0; FirstRow = 0; }
    BuildList();
}

function ChangeValue(int Direction)
{
    local UWindowList Item, Neighbor;
    if(CurrentList == None) { Super.ChangeValue(Direction); return; }
    if(CurrentList != Included || Count == 0) return;
    Item = Entries[Row];
    if(Direction < 0)
    {
        if(Row == 0) return;
        Neighbor = Item.Prev;
        Item.Remove(); Neighbor.InsertItemBefore(Item);
        Row--;
    }
    else
    {
        Neighbor = Item.Next;
        if(Neighbor == None) return;
        Item.Remove(); Neighbor.InsertItemAfter(Item, True);
        Row++;
    }
    Included.Notify(DE_Change);
    BuildList();
}

function bool HotKeyDown(int Key, float X, float Y)
{
    if(CurrentList != None && (Key == 0x25 || Key == 0x27))
    { ChangeValue(Key-0x26); return True; }
    return Super.HotKeyDown(Key, X, Y);
}

function GoBack()
{
    if(Picker != None) { Picker = None; BuildList(); return; }
    if(CurrentList != None)
    { CurrentList = None; Row = 0; FirstRow = 0; BuildList(); return; }
    NativeWindow.Close();
    PreviousScreen.ShowWindow(); PreviousScreen.FocusWindow();
    Super.Close(True);
}

defaultproperties
{
    HintText="ENTER / A: add or remove   LEFT/RIGHT: reorder   ESC / B: back"
}
