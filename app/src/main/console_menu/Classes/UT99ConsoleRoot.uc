// Keep the original UT menu objects: game types, mods and campaign own their actions.
class UT99ConsoleRoot extends UMenuRootWindow;

var UT99ConsoleHome Home;
var Texture Backdrop[12];

function Created()
{
    local int i;
    Super.Created();
    for(i = 0; i < 12; i++)
        Backdrop[i] = Texture(DynamicLoadObject("UMenu.Icons.Bg"$string(i%4+1)$string(i/4+1), class'Texture'));
    MenuBar.bShowMenu = False;
    MenuBar.CloseUp();
    MenuBar.HideWindow();
    Home = UT99ConsoleHome(CreateWindow(class'UT99ConsoleHome', 0, 0, WinWidth, WinHeight));
    Home.FocusWindow();
}

function Resized()
{
    Super.Resized();
    if(Home != None)
        Home.SetSize(WinWidth, WinHeight);
}

function bool HasDialog()
{
    local UWindowWindow W;
    for(W = FirstChildWindow; W != None; W = W.NextSiblingWindow)
        if(W != Home && W != MenuBar && W != StatusBar && W.bWindowVisible)
            return True;
    return False;
}

function Tick(float Delta)
{
    Super.Tick(Delta);
    if(Home == None)
        return;
    Home.bActionThisTick = False;
    if(HasDialog() || Console.bQuickKeyEnable || Console.bLocked)
    {
        if(Home.bWindowVisible)
        {
            Home.HideWindow();
            if(!Console.bQuickKeyEnable && !Console.bLocked)
                MenuBar.ShowWindow();
        }
    }
    else if(!Home.bWindowVisible)
    {
        MenuBar.CloseUp();
        MenuBar.HideWindow();
        Home.ShowWindow();
        Home.FocusWindow();
    }
}

function Paint(Canvas C, float X, float Y)
{
    local int i;
    if(Console.bQuickKeyEnable)
        return;
    // UT's own tiled logo, tinted burgundy over a charcoal desktop.
    C.DrawColor.R = 12;
    C.DrawColor.G = 14;
    C.DrawColor.B = 20;
    DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UWindow.WhiteTexture');
    C.DrawColor.R = 70;
    C.DrawColor.G = 24;
    C.DrawColor.B = 28;
    for(i = 0; i < 12; i++)
        DrawStretchedTexture(C, WinWidth*0.45 + (i%4)*WinHeight*0.16,
            WinHeight*0.24 + (i/4)*WinHeight*0.16, WinHeight*0.16, WinHeight*0.16,
            Backdrop[i]);
    C.DrawColor.R = 255;
    C.DrawColor.G = 255;
    C.DrawColor.B = 255;
}

function CloseActiveWindow()
{
    if(Home != None && Home.bWindowVisible)
        Home.GoBack();
    else
        Super.CloseActiveWindow();
}

defaultproperties
{
    LookAndFeelClass="UMenu.UMenuGoldLookAndFeel"
}
