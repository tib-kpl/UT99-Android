class UT99ConsoleServerGrid extends UTBrowserServerGrid;

// Capacity does not outrank latency when the active player counts are equal.
function int ByPlayers(UBrowserServerList T, UBrowserServerList B)
{
    local int Result;
    if(B == None) return -1;
    if(T.bPingFailed != B.bPingFailed)
    {
        if(T.bPingFailed) return 1;
        return -1;
    }
    if(T.NumPlayers > B.NumPlayers) Result = -1;
    else if(T.NumPlayers < B.NumPlayers) Result = 1;
    else if(T.Ping < B.Ping) Result = -1;
    else if(T.Ping > B.Ping) Result = 1;
    else if(Caps(T.HostName) < Caps(B.HostName)) Result = -1;
    else if(Caps(T.HostName) > Caps(B.HostName)) Result = 1;
    else if(T.IP < B.IP) Result = -1;
    else if(T.IP > B.IP) Result = 1;
    else Result = T.QueryPort-B.QueryPort;
    if(bSortDescending) Result = -Result;
    return Result;
}

function Created()
{
    Super.Created();
    SortByColumn = Players;
    bSortDescending = False;
}
