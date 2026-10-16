class ServerSortAudit extends Commandlet;

event int Main(string Params)
{
    local class<UBrowserServerGrid> GridClass;
    local UBrowserServerGrid G;
    local UBrowserServerList A, B;
    GridClass=class<UBrowserServerGrid>(DynamicLoadObject("UT99ConsoleMenu.UT99ConsoleServerGrid",class'Class'));
    if(GridClass == None) return 1;
    G=new(None) GridClass;
    A=new(None) class'UBrowserServerList';
    B=new(None) class'UBrowserServerList';
    A.NumPlayers=8; A.Ping=200;
    B.NumPlayers=4; B.Ping=10;
    if(G.ByPlayers(A,B)>=0 || G.ByPlayers(B,A)<=0) return 2;
    B.NumPlayers=8; B.Ping=20; B.MaxPlayers=10;
    A.MaxPlayers=64;
    if(G.ByPlayers(B,A)>=0 || G.ByPlayers(A,B)<=0) return 3;
    A.Ping=20; A.HostName="Alpha"; B.HostName="Beta";
    if(G.ByPlayers(A,B)>=0 || G.ByPlayers(B,A)<=0) return 4;
    A.bPingFailed=True; A.NumPlayers=32;
    if(G.ByPlayers(A,B)<=0 || G.ByPlayers(B,A)>=0) return 5;
    B.bPingFailed=True; B.NumPlayers=32; B.HostName="Alpha";
    if(G.ByPlayers(A,B)!=0) return 6;
    A.bPingFailed=False; B.bPingFailed=False;
    A.NumPlayers=12; B.NumPlayers=8;
    G.bSortDescending=True;
    if(G.ByPlayers(A,B)<=0 || G.ByPlayers(B,A)>=0) return 7;
    Log("SERVER_SORT PASS: population, ping before capacity, stable name, failed servers, equality, reverse");
    return 0;
}

defaultproperties
{
    IsClient=False
    IsServer=False
    IsEditor=True
    LogToStdout=True
}
