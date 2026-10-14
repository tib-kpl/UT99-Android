// Project the original match controls into a full-screen list. Their Notify
// handlers still own map discovery, game-type changes, config and travel URLs.
class UT99ConsoleMatch extends UT99ConsoleHome;

var UWindowFramedWindow NativeWindow;
var UMenuBotmatchClientWindow MatchClient;
var UWindowDialogControl Controls[512];
var UWindowComboControl Picker;
var string SectionName;
var UWindowEditControl InputField, EditTarget;
var localized string EnabledText, DisabledText, EditHint;
var localized string PreviewText, NoPreviewText, MapPickerHint;
var int PreviewRow;
var bool bPreviewMap;
var bool bMapPicker;
var Texture PickerPicture;
var string PickerMapName;
var float PreviewHeight, PreviewLabelY;

function BeforePaint(Canvas C, float X, float Y)
{
    local string MapName, ObjectName;
    local int SavedFirstRow;
    SavedFirstRow = FirstRow;
    Super.BeforePaint(C, X, Y);
    if(Picker == None || !bMapPicker) return;
    FirstRow = SavedFirstRow;
    MenuLeft = WinWidth*0.06;
    Width = WinWidth*0.42;
    Top = WinHeight*0.25;
    RowHeight = FClamp(WinHeight*0.065, 22, 40);
    VisibleRows = Max(1, int((WinHeight*0.62)/RowHeight));
    if(Row < FirstRow) FirstRow = Row;
    if(Row >= FirstRow+VisibleRows) FirstRow = Row-VisibleRows+1;
    if(Row == Count-1) return;
    MapName = Picker.List.GetItemValue2(Row);
    if(MapName == PickerMapName) return;
    PickerMapName = MapName;
    MapName = Left(MapName, Len(MapName)-4);
    ObjectName = MapName$".Screenshot";
    PickerPicture = Texture(DynamicLoadObject(ObjectName, class'Texture', True));
}

function Created()
{
    NativeWindow = UWindowFramedWindow(OwnerWindow);
    MatchClient = UMenuBotmatchClientWindow(NativeWindow.ClientArea);
    NativeWindow.HideWindow();
    Super.Created();
    NextActionTime = UIClock+0.20;
    FocusWindow();
}

function AddControls(UWindowWindow W, int Nest)
{
    local UWindowWindow Child;
    local UWindowDialogControl Control;
    if(W == None || Nest > 16) return;
    for(Child = W.FirstChildWindow; Child != None; Child = Child.NextSiblingWindow)
    {
        Control = UWindowDialogControl(Child);
        if(UWindowComboControl(Control) != None || UWindowCheckbox(Control) != None ||
           UWindowHSliderControl(Control) != None || UWindowEditControl(Control) != None ||
           UWindowSmallButton(Control) != None)
        {
            if(Count < 510 && Control.Text != "") Controls[Count++] = Control;
        }
        else AddControls(Child, Nest+1);
    }
}

function BuildList()
{
    local int i, j;
    local UWindowList Item;
    local UWindowPageControlPage Tab;
    for(i = 0; i < 512; i++) { Entries[i] = None; Controls[i] = None; }
    Count = 0;
    PreviewRow = -1;
    if(MatchClient == None) return;
    if(Picker != None)
    {
        for(Item = Picker.List.Items.Next; Item != None && Count < 511; Item = Item.Next)
            Entries[Count++] = Item;
    }
    else if(SectionName == "")
    {
        for(Item = MatchClient.Pages.Items.Next; Item != None && Count < 508; Item = Item.Next)
            Entries[Count++] = Item;
        Controls[Count++] = MatchClient.StartButton;
        if(UTStartGameCW(MatchClient) != None)
            Controls[Count++] = UTStartGameCW(MatchClient).DedicatedButton;
    }
    else
    {
        Tab = MatchClient.Pages.GetPage(SectionName);
        if(Tab != None) AddControls(Tab.Page, 0);

    }
    Count++;
    Row = Clamp(Row, 0, Max(0, Count-1));
}

