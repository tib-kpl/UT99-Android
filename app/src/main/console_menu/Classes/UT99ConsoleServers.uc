// Keep UBrowser's discovery, ping, favourites and connection logic behind a pad UI.
class UT99ConsoleServers extends UT99ConsoleDialog;

var UBrowserMainClientWindow BrowserClient;
var UBrowserServerListWindow ServerPages[3], CurrentServers;
var UBrowserServerList SelectedServer;
var UWindowPageControlPage LANPage, InternetPage;
var int ServerMode, ServerCount;
var int ServerPage, TotalServers, SortMode;
var int EmbeddedReturnMode;
var bool bServerDetails;
var bool bStatusRequested;
var float RefreshClock, DiscoveryClock;
var bool bDiscoveryStopped;
var localized string LANText, InternetText, FavoritesText, AddressText;
var localized string RefreshText, JoinText, FavoriteText, EmptyText, SearchText;
var localized string LANHelp, InternetHelp;
var localized string InfoText, CopyText, PingServerText, PingAllText, RemoveFavoriteText;
var localized string EditFavoriteText, NewFavoriteText, NextPageText, PreviousPageText, SortText;
var localized string PlayersText, RulesText, FailedText, PendingText;
var localized string IncompatibleText;
var localized string AdvancedText;
var localized string ListOptionsText, SearchServersText, PageHintText;
var bool bListOptions;
var UWindowEditControl SearchProxy;
var string SearchTerm;

function Created()
{
    local class<UBrowserServerListWindow> ListClass;
    local UMenuMultiplayerMenu M;
    Super.Created();
    bEmbedded = False;
    if(NativeHost != None) NativeHost.HideWindow();
    BrowserClient = UBrowserMainClientWindow(NativeWindow.ClientArea);
    ListClass = class'UT99ConsoleServerListWindow';
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
    SearchProxy = UWindowEditControl(CreateWindow(class'UWindowEditControl', 0, 0, 1, 1));
    SearchProxy.SetText(SearchServersText); SearchProxy.EditBox.MaxLength = 100; SearchProxy.HideWindow();
}

function SelectMode(int Mode)
{
    if(CurrentServers != None) CurrentServers.ShutdownFactories(False);
    ServerMode = Mode; SelectedServer = None; Row = 0; FirstRow = 0; ServerPage = 0; bListOptions = False;
    CurrentServers = ServerPages[Mode];
    if(Mode < 2)
    {
        CurrentServers.bNoAutoSort = False;
        ApplyServerSort();
    }
    CurrentServers.bPingSuspend = False;
    CurrentServers.Refresh();
    RefreshClock = 0; DiscoveryClock = 0; bDiscoveryStopped = False;
    BuildList(); FocusWindow();
}

function Finish()
{
    local int i;
    for(i = 0; i < 3; i++)
        if(ServerPages[i] != None)
        {
            ServerPages[i].bPingSuspend = True;
            ServerPages[i].ShutdownFactories(False);
        }
    Super.Finish();
}

