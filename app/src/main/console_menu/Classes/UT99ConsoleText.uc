class UT99ConsoleText extends UWindowWindow;
var string Text;
function Paint(Canvas C, float X, float Y)
{
    C.Font = Root.Fonts[F_Normal];
    C.DrawColor.R = 225; C.DrawColor.G = 210; C.DrawColor.B = 175;
    WrapClipText(C, 0, 0, Text);
}
function bool CheckMousePassThrough(float X, float Y)
{
    return True;
}
