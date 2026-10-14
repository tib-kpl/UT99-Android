// Keep UBrowser's discovery, ping, favourites and connection logic behind a pad UI.
class UT99ConsoleServers extends UT99ConsoleDialog;

var UBrowserMainClientWindow BrowserClient;
var UBrowserServerListWindow ServerPages[3], CurrentServers;
var UBrowserServerList SelectedServer;
var UWindowPageControlPage LANPage, InternetPage;
var int ServerMode, ServerCount;
var float RefreshClock, DiscoveryClock;
var bool bDiscoveryStopped;
var localized string LANText, InternetText, FavoritesText, AddressText;
var localized string RefreshText, JoinText, FavoriteText, EmptyText, SearchText;
var localized string LANHelp, InternetHelp;

function Created()
{
    local class<UBrowserServerListWindow> ListClass;
    local UMenuMultiplayerMenu M;
    Super.Created();
    bEmbedded = False;
    if(NativeHost != None) NativeHost.HideWindow();
    BrowserClient = UBrowserMainClientWindow(NativeWindow.ClientArea);
    ListClass = class<UBrowserServerListWindow>(DynamicLoadObject(BrowserClient.ServerListWindowClass, class'Class'));
    LANPage = BrowserClient.PageControl.AddPage(LANText, ListClass, 'UT99ConsoleLAN');
    InternetPage = BrowserClient.PageControl.AddPage(InternetText, ListClass, 'UT99ConsoleInternet');
    ServerPages[0] = UBrowserServerListWindow(LANPage.Page);
    ServerPages[1] = UBrowserServerListWindow(InternetPage.Page);
    ServerPages[2] = UBrowserServerListWindow(BrowserClient.Favorites.Page);
    ServerPages[0].ListFactories[0] = "UBrowser.UBrowserLocalFact,BeaconProduct=ut";
    ServerPages[0].URLAppend = "?LAN";
    ServerPages[1].ListFactories[0] = "UBrowser.UBrowserGSpyFact,MasterServerAddress=master.333networks.com,MasterServerTCPPort=28900,Region=0,GameName=ut";
    ServerPages[1].bFallbackFactories = False;
    ServerPages[0].AutoRefreshTime = 0; ServerPages[1].AutoRefreshTime = 0;
    ServerPages[0].bSuspendPingOnClose = False;
    ServerPages[1].bSuspendPingOnClose = False;
    ServerPages[2].bSuspendPingOnClose = False;
    M = UMenuMultiplayerMenu(UT99ConsoleRoot(Root).MenuBar.Multiplayer);
    ServerMode = 1;
    if(M != None && M.bOpenLAN) ServerMode = 0;
    SelectMode(ServerMode);
}

function SelectMode(int Mode)
{
    if(CurrentServers != None) CurrentServers.ShutdownFactories(False);
    ServerMode = Mode; SelectedServer = None; Row = 0; FirstRow = 0;
    CurrentServers = ServerPages[Mode];
    CurrentServers.bPingSuspend = False;
    CurrentServers.Refresh();
    RefreshClock = 0; DiscoveryClock = 0; bDiscoveryStopped = False;
    BuildList(); FocusWindow();
}

function Tick(float Delta)
{
    UIClock += Delta; bActionThisTick = False;
    RefreshClock += Delta;
    DiscoveryClock += Delta;
    if(ServerMode == 0 && !bDiscoveryStopped && DiscoveryClock > 6 && CurrentServers != None)
    {
        CurrentServers.ShutdownFactories(False);
        CurrentServers.PingState = PS_Done;
        bDiscoveryStopped = True;
    }
    if(bNativeClosed) { Finish(); return; }
    if(CurrentServers != None && CurrentServers.PingedList != None)
    {
        if(ServerMode >= 0) CurrentServers.ResumePinging();
        CurrentServers.Tick(Delta);
    }
    if(RefreshClock > 0.5) { RefreshClock = 0; BuildList(); }
}

function BuildList()
{
    local UBrowserServerList S;
    local int i;
    for(i = 0; i < 512; i++) Entries[i] = None;
    if(BrowserClient == None || bEmbedded) { Count = 1; return; }
    if(SelectedServer != None) { Count = 4; return; }
    if(ServerMode < 0) { Count = 7; return; }
    ServerCount = 0;
    if(CurrentServers.PingedList != None)
        for(S = UBrowserServerList(CurrentServers.PingedList.Next); S != None && ServerCount < 500; S = UBrowserServerList(S.Next))
            Entries[ServerCount++] = S;
    if(CurrentServers.UnpingedList != None)
        for(S = UBrowserServerList(CurrentServers.UnpingedList.Next); S != None && ServerCount < 500; S = UBrowserServerList(S.Next))
            Entries[ServerCount++] = S;
    Count = Max(1, ServerCount)+4;
    Row = Clamp(Row, 0, Count-1);
}