function string Caption(int Index)
{
    local UWindowDialogControl Control;
    local string Label, Value;
    if(Index == Count-1) return BackText;
    if(Picker != None)
        return UWindowComboListItem(Entries[Index]).Value;
    if(Entries[Index] != None)
        return UWindowPageControlPage(Entries[Index]).Caption;
    Control = Controls[Index];
    if(Control == None) return "";
    Label = RemoveAmpersand(Control.Text);
    if(UWindowComboControl(Control) != None)
        Value = UWindowComboControl(Control).GetValue();
    else if(UWindowCheckbox(Control) != None)
    {
        if(UWindowCheckbox(Control).bChecked) Value = EnabledText;
        else Value = DisabledText;
    }
    else if(UWindowHSliderControl(Control) != None)
        Value = string(int(UWindowHSliderControl(Control).Value));
    else if(UWindowEditControl(Control) != None)
        Value = UWindowEditControl(Control).EditBox.GetValue();
    if(Value != "") return Label@"  <"@Value@">";
    return Label;
}

function ChangeValue(int Direction)
{
    local UWindowComboControl Combo;
    local UWindowCheckbox Check;
    local UWindowHSliderControl Slider;
    local UWindowEditControl Edit;
    local int Index, Total;
    local UWindowList Item;
    if(Count == 0 || Picker != None) return;
    Combo = UWindowComboControl(Controls[Row]);
    Check = UWindowCheckbox(Controls[Row]);
    Slider = UWindowHSliderControl(Controls[Row]);
    Edit = UWindowEditControl(Controls[Row]);
    if(Combo != None)
    {
        for(Item = Combo.List.Items.Next; Item != None; Item = Item.Next) Total++;
        if(Total == 0) return;
        Index = Combo.GetSelectedIndex()+Direction;
        if(Index < 0) Index = Total-1;
        if(Index >= Total) Index = 0;
        Combo.SetSelectedIndex(Index);
    }
    else if(Check != None && !Check.bDisabled)
    {
        Check.bChecked = !Check.bChecked;
        Check.Notify(DE_Change);
    }
    else if(Slider != None)
        Slider.SetValue(Slider.Value+Direction*Max(1, Slider.Step));
    else if(Edit != None && Edit.EditBox.bCanEdit && Edit.EditBox.bNumericOnly && !Edit.EditBox.bNumericFloat)
    {
        Edit.SetValue(string(Max(0, int(Edit.EditBox.GetValue())+Direction)));
        Edit.Notify(DE_Change);
    }
    BuildList();
}

