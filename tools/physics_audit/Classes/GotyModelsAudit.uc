// Loads and animates bonus-pack models without a compile-time dependency.
class GotyModelsAudit extends AnimationObserve;

var int Sample;
var Actor DisplayModel;

function Timer()
{
    local class<Actor> ModelClass;
    local Actor Model;
    local PlayerPawn P;
    local string ClassName;
    local string SkinName, FaceName;

    Super.Timer();
    if (Sample >= 3)
    {
        Log("GOTY_MODELS COMPLETE samples=" $ Sample);
        SetTimer(0,False);
        return;
    }
    foreach AllActors(class'PlayerPawn', P)
        if (P.Player != None)
        {
            if (DisplayModel != None) DisplayModel.Destroy();
            P.SetLocation(vect(-448,-800,-180));
            P.ClientSetRotation(rot(0,-16384,0));
            if (Sample == 0)
            {
                ClassName="MultiMesh.TNali";
                SkinName="TNaliMeshSkins.Ouboudah";
                FaceName="TNaliMeshSkins.nali-Face";
            }
            else if (Sample == 1)
            {
                ClassName="MultiMesh.TCow";
                SkinName="TCowMeshSkins.WarCow";
                FaceName="TCowMeshSkins.WarCowFace";
            }
            else
            {
                ClassName="MultiMesh.TSkaarj";
                SkinName="TSkMSkins.Warr";
                FaceName="Dominator";
            }
            ModelClass=class<Actor>(DynamicLoadObject(ClassName,class'Class'));
            if (ModelClass != None)
                Model=Spawn(ModelClass,,,vect(-448,-950,-180),rot(0,16384,0));
            if (Model != None && Model.Mesh != None)
            {
                Model.SetPhysics(PHYS_None);
                PlayerPawn(Model).SetMultiSkin(Model,SkinName,FaceName,255);
                Model.LoopAnim('Breath1');
                Log("GOTY_MODELS PASS class=" $ ClassName $ " mesh=" $ Model.Mesh);
            }
            else Log("GOTY_MODELS FAIL class=" $ ClassName);
            Sample++;
            DisplayModel=Model;
            SetTimer(5,True);
            return;
        }
}
