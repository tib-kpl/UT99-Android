class UT99ConsoleServerListWindow extends UTBrowserServerListWindow;

// The console menu draws server details itself. OldUnreal 469 opens the
// native info area as a floating window on small screens as soon as the list
// is created, which showed a broken copy of the desktop browser over the menu.
function ShowInfoArea(bool bShow, optional bool bFloating, optional bool bNoActivate)
{
    Super.ShowInfoArea(False, bFloating, True);
}

defaultproperties
{
    GridClass="UT99ConsoleMenu.UT99ConsoleServerGrid"
}