function Tick(float Delta)
{
    if(!bWindowVisible) return;
    UIClock += Delta; bActionThisTick = False;
    if(SearchProxy != None && InputField == None && SearchTerm != SearchProxy.GetValue())
    { SearchTerm = SearchProxy.GetValue(); ServerPage = 0; Row = 0; FirstRow = 0; BuildList(); }
    RefreshClock += Delta;
    DiscoveryClock += Delta;
    if(ServerMode == 0 && !bDiscoveryStopped && DiscoveryClock > 6 && CurrentServers != None)
    {
        CurrentServers.ShutdownFactories(False);
        CurrentServers.PingState = PS_Done;
        bDiscoveryStopped = True;
    }
    if(bNativeClosed) { Finish(); return; }
    if(bServerDetails && !bStatusRequested && SelectedServer != None && !SelectedServer.bPinging)
    { SelectedServer.ServerStatus(); bStatusRequested = True; }
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
    local UWindowList Item;
    local int i, Offset;
    for(i = 0; i < 512; i++) Entries[i] = None;
    if(BrowserClient == None || bEmbedded) { Count = 1; return; }
    if(InputField != None) { Count = 1; return; }
    if(SelectedServer != None)
    {
        if(!bServerDetails) { Count = 10; return; }
        Count = 0;
        if(SelectedServer.PlayerList != None)
            for(Item = SelectedServer.PlayerList.Next; Item != None && Count < 250; Item = Item.Next) Entries[Count++] = Item;
        if(SelectedServer.RulesList != None)
            for(Item = SelectedServer.RulesList.Next; Item != None && Count < 500; Item = Item.Next) Entries[Count++] = Item;
        Count++; Row = Clamp(Row, 0, Count-1); return;
    }
    if(ServerMode < 0) { Count = 7; return; }
    if(bListOptions) { Count = 9; return; }
    ServerCount = 0;
    TotalServers = 0; Offset = ServerPage*10;
    if(CurrentServers.PingedList != None)
        for(S = UBrowserServerList(CurrentServers.PingedList.Next); S != None; S = UBrowserServerList(S.Next))
        {
            if(!MatchesSearch(S)) continue;
            if(TotalServers >= Offset && ServerCount < 10) Entries[ServerCount++] = S;
            TotalServers++;
        }
    if(CurrentServers.UnpingedList != None)
        for(S = UBrowserServerList(CurrentServers.UnpingedList.Next); S != None; S = UBrowserServerList(S.Next))
        {
            if(!MatchesSearch(S)) continue;
            if(TotalServers >= Offset && ServerCount < 10) Entries[ServerCount++] = S;
            TotalServers++;
        }
    if(ServerPage > 0 && Offset >= TotalServers) { ServerPage--; BuildList(); return; }
    Count = Max(1, ServerCount)+4;
    Row = Clamp(Row, 0, Count-1);
}

function bool MatchesSearch(UBrowserServerList S)
{
    return SearchTerm == "" || InStr(Caps(S.HostName$" "$S.MapName$" "$S.GameType$" "$S.IP), Caps(SearchTerm)) >= 0;
}

