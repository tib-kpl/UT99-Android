class UT99ConsoleText extends UWindowWindow;
var string Text;
var bool bScrollable, bDragging;
var int ScrollLines, MaxScrollLines;
function Paint(Canvas C, float X, float Y)
{
    local float SavedHeight, W, H, ThumbH;
    local int Lines;
    C.Font = Root.Fonts[F_Normal];
    C.DrawColor.R = 225; C.DrawColor.G = 210; C.DrawColor.B = 175;
    if(!bScrollable) { WrapClipText(C, 0, 0, Text); return; }
    TextSize(C, "A", W, H);
    SavedHeight = WinHeight; WinHeight = 100000;
    Lines = WrapClipText(C, 0, 0, Text, False, 0, 0, True);
    WinHeight = SavedHeight;
    MaxScrollLines = Max(0, Lines-int(WinHeight/FMax(1, H)));
    ScrollLines = Clamp(ScrollLines, 0, MaxScrollLines);
    WrapClipText(C, 0, -ScrollLines*H, Text);
    if(MaxScrollLines == 0) return;
    ThumbH = FMax(12, WinHeight*WinHeight/(Lines*H));
    C.DrawColor.R = 170; C.DrawColor.G = 125; C.DrawColor.B = 60;
    DrawStretchedTexture(C, WinWidth-6, (WinHeight-ThumbH)*ScrollLines/MaxScrollLines, 4, ThumbH, Texture'UWindow.WhiteTexture');
}
function bool CheckMousePassThrough(float X, float Y)
{
    return !bScrollable;
}

function LMouseDown(float X, float Y)
{
    if(!bScrollable || MaxScrollLines == 0) return;
    bDragging = True; Root.CaptureMouse(Self); MouseMove(X, Y);
}
function MouseMove(float X, float Y)
{
    if(bDragging) ScrollLines = Clamp(int(Y*MaxScrollLines/FMax(1, WinHeight)), 0, MaxScrollLines);
}
function LMouseUp(float X, float Y)
{
    bDragging = False; Root.CancelCapture();
}
