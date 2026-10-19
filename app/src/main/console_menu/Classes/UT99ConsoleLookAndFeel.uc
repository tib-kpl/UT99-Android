// Flat console-style edit boxes, combos and buttons that match the menu rows,
// instead of the bevelled desktop controls of the gold look.
class UT99ConsoleLookAndFeel extends UMenuGoldLookAndFeel;

function DrawPanel(UWindowWindow W, Canvas C, float X, float Y, float PW, float PH, bool bActive)
{
    C.Style = 1;
    // Gold outline, brighter on the focused control.
    if(bActive) { C.DrawColor.R = 255; C.DrawColor.G = 209; C.DrawColor.B = 106; }
    else { C.DrawColor.R = 190; C.DrawColor.G = 130; C.DrawColor.B = 48; }
    W.DrawStretchedTexture(C, X, Y, PW, PH, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 24; C.DrawColor.G = 17; C.DrawColor.B = 18;
    W.DrawStretchedTexture(C, X+1, Y+1, PW-2, PH-2, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
}

function DrawLabel(UWindowDialogControl W, Canvas C, float X, float Y, string Text)
{
    if(Text == "") return;
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    W.ClipText(C, X, Y, Text);
}

function WhiteText(UWindowDialogControl W)
{
    W.TextColor.R = 255; W.TextColor.G = 255; W.TextColor.B = 255;
}

function Editbox_Draw(UWindowEditControl W, Canvas C)
{
    WhiteText(W.EditBox);
    DrawPanel(W, C, W.EditAreaDrawX, 0, W.EditBoxWidth, W.WinHeight, W.EditBox.bHasKeyboardFocus);
    DrawLabel(W, C, W.TextX, W.TextY, W.Text);
}

function Combo_Draw(UWindowComboControl W, Canvas C)
{
    WhiteText(W.EditBox);
    DrawPanel(W, C, W.EditAreaDrawX, 0, W.EditBoxWidth, W.WinHeight, W.EditBox.bHasKeyboardFocus || W.bListVisible);
    DrawLabel(W, C, W.TextX, W.TextY, W.Text);
}

function Button_DrawSmallButton(UWindowSmallButton B, Canvas C)
{
    C.Style = 1;
    if(B.bDisabled || !B.IsActive())
    {
        C.DrawColor.R = 70; C.DrawColor.G = 62; C.DrawColor.B = 60;
        B.DrawStretchedTexture(C, 0, 0, B.WinWidth, B.WinHeight, Texture'UWindow.WhiteTexture');
        C.DrawColor.R = 38; C.DrawColor.G = 33; C.DrawColor.B = 33;
        B.TextColor.R = 140; B.TextColor.G = 132; B.TextColor.B = 128;
    }
    else
    {
        C.DrawColor.R = 190; C.DrawColor.G = 130; C.DrawColor.B = 48;
        if(B.bMouseDown) { C.DrawColor.R = 255; C.DrawColor.G = 209; C.DrawColor.B = 106; }
        B.DrawStretchedTexture(C, 0, 0, B.WinWidth, B.WinHeight, Texture'UWindow.WhiteTexture');
        C.DrawColor.R = 91; C.DrawColor.G = 24; C.DrawColor.B = 25;
        if(B.bMouseDown) { C.DrawColor.R = 130; C.DrawColor.G = 36; C.DrawColor.B = 36; }
        B.TextColor.R = 255; B.TextColor.G = 230; B.TextColor.B = 170;
    }
    B.DrawStretchedTexture(C, 1, 1, B.WinWidth-2, B.WinHeight-2, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
}