function string Caption(int Index)
{
    local UBrowserServerList S;
    local string Name;
    local UBrowserPlayerList P;
    local UBrowserRulesList R;
    if(Index == Count-1) return BackText;
    if(SelectedServer != None)
    {
        if(bServerDetails)
        {
            P = UBrowserPlayerList(Entries[Index]); R = UBrowserRulesList(Entries[Index]);
            if(P != None) return PlayersText$" : "$P.PlayerName$" / "$P.PlayerFrags$" / "$P.PlayerPing$" ms";
            if(R != None) return R.Rule$" : "$R.Value;
            return SearchText;
        }
        if(Index == 0)
        {
            if(SelectedServer.MinNetVer > UT99ConsoleRoot(Root).ClientNetworkVersion) return IncompatibleText$" "$SelectedServer.MinNetVer;
            return JoinText;
        }
        if(Index == 1) { if(ServerMode == 2) return RemoveFavoriteText; return FavoriteText; }
        if(Index == 2) return InfoText;
        if(Index == 3) return CopyText;
        if(Index == 4) return PingServerText;
        if(Index == 5) return PingAllText;
        if(Index == 6) return RefreshText;
        if(Index == 7) { if(ServerMode == 2) return EditFavoriteText; return AddressText; }
        return NewFavoriteText;
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
    if(!bListOptions)
    {
        if(Index == Count-2) return ListOptionsText;
        if(Index == Count-3) return SearchServersText$" : "$SearchTerm;
        if(Index == Count-4) return PreviousPageText$"    < "$(ServerPage+1)$" / "$Max(1, (TotalServers+9)/10)$" >    "$NextPageText;
    }
    else
    {
    if(Index == Count-2) return AddressText;
    if(Index == Count-3) return RefreshText;
    if(Index == Count-4) return FavoritesText$" / "$BrowserClient.MOTDName$" / "$BrowserClient.IRCName;
    if(Index == Count-5) return NewFavoriteText;
    if(Index == Count-6) return SortText$" : "$SortModeName();
    if(Index == Count-7) return NextPageText;
    if(Index == Count-8) return PreviousPageText;
    if(Index == Count-9) return AdvancedText;
    }
    if(ServerCount == 0)
    {
        if(ServerMode == 0 && !bDiscoveryStopped) return SearchText;
        if(CurrentServers.PingState == PS_QueryServer || CurrentServers.PingState == PS_Pinging) return SearchText;
        return EmptyText;
    }
    S = UBrowserServerList(Entries[Index]);
    Name = S.HostName; if(Name == "") Name = S.IP;
    if(S.bPingFailed) return Name$" / "$FailedText;
    if(!S.bPinged) return Name$" / "$PendingText;
    return Name$"  ("$S.NumPlayers$"/"$S.MaxPlayers$")  "$S.MapName;
}

function string SortModeName()
{
    if(SortMode == 1) return CurrentServers.Grid.PingName;
    if(SortMode == 2) return CurrentServers.Grid.MapNameName;
    if(SortMode == 3) return CurrentServers.Grid.PlayersName;
    return CurrentServers.Grid.ServerName;
}

function ApplyServerSort()
{
    if(SortMode == 0) CurrentServers.Grid.SortByColumn = CurrentServers.Grid.Server;
    else if(SortMode == 1) CurrentServers.Grid.SortByColumn = CurrentServers.Grid.Ping;
    else if(SortMode == 2) CurrentServers.Grid.SortByColumn = CurrentServers.Grid.MapName;
    else CurrentServers.Grid.SortByColumn = CurrentServers.Grid.Players;
    CurrentServers.Grid.bSortDescending = False;
    if(CurrentServers.PingedList != None) CurrentServers.PingedList.Sort();
}

function OpenFavorite(bool bEdit)
{
    local UBrowserFavoritesMenu M;
    M = UBrowserFavoritesMenu(ServerPages[2].Grid.Menu);
    M.Grid = ServerPages[2].Grid; M.List = SelectedServer;
    if(bEdit) M.ExecuteItem(M.EditFavorite);
    else M.ExecuteItem(M.NewFavorite);
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
    if(bServerDetails) S = S$" / "$InfoText;
    return S;
}

function BeforePaint(Canvas C, float X, float Y)
{
    if(bEmbedded) { Super.BeforePaint(C, X, Y); return; }
    if(InputField != None) { Super(UT99ConsoleMatch).BeforePaint(C, X, Y); return; }
    Super(UT99ConsoleHome).BeforePaint(C, X, Y);
    if(IsServerList())
    {
        MenuLeft = WinWidth*0.06; Width = WinWidth*0.88;
        Top = WinHeight*0.29; RowHeight = WinHeight*0.038;
        VisibleRows = 14; FirstRow = 0;
    }
    if(Notice == None) return;
    Notice.Text = "";
    if(SelectedServer != None)
        Notice.Text = SelectedServer.GameType$" / "$SelectedServer.MapTitle$" | "$SelectedServer.IP$":"$SelectedServer.GamePort$"   Ping : "$int(SelectedServer.Ping)$" ms";
    else if(ServerMode == 0) Notice.Text = LANHelp;
    else if(ServerMode == 1) Notice.Text = InternetHelp;
    if(SelectedServer == None && ServerMode >= 0)
        Notice.Text = Notice.Text$" | "$(ServerPage+1)$" / "$Max(1, (TotalServers+9)/10)$"   ("$TotalServers$")";
    Notice.WinTop = WinHeight*0.85; Notice.WinHeight = WinHeight*0.08;
}

function ActivateRow()
{
    if(InputField != None) return;
    if(bActionThisTick || UIClock < NextActionTime) return;
    bActionThisTick = True; NextActionTime = UIClock+0.20;
    if(Row == Count-1) { GoBack(); return; }
    if(SelectedServer != None)
    {
        if(bServerDetails) return;
        if(Row == 0)
        {
            if(SelectedServer.MinNetVer > UT99ConsoleRoot(Root).ClientNetworkVersion) return;
            if(SelectedServer.GamePort == 0) SelectedServer.GamePort = Max(1, SelectedServer.QueryPort-1);
            NativeWindow.SetParent(NativeParent);
            CurrentServers.Grid.JoinServer(SelectedServer);
            Finish();
        }
        else if(Row == 1)
        {
            if(ServerMode == 2)
            { UBrowserFavoriteServers(ServerPages[2]).RemoveFavorite(SelectedServer); SelectedServer = None; Row = 0; BuildList(); }
            else UBrowserFavoriteServers(ServerPages[2]).AddFavorite(SelectedServer);
        }
        else if(Row == 2)
        { bStatusRequested = False; bServerDetails = True; Row = 0; FirstRow = 0; BuildList(); }
        else if(Row == 3) GetPlayerOwner().CopyToClipboard("unreal://"$SelectedServer.IP$":"$SelectedServer.GamePort);
        else if(Row == 4) { if(!SelectedServer.bPinging) SelectedServer.PingServer(False, True, True); }
        else if(Row == 5) CurrentServers.RePing();
        else if(Row == 6) SelectMode(ServerMode);
        else if(Row == 7) { if(ServerMode == 2) OpenFavorite(True); else UBrowserMainWindow(NativeWindow).ShowOpenWindow(); }
        else OpenFavorite(False);
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
            EmbeddedReturnMode = -1;
            NativeHost.ShowWindow(); NativeWindow.ShowWindow();
        }
        return;
    }
    if(!bListOptions)
    {
        if(Row == Count-4) { ChangeValue(1); return; }
        if(Row == Count-2) { bListOptions = True; Row = 0; FirstRow = 0; BuildList(); return; }
        if(Row == Count-3)
        {
            EditTarget = SearchProxy;
            InputField = UWindowEditControl(CreateWindow(class'UWindowEditControl', MenuLeft, WinHeight*0.48, Width, 24));
            InputField.SetText(SearchServersText); InputField.SetFont(F_Large); InputField.SetValue(SearchTerm);
            InputField.EditBox.MaxLength = 100; InputField.EditBox.ActivateWindow(0, False);
            GetPlayerOwner().ConsoleCommand("ANDROID_SHOW_KEYBOARD"); BuildList(); return;
        }
        if(ServerCount == 0) return;
        SelectedServer = UBrowserServerList(Entries[Row]); Row = 0; FirstRow = 0; BuildList(); return;
    }
    if(Row == Count-2) { UBrowserMainWindow(NativeWindow).ShowOpenWindow(); return; }
    if(Row == Count-3) { SelectMode(ServerMode); return; }
    if(Row == Count-9)
    {
        EmbeddedReturnMode = ServerMode;
        if(ServerMode == 0) BrowserClient.PageControl.GotoTab(LANPage, True);
        else if(ServerMode == 1) BrowserClient.PageControl.GotoTab(InternetPage, True);
        else BrowserClient.PageControl.GotoTab(BrowserClient.Favorites, True);
        bEmbedded = True; Count = 1;
        NativeHost.ShowWindow(); NativeWindow.ShowWindow(); return;
    }
    if(Row == Count-5) { OpenFavorite(False); return; }
    if(Row == Count-6)
    {
        SortMode = (SortMode+1)%4;
        ApplyServerSort();
        ServerPage = 0; Row = 0; BuildList(); return;
    }
    if(Row == Count-7 || Row == Count-8)
    {
        if(Row == Count-7 && (ServerPage+1)*10 < TotalServers) ServerPage++;
        else if(Row == Count-8 && ServerPage > 0) ServerPage--;
        Row = 0; FirstRow = 0; BuildList(); return;
    }
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
    if(InputField != None) { Super.GoBack(); BuildList(); return; }
    if(bListOptions && !bEmbedded && ServerMode >= 0) { bListOptions = False; Row = 0; FirstRow = 0; BuildList(); return; }
    if(bServerDetails) { bServerDetails = False; Row = 2; FirstRow = 0; BuildList(); return; }
    if(bEmbedded)
    {
        NativeWindow.HideWindow(); NativeHost.HideWindow(); bEmbedded = False;
        ServerMode = EmbeddedReturnMode; Row = 0; FirstRow = 0; BuildList(); return;
    }
    if(SelectedServer != None) { SelectedServer = None; Row = 0; BuildList(); return; }
    if(ServerMode >= 0)
    {
        CurrentServers.ShutdownFactories(False);
    }
    NativeWindow.SetParent(NativeParent);
    Super.GoBack();
}

