// Isolated original-package load/render probe; no compile-time GOTY imports.
class SkeletalModelsAudit extends AnimationObserve;
var SkeletalDummy DisplayModel;
var int Sample;
function PostBeginPlay()
{
 Super.PostBeginPlay();
 DeathMatchPlus(Level.Game).bRequireReady=False;
 DeathMatchPlus(Level.Game).CountDown=0;
}
function Timer()
{
 local PlayerPawn P;
 local string ModelName,SkinName;
 local name Sequence;
 local class<Actor> PlayerClass;
 local int Padding;
 Super.Timer();
 foreach AllActors(class'PlayerPawn',P)
  if(P.Player!=None)
  {
   if(Sample==0)
   {
    DeathMatchPlus(Level.Game).bNetReady=False;
    DeathMatchPlus(Level.Game).StartMatch();
   }
   if(DisplayModel!=None) DisplayModel.Destroy();
   P.SetLocation(vect(-448,-800,-180));
   P.ClientSetRotation(rot(0,-16384,0));
   if(Sample<3) { ModelName="NewXan"; SkinName="XanTitanium"; }
   else { ModelName="WarMachineBoss"; SkinName="WarGold"; }
   if(Sample%3==0) Sequence='Breath1L';
   else if(Sample%3==1) Sequence='RunLg';
   else Sequence='Dead1';
   if(Sample==0) PlayerClass=class<Actor>(DynamicLoadObject("SkeletalChars.XanMk2",class'Class'));
   if(Sample==3) PlayerClass=class<Actor>(DynamicLoadObject("SkeletalChars.WarBoss",class'Class'));
   if((Sample==0 || Sample==3) && PlayerClass==None) Log("SKELETAL_MODELS FAIL player-class");
   DisplayModel=Spawn(class'SkeletalDummy',,,vect(-448,-950,-180),rot(0,16384,0));
   DisplayModel.Mesh=Mesh(DynamicLoadObject("SkeletalChars."$ModelName,class'Mesh'));
   DisplayModel.Skin=Texture(DynamicLoadObject("SkeletalChars."$SkinName,class'Texture'));
   if(DisplayModel.Mesh!=None && DisplayModel.Skin!=None && DisplayModel.HasAnim(Sequence))
   {
    DisplayModel.LoopAnim(Sequence);
    Log("SKELETAL_MODELS PASS mesh="$DisplayModel.Mesh$" sequence="$Sequence$" skin="$DisplayModel.Skin);
   }
   else Log("SKELETAL_MODELS FAIL mesh="$ModelName$" sequence="$Sequence);
   Sample++;
   if(Sample>=6)
   {
    for(Padding=0;Padding<80;Padding++) Log("SKELETAL_MODELS flush diagnostic log 012345678901234567890123456789012345678901234567890123456789");
    SetTimer(0,False);
   }
   else SetTimer(5,True);
   return;
  }
}
