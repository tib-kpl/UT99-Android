// Keep the original UT menu objects: game types, mods and campaign own their actions.
class UT99ConsoleRoot extends UMenuRootWindow;

var UT99ConsoleHome Home;
var Texture Backdrop[12];
var UT99ConsoleMatch MatchScreen;
var UT99ConsoleLists ListsScreen;
var Texture MapBackdrop;
var string BackdropMapName;
var bool bLoggedGameplayMenu;
var UT99ConsoleCampaign CampaignScreen;

function bool IsGameplayMenu()
{
    local string MapURL;
    if(Console.bLocked || Console.bQuickKeyEnable) return False;
    MapURL = GetLevel().GetLocalURL();
    if(Left(MapURL, 5) ~= "Entry" || Left(MapURL, 9) ~= "CityIntro" ||
       Left(MapURL, 11) ~= "UT-Logo-Map" || Left(MapURL, 9) ~= "UTCredits")
        return False;
    if(GetLevel().Game != None && GetLevel().Game.IsA('UTIntro')) return False;
    return True;
}

function ResetHome()
{
    Home.Page = None;
    Home.Depth = 0;
    Home.Row = 0;
    Home.FirstRow = 0;
    Home.BuildList();
}

// Called by the native Start queue, separately from Escape / B navigation.
function bool HandleStartButton()
{
    if(!IsGameplayMenu()) return False;
    if(!Console.bUWindowActive)
    {
        ResetHome();
        MenuBar.CloseUp();
        return False;
    }
    GetPlayerOwner().ConsoleCommand("ANDROID_HIDE_KEYBOARD");
    if(ListsScreen != None && ListsScreen.bWindowVisible)
    {
        ListsScreen.NativeWindow.Close();
        ListsScreen.Close(True);
        MatchScreen.NativeWindow.Close();
        MatchScreen.Close(True);
    }
    else if(MatchScreen != None && MatchScreen.bWindowVisible)
    {
        MatchScreen.NativeWindow.Close();
        MatchScreen.Close(True);
    }
    ResetHome();
    MenuBar.CloseUp();
    Console.CloseUWindow();
    bLoggedGameplayMenu = False;
    return True;
}

function ChooseMapBackdrop()
{
    local string FirstMap, NextMap, MapNames[256], ObjectName;
    local int Total, i, Pick;
    FirstMap = GetPlayerOwner().GetMapName("", "", 0);
    NextMap = FirstMap;
    while(NextMap != "" && Total < 256)
    {
        if(Left(NextMap, 3) ~= "DM-" || Left(NextMap, 4) ~= "CTF-" ||
           Left(NextMap, 4) ~= "DOM-" || Left(NextMap, 3) ~= "AS-")
            MapNames[Total++] = NextMap;
        NextMap = GetPlayerOwner().GetMapName("", NextMap, 1);
        if(NextMap ~= FirstMap) break;
    }
    for(i = 0; i < Min(Total, 8); i++)
    {
        Pick = Rand(Total);
        BackdropMapName = Left(MapNames[Pick], Len(MapNames[Pick])-4);
        ObjectName = BackdropMapName$".Screenshot";
        MapBackdrop = Texture(DynamicLoadObject(ObjectName, class'Texture', True));
        if(MapBackdrop != None) return;
    }
    BackdropMapName = "";
}

function Created()
{
    Super.Created();
    ChooseMapBackdrop();
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
    if(MatchScreen != None)
        MatchScreen.SetSize(WinWidth, WinHeight);
    if(ListsScreen != None)
        ListsScreen.SetSize(WinWidth, WinHeight);
    if(CampaignScreen != None)
        CampaignScreen.SetSize(WinWidth, WinHeight);
}

function bool HasDialog()
{
    local UWindowWindow W;
    for(W = FirstChildWindow; W != None; W = W.NextSiblingWindow)
        if(W != Home && W != MenuBar && W != StatusBar && W.bWindowVisible)
        {
            if(Home.bWindowVisible) Log("UT99Console dialog:"@W.Class);
            return True;
        }
    return False;
}