function ChangeValue(int Direction)
{
    local int PreviousRow, FooterOffset;
    local bool bServerRow;
    if(bEmbedded) { Super.ChangeValue(Direction); return; }
    if(SelectedServer != None || ServerMode < 0) return;
    PreviousRow = Row; FooterOffset = Count-Row;
    bServerRow = Row < Max(1, ServerCount);
    ServerPage = Clamp(ServerPage+Direction, 0, Max(0, (TotalServers-1)/10));
    FirstRow = 0; BuildList();
    if(!bListOptions)
    {
        if(bServerRow) Row = Min(PreviousRow, Max(0, ServerCount-1));
        else Row = Clamp(Count-FooterOffset, 0, Count-1);
    }
}

function bool HotKeyDown(int Key, float X, float Y)
{
    if(bWindowVisible && InputField == None && !bEmbedded && IsServerList() &&
       (Key == 0x25 || Key == 0x27 || Key == 0x21 || Key == 0x22))
    {
        if(Key == 0x25 || Key == 0x21) ChangeValue(-1);
        else ChangeValue(1);
        return True;
    }
    return Super.HotKeyDown(Key, X, Y);
}

function LMouseDown(float X, float Y)
{
    if(IsServerList() && InputField == None && X >= MenuLeft && X <= MenuLeft+Width &&
       Y >= Top+(Count-4)*RowHeight && Y < Top+(Count-3)*RowHeight)
    {
        if(X < MenuLeft+Width*0.5) ChangeValue(-1);
        else ChangeValue(1);
        return;
    }
    Super.LMouseDown(X, Y);
}

