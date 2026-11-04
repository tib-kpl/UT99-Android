// Access a control without UE1 v400 copying a >255-byte contextual array.
class CampaignFlowFixture extends UT99ConsoleCampaign;
function UWindowDialogControl ControlAt(int Index)
{
    return Controls[Index];
}