function ActivateRow()
{
    local UWindowDialogControl Control;
    local UWindowComboControl Combo;
    if(Count == 0 || bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True;
    NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(Picker != None)
    {
        Combo = Picker;
        Picker = None;
        Combo.SetSelectedIndex(Row);
        Row = 0; FirstRow = 0;
        BuildList();
        return;
    }
    if(Entries[Row] != None)
    {
        SectionName = UWindowPageControlPage(Entries[Row]).Caption;
        Row = 0; FirstRow = 0;
        BuildList();
        return;
    }
    Control = Controls[Row];
    if(UWindowComboControl(Control) != None)
    {
        Picker = UWindowComboControl(Control);
        bMapPicker = UMenuStartMatchClientWindow(Control.NotifyWindow) != None &&
            Control == UMenuStartMatchClientWindow(Control.NotifyWindow).MapCombo;
        PickerMapName = ""; PickerPicture = None;
        Row = Max(0, Picker.GetSelectedIndex()); FirstRow = 0;
        BuildList();
    }
    else if(UWindowCheckbox(Control) != None || UWindowHSliderControl(Control) != None)
        ChangeValue(1);
    else if(UWindowEditControl(Control) != None)
    {
        EditTarget = UWindowEditControl(Control);
        InputField = UWindowEditControl(CreateWindow(class'UWindowEditControl', MenuLeft, WinHeight*0.48, Width, 24));
        InputField.SetText(EditTarget.Text);
        InputField.SetFont(F_Large);
        InputField.SetValue(EditTarget.EditBox.GetValue());
        InputField.EditBox.MaxLength = EditTarget.EditBox.MaxLength;
        InputField.EditBox.bNumericOnly = EditTarget.EditBox.bNumericOnly;
        InputField.EditBox.bNumericFloat = EditTarget.EditBox.bNumericFloat;
        InputField.EditBox.ActivateWindow(0, False);
        GetPlayerOwner().ConsoleCommand("ANDROID_SHOW_KEYBOARD");
    }
    else if(UWindowButton(Control) != None && !UWindowButton(Control).bDisabled)
    {
        if(Control == MatchClient.StartButton ||
            (UTStartGameCW(MatchClient) != None && Control == UTStartGameCW(MatchClient).DedicatedButton))
            UT99ConsoleRoot(Root).ResetHome();
        Control.Notify(DE_Click);
        // StartPressed closes the backing window and launches the match.
        if(Control == MatchClient.StartButton ||
            (UTStartGameCW(MatchClient) != None && Control == UTStartGameCW(MatchClient).DedicatedButton))
            Super.Close(True);
    }
}

function bool HotKeyDown(int Key, float X, float Y)
{
    if(!bWindowVisible) return False;
    if(bPreviewMap)
    {
        if(Key == 0x0D || Key == 0xC9 || Key == 0x25 || Key == 0x08) bPreviewMap = False;
        return True;
    }
    if(InputField != None)
    {
        if(Key == 0xC9) { GoBack(); return True; }
        if(Key == 0x0D)
        {
            EditTarget.SetValue(InputField.EditBox.GetValue());
            EditTarget.Notify(DE_Change);
            InputField.Close(); InputField = None; EditTarget = None;
            GetPlayerOwner().ConsoleCommand("ANDROID_HIDE_KEYBOARD");
            FocusWindow();
            BuildList();
            return True;
        }
        return False;
    }
    if(Key == 0x25 || Key == 0x27)
    {
        if(Controls[Row] != None) ChangeValue(Key-0x26);
        else if(Key == 0x27) ActivateRow();
        else GoBack();
        return True;
    }
    return Super.HotKeyDown(Key, X, Y);
}

function GoBack()
{
    if(bPreviewMap)
        bPreviewMap = False;
    else if(InputField != None)
    {
        InputField.Close(); InputField = None; EditTarget = None;
        GetPlayerOwner().ConsoleCommand("ANDROID_HIDE_KEYBOARD");
        FocusWindow();
    }
    else if(Picker != None)
    {
        Picker = None; Row = 0; FirstRow = 0; BuildList();
    }
    else if(SectionName != "")
    {
        SectionName = ""; Row = 0; FirstRow = 0; BuildList();
    }
    else
    {
        NativeWindow.Close();
        Super.Close(True);
    }
}

function string GetLocation()
{
    local string S;
    S = Super.GetLocation();
    if(NativeWindow != None) S = S$" / "$RemoveAmpersand(NativeWindow.WindowTitle);
    if(SectionName != "") S = S$" / "$RemoveAmpersand(SectionName);
    if(Picker != None) S = S$" / "$RemoveAmpersand(Picker.Text);
    if(EditTarget != None) S = S$" / "$RemoveAmpersand(EditTarget.Text);
    return S;
}

function Paint(Canvas C, float X, float Y)
{
    local Texture Picture;
    local float W, H, TextW, TextH;
    local string MapCaption;
    if(InputField != None)
    {
        W = FMin(WinWidth*0.70, WinHeight*0.82);
        C.Style = 2;
        C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
        DrawStretchedTexture(C, (WinWidth-W)*0.5, WinHeight*0.02, W, W*0.5, Texture'UT99Logo');
        C.Style = 1;
        DrawLocation(C, WinHeight*0.35);
        C.Font = Root.Fonts[F_Normal];
        TextSize(C, EditHint, TextW, TextH);
        ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.94, EditHint);
        return;
    }
    if(Picker != None && bMapPicker) { PaintMapPicker(C); return; }
    if(!bPreviewMap) { Super.Paint(C, X, Y); return; }
    Picture = MatchClient.ScreenshotWindow.Screenshot;
    C.Style = 1;
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    C.bNoSmooth = True;
    if(Picture != None)
    {
        W = FMin(WinWidth*0.90, WinHeight*0.82*Picture.USize/Picture.VSize);
        H = W*Picture.VSize/Picture.USize;
        DrawStretchedTexture(C, (WinWidth-W)*0.5, WinHeight*0.03, W, H, Picture);
    }
    else
    {
        C.Font = MenuFont;
        TextSize(C, NoPreviewText, TextW, TextH);
        ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.45, NoPreviewText);
    }
    C.Font = MenuFont;
    MapCaption = MatchClient.ScreenshotWindow.MapTitle;
    if(MapCaption == "") MapCaption = MatchClient.Map;
    TextSize(C, MapCaption, TextW, TextH);
    ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.88, MapCaption);
    TextSize(C, BackText, TextW, TextH);
    ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.96, BackText);
    C.bNoSmooth = False;
}