function Paint(Canvas C, float X, float Y)
{
    if(bEmbedded) Super.Paint(C, X, Y);
    else if(InputField != None) Super(UT99ConsoleMatch).Paint(C, X, Y);
    else if(IsServerList()) PaintServerList(C);
    else Super(UT99ConsoleHome).Paint(C, X, Y);
}

function bool IsServerList()
{
    return ServerMode >= 0 && SelectedServer == None && !bListOptions;
}

function DrawTableText(Canvas C, float X, float Y, float W, string S)
{
    local float TW, TH;
    TextSize(C, S, TW, TH);
    while(TW > W && Len(S) > 1) { S = Left(S, Len(S)-1); TextSize(C, S, TW, TH); }
    ClipText(C, X, Y, S);
}

function PaintServerList(Canvas C)
{
    local int i;
    local float Y, W, H;
    local UBrowserServerList S;
    C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
    DrawStretchedTexture(C, WinWidth*0.40, WinHeight*0.005, WinWidth*0.20, WinHeight*0.18, Texture'UT99Logo');
    C.Font = Root.Fonts[F_Bold]; C.DrawColor.R = 255; C.DrawColor.G = 205; C.DrawColor.B = 100;
    TextSize(C, GetLocation(), W, H); ClipText(C, (WinWidth-W)*0.5, WinHeight*0.20, GetLocation());
    DrawTableText(C, MenuLeft+10, WinHeight*0.26, Width*0.50, CurrentServers.Grid.ServerName);
    DrawTableText(C, MenuLeft+Width*0.51, WinHeight*0.26, Width*0.25, CurrentServers.Grid.MapNameName);
    DrawTableText(C, MenuLeft+Width*0.77, WinHeight*0.26, Width*0.12, CurrentServers.Grid.PlayersName);
    DrawTableText(C, MenuLeft+Width*0.90, WinHeight*0.26, Width*0.10, CurrentServers.Grid.PingName);
    for(i = 0; i < Count; i++)
    {
        Y = Top+i*RowHeight;
        if(i == Row) { C.DrawColor.R = 93; C.DrawColor.G = 17; C.DrawColor.B = 28; }
        else { C.DrawColor.R = 20; C.DrawColor.G = 18; C.DrawColor.B = 24; }
        DrawStretchedTexture(C, MenuLeft, Y, Width, RowHeight-1, Texture'UWindow.WhiteTexture');
        C.DrawColor.R = 240; C.DrawColor.G = 229; C.DrawColor.B = 204;
        if(i >= Count-4) { C.DrawColor.R = 212; C.DrawColor.G = 183; C.DrawColor.B = 133; }
        if(i == Row) { C.DrawColor.R = 255; C.DrawColor.G = 213; C.DrawColor.B = 100; }
        C.Font = Root.Fonts[F_LargeBold]; TextSize(C, "A", W, H);
        S = UBrowserServerList(Entries[i]);
        if(S != None)
        {
            DrawTableText(C, MenuLeft+10, Y+(RowHeight-H)*0.5, Width*0.49-10, S.HostName);
            if(S.HostName == "") DrawTableText(C, MenuLeft+10, Y+(RowHeight-H)*0.5, Width*0.49-10, S.IP);
            DrawTableText(C, MenuLeft+Width*0.51, Y+(RowHeight-H)*0.5, Width*0.25, S.MapName);
            if(S.bPinged && !S.bPingFailed)
            {
                ClipText(C, MenuLeft+Width*0.77, Y+(RowHeight-H)*0.5, S.NumPlayers$"/"$S.MaxPlayers);
                ClipText(C, MenuLeft+Width*0.90, Y+(RowHeight-H)*0.5, string(int(S.Ping)));
            }
            else ClipText(C, MenuLeft+Width*0.90, Y+(RowHeight-H)*0.5, "...");
        }
        else if(i == Count-4)
        {
            DrawTableText(C, MenuLeft+10, Y+(RowHeight-H)*0.5, Width*0.35, PreviousPageText);
            ClipText(C, MenuLeft+Width*0.43, Y+(RowHeight-H)*0.5, (ServerPage+1)$" / "$Max(1, (TotalServers+9)/10));
            DrawTableText(C, MenuLeft+Width*0.68, Y+(RowHeight-H)*0.5, Width*0.32-10, NextPageText);
        }
        else
        {
            if(i >= Count-3)
            {
                TextSize(C, Caption(i), W, H);
                DrawTableText(C, MenuLeft+FMax(10, (Width-W)*0.5), Y+(RowHeight-H)*0.5, Width-20, Caption(i));
            }
            else DrawTableText(C, MenuLeft+10, Y+(RowHeight-H)*0.5, Width-20, Caption(i));
        }
    }
    C.Font = Root.Fonts[F_Normal]; TextSize(C, PageHintText, W, H);
    ClipText(C, (WinWidth-W)*0.5, WinHeight*0.94, PageHintText);
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
    InfoText="SERVER AND PLAYER INFO"
    CopyText="COPY SERVER ADDRESS"
    PingServerText="PING THIS SERVER"
    PingAllText="PING ALL SERVERS"
    RemoveFavoriteText="REMOVE FROM FAVOURITES"
    EditFavoriteText="EDIT FAVOURITE"
    NewFavoriteText="NEW FAVOURITE"
    NextPageText="NEXT PAGE"
    PreviousPageText="PREVIOUS PAGE"
    SortText="SORT SERVERS"
    PlayersText="PLAYER / SCORE / PING"
    RulesText="SERVER RULES"
    FailedText="SERVER NOT RESPONDING"
    PendingText="QUERYING SERVER..."
    IncompatibleText="SERVER REQUIRES UT VERSION"
    AdvancedText="ADVANCED SERVER BROWSER"
    ListOptionsText="SERVER LIST OPTIONS"
    SearchServersText="SEARCH NAME / MAP / GAME TYPE"
    PageHintText="UP/DOWN: server   LEFT/RIGHT: page   A: select   B: back"
    LANHelp="Servers on your local network. Start a multiplayer game on the host, then refresh."
    InternetHelp="Choose a server, then join. Refresh to search again."
    ServerMode=-1
    SortMode=3
}
