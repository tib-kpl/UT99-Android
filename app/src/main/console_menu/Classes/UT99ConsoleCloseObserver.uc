// Observe native Close() without changing its class or callbacks.
class UT99ConsoleCloseObserver extends UWindowWindow;
var UT99ConsoleDialog Adapter;
function Close(optional bool bByParent)
{
    if(Adapter != None) Adapter.bNativeClosed = True;
    Super.Close(bByParent);
}
