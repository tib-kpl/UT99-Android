// Present native dialog controls without duplicating their notification/config logic.
class UT99ConsoleDialog extends UT99ConsoleMatch;

var UWindowPageControl Tabs;
var UWindowWindow PreviousScreen, NativeHost;
var UMenuCustomizeClientWindow BindingOwner;
var UMenuWeaponPriorityListBox Weapons;
var UMenuPlayerMeshClient PlayerPreview;
var UMenuWeaponPriorityMesh WeaponPreview;
var UWindowWindow PlayerPreviewParent, WeaponPreviewParent, NativeParent;
var bool bEmbedded, bNativeClosed;
var UT99ConsoleText WeaponDetails;
var bool bDetailMode;
var int DetailReturnRow;
var localized string DetailsText;
var UT99ConsoleText Notice;
var UWindowComboControl EditComboTarget;
var byte HistoryEntries[512];
var localized string HistoryText;
var localized string BindingHint, WeaponsText, ReorderHint, PreviewFaceText;
var localized string ServerAddressText, JoinServerText, RecentServersText, AddressHelp, AddressLocation;

function UWindowPageControl FindTabs(UWindowWindow W)
{
    local UWindowWindow Child;
    local UWindowPageControl Result;
    if(UWindowPageControl(W) != None) return UWindowPageControl(W);
    for(Child = W.FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
    {
        Result = FindTabs(Child);
        if(Result != None) return Result;
    }
    return None;
}

function Created()
{
    local UT99ConsoleRoot R;
    local UT99ConsoleCloseObserver Observer;
    R = UT99ConsoleRoot(Root);
    NativeWindow = UWindowFramedWindow(OwnerWindow);
    NativeParent = NativeWindow.ParentWindow;
    if(R.DialogScreen != None && R.DialogScreen.bWindowVisible) PreviousScreen = R.DialogScreen;
    else if(R.SavesScreen != None && R.SavesScreen.bWindowVisible) PreviousScreen = R.SavesScreen;
    else if(R.CampaignScreen != None && R.CampaignScreen.bWindowVisible) PreviousScreen = R.CampaignScreen;
    else if(R.ListsScreen != None && R.ListsScreen.bWindowVisible) PreviousScreen = R.ListsScreen;
    else if(R.MatchScreen != None && R.MatchScreen.bWindowVisible) PreviousScreen = R.MatchScreen;
    else PreviousScreen = R.Home;
    if(PreviousScreen != None) PreviousScreen.HideWindow();
    NativeWindow.HideWindow();
    if(NativeWindow.OwnerWindow != None) NativeWindow.OwnerWindow.ModalWindow = None;
    Observer = UT99ConsoleCloseObserver(NativeWindow.ClientArea.FindChildWindow(class'UT99ConsoleCloseObserver'));
    if(Observer != None) { Observer.Adapter = None; Observer.Close(); }
    Observer = UT99ConsoleCloseObserver(NativeWindow.ClientArea.CreateWindow(class'UT99ConsoleCloseObserver', 0, 0, 0, 0));
    Observer.Adapter = Self;
    Tabs = FindTabs(NativeWindow.ClientArea);
    PlayerPreview = UMenuPlayerMeshClient(NativeWindow.FindChildWindow(class'UMenuPlayerMeshClient'));
    WeaponPreview = UMenuWeaponPriorityMesh(NativeWindow.FindChildWindow(class'UMenuWeaponPriorityMesh'));
    Weapons = UMenuWeaponPriorityListBox(NativeWindow.FindChildWindow(class'UMenuWeaponPriorityListBox'));
    if(Weapons != None) Log("UT99Console weapon list:"@Weapons.Class@"items="@Weapons.Items.Count()@"visible="@Weapons.Items.CountShown());
    if(Weapons != None && Weapons.Items.CountShown() == 0) FillMissingWeapons();
    if(Weapons != None) HintText = ReorderHint;
    SetAcceptsHotKeys(True);
    MenuFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
    BuildList();
    Notice = UT99ConsoleText(CreateWindow(class'UT99ConsoleText', WinWidth*0.08, WinHeight*0.71, WinWidth*0.84, WinHeight*0.20));
    PlayerPreviewParent = None; WeaponPreviewParent = None;
    if(PlayerPreview != None) PlayerPreviewParent = PlayerPreview.ParentWindow;
    if(WeaponPreview != None) WeaponPreviewParent = WeaponPreview.ParentWindow;
    if(Count <= 1 || NativeWindow.IsA('UBrowserMainWindow') || NativeWindow.IsA('UWindowConsoleWindow'))
    {
        bEmbedded = True; Count = 1;
        NativeHost = CreateWindow(class'UWindowWindow', 0, 0, 100, 100);
        NativeWindow.SetParent(NativeHost);
    }
    else
    {
        if(PlayerPreview != None) PlayerPreview.SetParent(Self);
        if(Weapons != None && WeaponPreview != None)
        {
            Weapons.MeshWindow = WeaponPreview;
            WeaponPreview.SetParent(Self);
            WeaponDetails = UT99ConsoleText(CreateWindow(class'UT99ConsoleText', 0, 0, 100, 100));
        }
    }
    NextActionTime = UIClock+0.20;
    FocusWindow();
}

function FillMissingWeapons()
{
    local string ClassName;
    local int i;
    local UMenuWeaponPriorityList Item;
    local class<Weapon> WeaponClass;
    ClassName = GetPlayerOwner().GetNextInt(Weapons.WeaponClassParent, 0);
    while(ClassName != "" && i < 20)
    {
        WeaponClass = class<Weapon>(DynamicLoadObject(ClassName, class'Class', True));
        if(WeaponClass != None)
        {
            for(Item = UMenuWeaponPriorityList(Weapons.Items.Next); Item != None; Item = UMenuWeaponPriorityList(Item.Next))
                if(Item.PriorityName == WeaponClass.Name) break;
            if(Item == None && Weapons.Items.Count() < 20)
                Item = UMenuWeaponPriorityList(Weapons.Items.Append(Weapons.ListClass));
            if(Item == None)
            {
                ClassName = GetPlayerOwner().GetNextInt(Weapons.WeaponClassParent, ++i);
                continue;
            }
            Item.PriorityName = WeaponClass.Name;
            Item.WeaponClassName = ClassName; Item.bFound = True;
            Weapons.ReadWeapon(Item, WeaponClass);
        }
        ClassName = GetPlayerOwner().GetNextInt(Weapons.WeaponClassParent, ++i);
    }
}

function Tick(float Delta)
{
    UIClock += Delta; bActionThisTick = False;
    if(bNativeClosed) { Finish(); return; }
    if(!bEmbedded) NativeWindow.Tick(Delta);
}

function AddControls(UWindowWindow W, int Nest)
{
    local UWindowWindow Child;
    local UWindowDialogControl Control;
    if(W == None || Nest > 16) return;
    for(Child = W.FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
    {
        if(Child == PlayerPreview || Child == WeaponPreview) continue;
        Control = UWindowDialogControl(Child);
        if(UWindowSmallCloseButton(Control) != None) continue;
        if(UWindowComboControl(Control) != None || UWindowCheckbox(Control) != None ||
           UWindowHSliderControl(Control) != None || UWindowEditControl(Control) != None || UWindowButton(Control) != None)
        {
            if(Count < 510 && (Control.Text != "" || UMenuRaisedButton(Control) != None))
            {
                Controls[Count++] = Control;
                if(UWindowComboControl(Control) != None && UWindowComboControl(Control).EditBox.bCanEdit)
                {
                    HistoryEntries[Count] = 1; Controls[Count++] = Control;
                }
            }
        }
        else AddControls(Child, Nest+1);
    }
}

function BuildList()
{
    local int i;
    local UWindowList Item;
    local UWindowPageControlPage Tab;
    if(bEmbedded || bDetailMode) { Count = 1; return; }
    for(i = 0; i < 512; i++) { Entries[i] = None; Controls[i] = None; HistoryEntries[i] = 0; }
    Count = 0;
    if(Picker != None)
    {
        for(Item = Picker.List.Items.Next; Item != None && Count < 511; Item = Item.Next)
            Entries[Count++] = Item;
    }
    else if(Tabs != None && SectionName == "")
    {
        for(Item = Tabs.Items.Next; Item != None && Count < 511; Item = Item.Next)
            Entries[Count++] = Item;
    }
    else if(Tabs != None)
    {
        Tab = Tabs.GetPage(SectionName);
        if(Tab != None) AddControls(Tab.Page, 0);
    }
    else
    {
        if(Weapons != None)
            for(Item = Weapons.Items.Next; Item != None && Count < 500; Item = Item.Next)
                if(Item.ShowThisItem()) Entries[Count++] = Item;
        if(PlayerPreview != None) Controls[Count++] = PlayerPreview.FaceButton;
        AddControls(NativeWindow, 0);
        if(Weapons != None) Count++; // Full description action.
    }
    Count++; Row = Clamp(Row, 0, Count-1);
}

function string Caption(int Index)
{
    local UMenuCustomizeClientWindow Keys;
    local UWindowWindow Label;
    if(Index == Count-1) return BackText;
    if(NativeWindow.IsA('UBrowserOpenWindow') && Picker == None)
    {
        if(HistoryEntries[Index] != 0) return RecentServersText;
        if(UWindowComboControl(Controls[Index]) != None)
            return ServerAddressText$" : "$UWindowComboControl(Controls[Index]).GetValue();
        if(UWindowSmallOKButton(Controls[Index]) != None) return JoinServerText;
    }
    if(Weapons != None && Index == Count-2) return DetailsText;
    if(HistoryEntries[Index] != 0 && Picker == None) return HistoryText$" : "$Controls[Index].Text;
    if(PlayerPreview != None && Controls[Index] == PlayerPreview.FaceButton) return PreviewFaceText;
    if(Weapons != None && Entries[Index] != None && Picker == None)
        return string(Index+1)$". "$UMenuWeaponPriorityList(Entries[Index]).WeaponName;
    if(UMenuRaisedButton(Controls[Index]) != None)
    {
        Keys = UMenuCustomizeClientWindow(Controls[Index].NotifyWindow);
        if(Keys != None)
            for(Label = Keys.FirstChildWindow; Label != None; Label = Label.NextSiblingWindow)
                if(UMenuLabelControl(Label) != None && Abs(Label.WinTop-Controls[Index].WinTop-3) < 1)
                    return UMenuLabelControl(Label).Text$" : "$Controls[Index].Text;
    }
    return Super.Caption(Index);
}

function string GetLocation()
{
    local string S;
    S = UT99ConsoleHome(PreviousScreen).GetLocation();
    if(NativeWindow.IsA('UBrowserOpenWindow')) S = S$" / "$AddressLocation;
    else S = S$" / "$RemoveAmpersand(NativeWindow.WindowTitle);
    if(SectionName != "") S = S$" / "$SectionName;
    if(Picker != None) S = S$" / "$RemoveAmpersand(Picker.Text);
    if(EditTarget != None) S = S$" / "$RemoveAmpersand(EditTarget.Text);
    if(EditComboTarget != None) S = S$" / "$RemoveAmpersand(EditComboTarget.Text);
    return S;
}

function PrepareControls(UWindowWindow W, Canvas C, int Nest)
{
    local UWindowWindow Child, Next;
    if(W == None || Nest > 16) return;
    W.BeforePaint(C, 0, 0);
    for(Child = W.FirstChildWindow; Child != None; Child = Next)
    {
        Next = Child.NextSiblingWindow;
        PrepareControls(Child, C, Nest+1);
    }
}

function BeforePaint(Canvas C, float X, float Y)
{
    local Region Client;
    local UWindowPageControlPage Tab;
    Super.BeforePaint(C, X, Y);
    if(bDetailMode)
    {
        Top = WinHeight*0.86;
        WeaponDetails.WinLeft = WinWidth*0.08; WeaponDetails.WinTop = WinHeight*0.42;
        WeaponDetails.SetSize(WinWidth*0.84, WinHeight*0.42);
        return;
    }
    if(bEmbedded)
    {
        Top = WinHeight*0.86;
        NativeHost.WinLeft = WinWidth*0.05; NativeHost.WinTop = WinHeight*0.40;
        NativeHost.SetSize(WinWidth*0.90, WinHeight*0.44);
        NativeWindow.SetSize(NativeHost.WinWidth+12, NativeHost.WinHeight+30);
        Client = LookAndFeel.FW_GetClientArea(NativeWindow);
        NativeWindow.WinLeft = -Client.X; NativeWindow.WinTop = -Client.Y;
        NativeWindow.SetSize(NativeHost.WinWidth+NativeWindow.WinWidth-Client.W,
                             NativeHost.WinHeight+NativeWindow.WinHeight-Client.H);
        return;
    }
    if(Tabs != None && SectionName != "")
    {
        Tab = Tabs.GetPage(SectionName);
        if(Tab != None) PrepareControls(Tab.Page, C, 0);
    }
    if(Tabs == None && !bEmbedded) PrepareControls(NativeWindow.ClientArea, C, 0);
    if(Weapons != None && Entries[Row] != None)
    {
        Weapons.SetSelectedItem(UWindowListBoxItem(Entries[Row]));
        Weapons.SelectWeapon();
    }
    if(PlayerPreview != None || WeaponPreview != None)
    {
        MenuLeft = WinWidth*0.05; Width = WinWidth*0.47;
        if(PlayerPreview != None)
        {
            PlayerPreview.WinLeft = WinWidth*0.56; PlayerPreview.WinTop = Top;
            PlayerPreview.SetSize(WinWidth*0.40, WinHeight*0.40);
            PlayerPreview.MeshActor.DrawScale = PlayerPreview.MeshActor.Default.DrawScale*0.50;
        }
        if(WeaponPreview != None)
        {
            WeaponPreview.WinLeft = WinWidth*0.56; WeaponPreview.WinTop = Top;
            WeaponPreview.SetSize(WinWidth*0.40, WinHeight*0.28);
            WeaponDetails.WinLeft = WinWidth*0.56; WeaponDetails.WinTop = WinHeight*0.71;
            WeaponDetails.SetSize(WinWidth*0.40, WinHeight*0.17);
            if(UTWeaponPriorityList(Weapons.SelectedItem) != None)
                WeaponDetails.Text = UTWeaponPriorityList(Weapons.SelectedItem).WeaponDescription;
            else WeaponDetails.Text = "";
        }
    }
}

function Paint(Canvas C, float X, float Y)
{
    local string Message;
    local float W, H;
    local UWindowMessageBox MessageBox;
    local bool bTimedOut;
    Super.Paint(C, X, Y);
    if(BindingOwner != None && BindingOwner.bPolling) Message = BindingHint;
    else if(UWindowMessageBoxCW(NativeWindow.ClientArea) != None)
        Message = UWindowMessageBoxCW(NativeWindow.ClientArea).MessageArea.Message;
    else if(FreeSlotsClient(NativeWindow.ClientArea) != None)
        Message = FreeSlotsClient(NativeWindow.ClientArea).QueryText;
    else if(NativeWindow.IsA('UBrowserOpenWindow')) Message = AddressHelp;
    MessageBox = UWindowMessageBox(NativeWindow);
    if(MessageBox != None)
    {
        bTimedOut = MessageBox.TimeOutTime != 0 && GetEntryLevel().TimeSeconds > MessageBox.TimeOutTime;
        MessageBox.AfterPaint(C, 0, 0);
        if(bTimedOut) Finish();
    }
    Notice.Text = Message;
    Notice.WinLeft = WinWidth*0.08; Notice.WinTop = WinHeight*0.71;
    Notice.SetSize(WinWidth*0.84, WinHeight*0.20);
}

function ActivateRow()
{
    local UWindowPageControlPage Tab;
    local UWindowButton Button;
    local UWindowComboControl Combo;
    if(Row == Count-1) { GoBack(); return; }
    if(bActionThisTick || UIClock < NextActionTime) return;
    if(Weapons != None && Row == Count-2)
    {
        DetailReturnRow = Row; bDetailMode = True; Row = 0; FirstRow = 0;
        WeaponPreview.HideWindow(); BuildList(); return;
    }
    if(Weapons != None && Entries[Row] != None && Picker == None)
    { Weapons.SetSelectedItem(UWindowListBoxItem(Entries[Row])); Weapons.SelectWeapon(); return; }
    if(Tabs != None && Entries[Row] != None && Picker == None)
    {
        Tab = UWindowPageControlPage(Entries[Row]); Tabs.GotoTab(Tab, True);
        SectionName = Tab.Caption; Row = 0; FirstRow = 0; BuildList();
        NextActionTime = UIClock+0.20; return;
    }
    Button = UWindowButton(Controls[Row]);
    if(Button != None && Picker == None)
    {
        if(Button.bDisabled) return;
        bActionThisTick = True; NextActionTime = UIClock+0.20;
        Button.Click(0, 0);
        BindingOwner = UMenuCustomizeClientWindow(Button.NotifyWindow);
        if(BindingOwner != None && BindingOwner.bPolling) return;
        BindingOwner = None;
        if(UWindowMessageBoxCW(NativeWindow.ClientArea) != None || FreeSlotsClient(NativeWindow.ClientArea) != None ||
           UWindowSmallOKButton(Button) != None || UWindowSmallCancelButton(Button) != None)
            Finish();
        else BuildList();
        return;
    }
    Combo = UWindowComboControl(Controls[Row]);
    if(Combo != None && Combo.EditBox.bCanEdit && Picker == None && HistoryEntries[Row] == 0)
    {
        EditComboTarget = Combo;
        InputField = UWindowEditControl(CreateWindow(class'UWindowEditControl', MenuLeft, WinHeight*0.48, Width, 24));
        InputField.SetText(Combo.Text); InputField.SetFont(F_Large); InputField.SetValue(Combo.GetValue());
        InputField.EditBox.MaxLength = Combo.EditBox.MaxLength;
        InputField.EditBox.ActivateWindow(0, False);
        GetPlayerOwner().ConsoleCommand("ANDROID_SHOW_KEYBOARD");
        NextActionTime = UIClock+0.20; return;
    }
    if(UWindowEditControl(Controls[Row]) != None && !UWindowEditControl(Controls[Row]).EditBox.bCanEdit) return;
    Super.ActivateRow();
}

function ChangeValue(int Direction)
{
    local UWindowList Item, Adjacent;
    if(Weapons != None && Entries[Row] != None && Picker == None)
    {
        Item = Entries[Row];
        if(Direction < 0) Adjacent = Item.Prev;
        else Adjacent = Item.Next;
        if(Adjacent == None || Adjacent == Weapons.Items) return;
        Item.Remove();
        if(Direction < 0) Adjacent.InsertItemBefore(Item);
        else Adjacent.InsertItemAfter(Item, True);
        Weapons.Notify(DE_Change); Weapons.SaveConfigs();
        Row = Clamp(Row+Direction, 0, Count-2); BuildList();
        return;
    }
    Super.ChangeValue(Direction);
}

function bool HotKeyDown(int Key, float X, float Y)
{
    if(!bWindowVisible) return False;
    if(InputField != None && EditComboTarget != None)
    {
        if(Key == 0x0D)
        {
            EditComboTarget.SetValue(InputField.EditBox.GetValue());
            InputField.Close(); InputField = None; EditComboTarget = None;
            GetPlayerOwner().ConsoleCommand("ANDROID_HIDE_KEYBOARD");
            FocusWindow(); BuildList(); return True;
        }
        return False;
    }
    if(bDetailMode && Key != 0xC9)
    {
        if(Key == 0x0D || Key == 0x1B || Key == 0x25) GoBack();
        return True;
    }
    if(Key == 0xC9) return UT99ConsoleRoot(Root).HandleBackButton();
    if(BindingOwner != None && BindingOwner.bPolling)
    {
        if(Key == 0x1B || Key == 0xC9)
        {
            BindingOwner.bPolling = False; BindingOwner.SelectedButton.bDisabled = False;
        }
        else BindingOwner.KeyDown(Key, 0, 0);
        BindingOwner = None; FocusWindow(); BuildList(); return True;
    }
    if(bEmbedded)
    {
        if(Key == 0xC9 || Key == 0x1B) { GoBack(); return True; }
        return False;
    }
    return Super.HotKeyDown(Key, X, Y);
}

function RestorePreviews()
{
    if(PlayerPreview != None) PlayerPreview.SetParent(PlayerPreviewParent);
    if(WeaponPreview != None) WeaponPreview.SetParent(WeaponPreviewParent);
}

function CloseForResume()
{
    if(BindingOwner != None && BindingOwner.bPolling)
    { BindingOwner.bPolling = False; BindingOwner.SelectedButton.bDisabled = False; }
    RestorePreviews();
    if(bEmbedded) NativeWindow.SetParent(NativeParent);
    if(!bNativeClosed) NativeWindow.Close();
    Finish();
}

function Finish()
{
    HideWindow();
    if(PreviousScreen != None)
    {
        PreviousScreen.ShowWindow(); PreviousScreen.FocusWindow();
        UT99ConsoleRoot(Root).DialogScreen = UT99ConsoleDialog(PreviousScreen);
    }
    else UT99ConsoleRoot(Root).DialogScreen = None;
}

function GoBack()
{
    if(bDetailMode)
    {
        bDetailMode = False; Row = DetailReturnRow; FirstRow = 0;
        WeaponPreview.ShowWindow(); BuildList(); return;
    }
    if(BindingOwner != None && BindingOwner.bPolling)
    { BindingOwner.bPolling = False; BindingOwner.SelectedButton.bDisabled = False; BindingOwner = None; return; }
    if(InputField != None || Picker != None) { EditComboTarget = None; Super.GoBack(); return; }
    if(SectionName != "") { SectionName = ""; Row = 0; FirstRow = 0; BuildList(); return; }
    RestorePreviews();
    if(bEmbedded) NativeWindow.SetParent(NativeParent);
    NativeWindow.EscClose(); Finish();
}

defaultproperties
{
    ServerAddressText="SERVER IP ADDRESS"
    JoinServerText="JOIN GAME"
    RecentServersText="RECENT SERVER ADDRESSES"
    AddressLocation="JOIN BY ADDRESS"
    AddressHelp="Enter the host address, for example 192.168.1.20:7777, then select JOIN GAME. For LAN, both devices must be on the same local network."
    BindingHint="Press a key to assign it. ESC: cancel"
    HistoryText="HISTORY"
    DetailsText="FULL WEAPON DESCRIPTION"
    PreviewFaceText="FACE / FULL BODY PREVIEW"
    WeaponsText="WEAPON PRIORITY"
    ReorderHint="UP/DOWN: select   LEFT/RIGHT: priority   ESC / B: back"
}