function Tick(float Delta)
{
    local UMenuBotmatchWindow MatchWindow;
    local UWindowFramedWindow ListWindow;
    local UWindowWindow CampaignWindow;
    Super.Tick(Delta);
    if(IsGameplayMenu())
    {
        Console.bNoDrawWorld = False;
        if(!bLoggedGameplayMenu)
        {
            Log("UT99Console gameplay menu mode="@GetLevel().NetMode@"pauser="@GetLevel().Pauser);
            bLoggedGameplayMenu = True;
        }
    }
    else bLoggedGameplayMenu = False;
    if(Home == None)
        return;
    Home.bActionThisTick = False;
    Home.UIClock += Delta;
    if(MatchScreen != None)
    {
        MatchScreen.bActionThisTick = False;
        MatchScreen.UIClock += Delta;
    }
    if(ListsScreen != None)
    {
        ListsScreen.bActionThisTick = False;
        ListsScreen.UIClock += Delta;
    }
    CampaignWindow = FindChildWindow(class'NewCharacterWindow');
    if(CampaignWindow == None || !CampaignWindow.bWindowVisible) CampaignWindow = FindChildWindow(class'ManagerWindow');
    if(CampaignWindow == None || !CampaignWindow.bWindowVisible) CampaignWindow = FindChildWindow(class'UTLadder');
    if(CampaignWindow != None && CampaignWindow.bWindowVisible)
    {
        if(CampaignScreen != None) CampaignScreen.HideWindow();
        CampaignScreen = UT99ConsoleCampaign(CreateWindow(class'UT99ConsoleCampaign', 0, 0, WinWidth, WinHeight, CampaignWindow));
        MenuBar.HideWindow();
    }
    MatchWindow = UMenuBotmatchWindow(FindChildWindow(class'UMenuBotmatchWindow'));
    if(MatchWindow != None && MatchWindow.bWindowVisible && !Console.bLocked)
    {
        MatchScreen = UT99ConsoleMatch(CreateWindow(class'UT99ConsoleMatch', 0, 0, WinWidth, WinHeight, MatchWindow));
        MatchScreen.FocusWindow();
    }
    if(MatchScreen != None && MatchScreen.bWindowVisible)
    {
        ListWindow = UWindowFramedWindow(FindChildWindow(class'UMenuMapListWindow'));
        if(ListWindow == None || !ListWindow.bWindowVisible)
            ListWindow = UWindowFramedWindow(FindChildWindow(class'UMenuMutatorWindow'));
        if(ListWindow != None && ListWindow.bWindowVisible)
            ListsScreen = UT99ConsoleLists(CreateWindow(class'UT99ConsoleLists', 0, 0, WinWidth, WinHeight, ListWindow));
    }
    if(HasDialog() || Console.bQuickKeyEnable || Console.bLocked)
    {
        if(Home.bWindowVisible)
        {
            Log("UT99Console hiding home; quick="@Console.bQuickKeyEnable@"locked="@Console.bLocked);
            Home.HideWindow();
            if(!Console.bQuickKeyEnable && !Console.bLocked &&
                (MatchScreen == None || !MatchScreen.bWindowVisible))
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
    local Texture Background;
    local float CropHeight;
    if(Console.bQuickKeyEnable)
        return;
    if(IsGameplayMenu() && (MatchScreen == None || !MatchScreen.bPreviewMap))
    {
        if(InStr(GetPlayerOwner().ConsoleCommand("ANDROID_MENU_BLUR"), "1") != -1) return;
        // Dim fallback for renderers without the Android blur command.
        C.Style = 4;
        C.DrawColor.R = 80; C.DrawColor.G = 80; C.DrawColor.B = 80;
        DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UWindow.WhiteTexture');
        C.Style = 1;
        C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
        return;
    }
    // UT's own tiled logo, tinted burgundy over a charcoal desktop.
    C.DrawColor.R = 12;
    C.DrawColor.G = 14;
    C.DrawColor.B = 20;
    DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UWindow.WhiteTexture');
    if(MatchScreen != None && MatchScreen.bPreviewMap) return;
    Background = MapBackdrop;
    if(MatchScreen != None && MatchScreen.bWindowVisible && MatchScreen.MatchClient != None)
        Background = MatchScreen.MatchClient.ScreenshotWindow.Screenshot;
    if(Background != None)
    {
        C.DrawColor.R = 105; C.DrawColor.G = 90; C.DrawColor.B = 90;
        CropHeight = Background.USize*WinHeight/WinWidth;
        DrawStretchedTextureSegment(C, 0, 0, WinWidth, WinHeight, 0,
            (Background.VSize-CropHeight)*0.5, Background.USize, CropHeight, Background);
        C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
        return;
    }
    C.DrawColor.R = 40;
    C.DrawColor.G = 22;
    C.DrawColor.B = 24;
    for(i = 0; i < 12; i++)
        DrawStretchedTexture(C, (i%4)*WinWidth*0.25,
            (WinHeight-WinWidth*0.75)*0.5 + (i/4)*WinWidth*0.25, WinWidth*0.25, WinWidth*0.25,
            Backdrop[i]);
    C.DrawColor.R = 255;
    C.DrawColor.G = 255;
    C.DrawColor.B = 255;
}

function CloseActiveWindow()
{
    if(CampaignScreen != None && CampaignScreen.bWindowVisible)
        CampaignScreen.GoBack();
    else if(ListsScreen != None && ListsScreen.bWindowVisible)
        ListsScreen.GoBack();
    else if(MatchScreen != None && MatchScreen.bWindowVisible)
        MatchScreen.GoBack();
    else if(Home != None && Home.bWindowVisible)
        Home.GoBack();
    else
        Super.CloseActiveWindow();
}

defaultproperties
{
    LookAndFeelClass="UMenu.UMenuGoldLookAndFeel"
    Backdrop(0)=Texture'UMenu.Icons.Bg11'
    Backdrop(1)=Texture'UMenu.Icons.Bg21'
    Backdrop(2)=Texture'UMenu.Icons.Bg31'
    Backdrop(3)=Texture'UMenu.Icons.Bg41'
    Backdrop(4)=Texture'UMenu.Icons.Bg12'
    Backdrop(5)=Texture'UMenu.Icons.Bg22'
    Backdrop(6)=Texture'UMenu.Icons.Bg32'
    Backdrop(7)=Texture'UMenu.Icons.Bg42'
    Backdrop(8)=Texture'UMenu.Icons.Bg13'
    Backdrop(9)=Texture'UMenu.Icons.Bg23'
    Backdrop(10)=Texture'UMenu.Icons.Bg33'
    Backdrop(11)=Texture'UMenu.Icons.Bg43'
}