function string Caption(int Index)
{
    local UBrowserServerList S;
    local string Name;
    if(Index == Count-1) return BackText;
    if(SelectedServer != None)
    {
        if(Index == 0) return JoinText;
        if(Index == 1) return FavoriteText;
        return RefreshText;
    }
    if(ServerMode < 0)
    {
        if(Index == 0) return LANText;
        if(Index == 1) return InternetText;
        if(Index == 2) return FavoritesText;
        if(Index == 3) return AddressText;
        if(Index == 4) return BrowserClient.MOTDName;
        return BrowserClient.IRCName;
    }
    if(Index == Count-2) return AddressText;
    if(Index == Count-3) return RefreshText;
    if(Index == Count-4) return FavoritesText$" / "$BrowserClient.MOTDName$" / "$BrowserClient.IRCName;
    if(ServerCount == 0)
    {
        if(ServerMode == 0 && !bDiscoveryStopped) return SearchText;
        if(CurrentServers.PingState == PS_QueryServer || CurrentServers.PingState == PS_Pinging) return SearchText;
        return EmptyText;
    }
    S = UBrowserServerList(Entries[Index]);
    Name = S.HostName; if(Name == "") Name = S.IP;
    return Name$"  ("$S.NumPlayers$"/"$S.MaxPlayers$")  "$S.MapName;
}

function string GetLocation()
{
    local string S;
    S = UT99ConsoleHome(PreviousScreen).GetLocation();
    if(ServerMode == 0) S = S$" / "$LANText;
    else if(ServerMode == 1) S = S$" / "$InternetText;
    else if(ServerMode == 2) S = S$" / "$FavoritesText;
    else S = S$" / "$FavoritesText$" / "$BrowserClient.MOTDName$" / "$BrowserClient.IRCName;
    if(SelectedServer != None) S = S$" / "$SelectedServer.HostName;
    return S;
}

function BeforePaint(Canvas C, float X, float Y)
{
    if(bEmbedded) { Super.BeforePaint(C, X, Y); return; }
    Super(UT99ConsoleHome).BeforePaint(C, X, Y);
    if(Notice == None) return;
    Notice.Text = "";
    if(SelectedServer != None)
        Notice.Text = SelectedServer.GameType$" / "$SelectedServer.MapTitle$"\n"$SelectedServer.IP$":"$SelectedServer.GamePort$"   Ping : "$int(SelectedServer.Ping)$" ms";
    else if(ServerMode == 0) Notice.Text = LANHelp;
    else if(ServerMode == 1) Notice.Text = InternetHelp;
    Notice.WinTop = WinHeight*0.85; Notice.WinHeight = WinHeight*0.08;
}

function ActivateRow()
{
    if(bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True; NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(SelectedServer != None)
    {
        if(Row == 0)
        {
            if(SelectedServer.GamePort == 0) SelectedServer.GamePort = Max(1, SelectedServer.QueryPort-1);
            NativeWindow.SetParent(NativeParent);
            CurrentServers.Grid.JoinServer(SelectedServer);
            Finish();
        }
        else if(Row == 1) UBrowserFavoriteServers(ServerPages[2]).AddFavorite(SelectedServer);
        else { SelectMode(ServerMode); }
        return;
    }
    if(ServerMode < 0)
    {
        if(Row < 3) { SelectMode(Row); return; }
        if(Row == 3) UBrowserMainWindow(NativeWindow).ShowOpenWindow();
        else
        {
            // News and IRC keep their complete native controls in a separate frame.
            if(Row == 4) BrowserClient.PageControl.GotoTab(BrowserClient.MOTD, True);
            else BrowserClient.PageControl.GotoTab(BrowserClient.IRC, True);
            bEmbedded = True; Count = 1;
            NativeHost.ShowWindow(); NativeWindow.ShowWindow();
        }
        return;
    }
    if(Row == Count-2) { UBrowserMainWindow(NativeWindow).ShowOpenWindow(); return; }
    if(Row == Count-3) { SelectMode(ServerMode); return; }
    if(Row == Count-4)
    {
        CurrentServers.ShutdownFactories(False);
        ServerMode = -1; Row = 0; FirstRow = 0; BuildList(); return;
    }
    if(ServerCount == 0) return;
    SelectedServer = UBrowserServerList(Entries[Row]);
    Row = 0; FirstRow = 0; BuildList();
}

function GoBack()
{
    if(bEmbedded)
    {
        NativeWindow.HideWindow(); NativeHost.HideWindow(); bEmbedded = False;
        ServerMode = -1; BuildList(); return;
    }
    if(SelectedServer != None) { SelectedServer = None; Row = 0; BuildList(); return; }
    if(ServerMode >= 0)
    {
        CurrentServers.ShutdownFactories(False);
    }
    NativeWindow.SetParent(NativeParent);
    Super.GoBack();
}

function Paint(Canvas C, float X, float Y)
{
    if(bEmbedded) Super.Paint(C, X, Y);
    else Super(UT99ConsoleHome).Paint(C, X, Y);
}

function CloseForResume()
{
    NativeWindow.SetParent(NativeParent);
    Super.CloseForResume();
}

defaultproperties
{
    LANText="LAN GAMES"
    InternetText="INTERNET GAMES"
    FavoritesText="FAVOURITE SERVERS"
    AddressText="JOIN BY SERVER ADDRESS"
    RefreshText="REFRESH SERVER LIST"
    JoinText="JOIN GAME"
    FavoriteText="ADD TO FAVOURITES"
    EmptyText="NO SERVERS FOUND"
    SearchText="SEARCHING FOR SERVERS..."
    LANHelp="Servers on your local network. Start a multiplayer game on the host, then refresh."
    InternetHelp="Choose a server, then join. Refresh to search again."
    ServerMode=-1
}