function PaintMapPicker(Canvas C)
{
    local int i;
    local float YPos, TextW, TextH, PictureSize, PictureX, LogoW;
    local string S;
    LogoW = WinHeight*0.46;
    C.Style = 2;
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    DrawStretchedTexture(C, (WinWidth-LogoW)*0.5, -WinHeight*0.015, LogoW, LogoW*0.5, Texture'UT99Logo');
    C.Style = 1;
    DrawLocation(C, WinHeight*0.20);
    C.Font = MenuFont;
    for(i = FirstRow; i < Min(Count, FirstRow+VisibleRows); i++)
    {
        YPos = Top+(i-FirstRow)*RowHeight;
        if(i == Row)
        {
            C.DrawColor.R = 90; C.DrawColor.G = 15; C.DrawColor.B = 20;
            DrawStretchedTexture(C, MenuLeft, YPos, Width, RowHeight-2, Texture'UWindow.WhiteTexture');
            C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
            DrawStretchedTexture(C, MenuLeft, YPos, Width, 1, Texture'UWindow.WhiteTexture');
        }
        C.DrawColor.R = 225; C.DrawColor.G = 220; C.DrawColor.B = 205;
        if(i == Row) { C.DrawColor.R = 255; C.DrawColor.G = 208; C.DrawColor.B = 100; }
        S = Caption(i);
        TextSize(C, S, TextW, TextH);
        ClipText(C, MenuLeft+12, YPos+(RowHeight-TextH)*0.5, S);
    }
    PictureSize = FMin(WinWidth*0.40, WinHeight*PreviewHeight);
    PictureX = WinWidth*0.74-PictureSize*0.5;
    C.DrawColor.R = 230; C.DrawColor.G = 174; C.DrawColor.B = 66;
    DrawStretchedTexture(C, PictureX-2, WinHeight*0.28-2, PictureSize+4, PictureSize+4, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    if(PickerPicture != None)
    {
        C.bNoSmooth = True;
        DrawStretchedTexture(C, PictureX, WinHeight*0.28, PictureSize, PictureSize, PickerPicture);
        C.bNoSmooth = False;
    }
    else
    {
        C.DrawColor.R = 12; C.DrawColor.G = 14; C.DrawColor.B = 20;
        DrawStretchedTexture(C, PictureX, WinHeight*0.28, PictureSize, PictureSize, Texture'UWindow.WhiteTexture');
        C.Font = Root.Fonts[F_Normal];
        C.DrawColor.R = 225; C.DrawColor.G = 220; C.DrawColor.B = 205;
        TextSize(C, NoPreviewText, TextW, TextH);
        ClipText(C, WinWidth*0.74-TextW*0.5, WinHeight*0.55, NoPreviewText);
    }
    C.Font = MenuFont;
    C.DrawColor.R = 225; C.DrawColor.G = 220; C.DrawColor.B = 205;
    S = Left(PickerMapName, Max(0, Len(PickerMapName)-4));
    TextSize(C, S, TextW, TextH);
    ClipText(C, WinWidth*0.74-TextW*0.5, WinHeight*PreviewLabelY, S);
    C.Font = Root.Fonts[F_Normal];
    TextSize(C, MapPickerHint, TextW, TextH);
    ClipText(C, (WinWidth-TextW)*0.5, WinHeight*0.94, MapPickerHint);
    DrawScrollIndicator(C);
}

function LMouseDown(float X, float Y)
{
    if(bPreviewMap) { bPreviewMap = False; return; }
    Super.LMouseDown(X, Y);
}

defaultproperties
{
    EnabledText="ON"
    DisabledText="OFF"
    PreviewHeight=0.55
    PreviewLabelY=0.86
    PreviewText="VIEW MAP"
    NoPreviewText="This map has no preview image."
    MapPickerHint="UP/DOWN: preview   ENTER / A: select   ESC / B: back"
    EditHint="ENTER: save   ESC: cancel"
    HintText="UP/DOWN: select   LEFT/RIGHT: change   ENTER / A: open   ESC / B: back"
}
