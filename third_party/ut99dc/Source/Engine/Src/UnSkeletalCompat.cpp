#include "EnginePrivate.h"
#include "UnSkeletalCompat.h"

#if defined(PLATFORM_ANDROID)
IMPLEMENT_CLASS(UAnimation);
IMPLEMENT_CLASS(USkeletalMesh);

void UAnimation::Serialize(FArchive& Ar)
{
    Super::Serialize(Ar);
    Ar<<RefBones<<Moves<<AnimSeqs;
}

void USkeletalMesh::Serialize(FArchive& Ar)
{
    Super::Serialize(Ar);
    Ar<<ExtWedges<<Points<<RefSkeleton<<WeightIndices<<Weights<<LocalPoints;
    // The reference is before the depth and adjustment matrix on disk.
    Ar<<WeaponBoneIndex<<DefaultAnimation<<SkeletalDepth;
    Ar<<WeaponAdjust.Origin<<WeaponAdjust.XAxis<<WeaponAdjust.YAxis<<WeaponAdjust.ZAxis;
}

namespace
{
struct FSkelTransform
{
    FVector X,Y,Z,Position;
    FVector Rotate(const FVector& V) const { return X*V.X+Y*V.Y+Z*V.Z; }
    FVector Apply(const FVector& V) const { return Rotate(V)+Position; }
};

FSkelTransform BoneTransform(FSkelQuat Q,const FVector& P,UBOOL Root)
{
    FLOAT N=Q.X*Q.X+Q.Y*Q.Y+Q.Z*Q.Z+Q.W*Q.W;
    if(!(N>SMALL_NUMBER)) { Q.X=Q.Y=Q.Z=0; Q.W=1; N=1; }
    FLOAT S=appSqrt(1.f/N);
    Q.X*=S; Q.Y*=S; Q.Z*=S; Q.W*=S;
    // UT stores the root orientation in the opposite sense to child bones.
    if(!Root) { Q.X=-Q.X; Q.Y=-Q.Y; Q.Z=-Q.Z; }
    FSkelTransform T;
    T.X=FVector(1-2*(Q.Y*Q.Y+Q.Z*Q.Z),2*(Q.X*Q.Y+Q.Z*Q.W),2*(Q.X*Q.Z-Q.Y*Q.W));
    T.Y=FVector(2*(Q.X*Q.Y-Q.Z*Q.W),1-2*(Q.X*Q.X+Q.Z*Q.Z),2*(Q.Y*Q.Z+Q.X*Q.W));
    T.Z=FVector(2*(Q.X*Q.Z+Q.Y*Q.W),2*(Q.Y*Q.Z-Q.X*Q.W),1-2*(Q.X*Q.X+Q.Y*Q.Y));
    T.Position=P;
    return T;
}

FSkelQuat BlendQuat(const FSkelQuat& A,const FSkelQuat& B,FLOAT Alpha)
{
    FLOAT Dot=A.X*B.X+A.Y*B.Y+A.Z*B.Z+A.W*B.W;
    FLOAT Sign=Dot<0 ? -1.f : 1.f;
    FLOAT AWeight=1-Alpha,BWeight=Alpha*Sign;
    FLOAT Cosine=Clamp(Abs(Dot),0.f,1.f);
    if(Cosine<0.9995f)
    {
        FLOAT Angle=acosf(Cosine),Denom=appSin(Angle);
        AWeight=appSin((1-Alpha)*Angle)/Denom;
        BWeight=appSin(Alpha*Angle)*Sign/Denom;
    }
    FSkelQuat Q;
    Q.X=A.X*AWeight+B.X*BWeight;
    Q.Y=A.Y*AWeight+B.Y*BWeight;
    Q.Z=A.Z*AWeight+B.Z*BWeight;
    Q.W=A.W*AWeight+B.W*BWeight;
    return Q;
}

void TrackInterval(const FSkelTrack& Track,INT Count,FLOAT Time,FLOAT Duration,INT& A,INT& B,FLOAT& Alpha)
{
    A=B=0; Alpha=0;
    if(Count<2) return;
    if(Track.Times.Num()==Count)
    {
        while(A+1<Count && Track.Times(A+1)<=Time) A++;
        B=(A+1)%Count;
        FLOAT End=B ? Track.Times(B) : Duration;
        if(End>Track.Times(A)) Alpha=Clamp((Time-Track.Times(A))/(End-Track.Times(A)),0.f,1.f);
    }
    else
    {
        FLOAT Frame=Duration>0 ? Time*Count/Duration : 0;
        A=Clamp(appFloor(Frame),0,Count-1); B=(A+1)%Count; Alpha=Frame-appFloor(Frame);
    }
}

void SampleTrack(const FSkelTrack& Track,FLOAT Time,FLOAT Duration,FSkelQuat& Q,FVector& P)
{
    INT A,B; FLOAT Alpha;
    if(Track.Rotations.Num())
    {
        TrackInterval(Track,Track.Rotations.Num(),Time,Duration,A,B,Alpha);
        Q=BlendQuat(Track.Rotations(A),Track.Rotations(B),Alpha);
    }
    if(Track.Positions.Num())
    {
        TrackInterval(Track,Track.Positions.Num(),Time,Duration,A,B,Alpha);
        P=Track.Positions(A)*(1-Alpha)+Track.Positions(B)*Alpha;
    }
}
}

void USkeletalMesh::PostLoad()
{
    Super::PostLoad();
    if(DefaultAnimation)
    {
        DefaultAnimation->ConditionalPostLoad();
        BuildVertexAnimations();
    }
}

void USkeletalMesh::BuildVertexAnimations()
{
    guard(USkeletalMesh::BuildVertexAnimations);
    // Convert once to the existing LOD renderer's vertex poses. The source
    // package and its object identities stay unchanged.
    if(!DefaultAnimation || !Points.Num() || RefSkeleton.Num()<1 || RefSkeleton.Num()>256
    || RefSkeleton.Num()!=WeightIndices.Num()
    || Weights.Num()!=LocalPoints.Num() || SpecialVerts || ExtWedges.Num())
        appErrorf(TEXT("Unsupported skeletal mesh layout: %s"),GetName());
    UAnimation* Anim=DefaultAnimation;
    if(Anim->Moves.Num()!=Anim->AnimSeqs.Num()) appErrorf(TEXT("Invalid skeletal animation: %s"),Anim->GetName());
    INT Frames=0;
    for(INT I=0; I<Anim->AnimSeqs.Num(); I++)
    {
        INT N=Anim->AnimSeqs(I).NumFrames;
        if(N<1 || N>4096 || Frames>65536-N) appErrorf(TEXT("Invalid skeletal frame count"));
        Frames+=N;
    }
    if(Points.Num()>65532 || Frames<1 || Frames>16000000/Points.Num()) appErrorf(TEXT("Skeletal animation exceeds pose budget"));
    TArray<INT> BoneMap;
    for(INT I=0; I<RefSkeleton.Num(); I++)
    {
        if((I && (RefSkeleton(I).Parent<0 || RefSkeleton(I).Parent>=I))
        || INT(WeightIndices(I).Start)+INT(WeightIndices(I).Count)>Weights.Num()) appErrorf(TEXT("Invalid skeletal hierarchy"));
        INT Match=INDEX_NONE;
        for(INT J=0; J<Anim->RefBones.Num(); J++) if(Anim->RefBones(J).Name==RefSkeleton(I).Name) { Match=J; break; }
        BoneMap.AddItem(Match);
    }
    for(INT I=0; I<Weights.Num(); I++) if(Weights(I).Point>=Points.Num()) appErrorf(TEXT("Invalid skeletal influence"));
    AnimSeqs=Anim->AnimSeqs;
    if(WeaponBoneIndex>=0 && WeaponBoneIndex<RefSkeleton.Num())
    {
        SpecialVerts=3;
        FMeshFace Face;
        Face.iWedge[0]=0; Face.iWedge[1]=1; Face.iWedge[2]=2; Face.MaterialIndex=0;
        SpecialFaces.AddItem(Face);
    }
    FrameVerts=Points.Num()+SpecialVerts; AnimFrames=Frames;
    if(Frames>16000000/FrameVerts) appErrorf(TEXT("Skeletal animation exceeds pose budget"));
    Verts.DetachSource();
    Verts.Empty(); Verts.Add(FrameVerts*AnimFrames);
    BoundingBoxes.Empty(); BoundingSpheres.Empty();
    TArray<FSkelTransform> Transforms; Transforms.Add(RefSkeleton.Num());
    TArray<FVector> Pose; Pose.Add(FrameVerts);
    INT Frame=0;
    for(INT Sequence=0; Sequence<AnimSeqs.Num(); Sequence++)
    {
        FMeshAnimSeq& Seq=AnimSeqs(Sequence); Seq.StartFrame=Frame;
        const FSkelMove& Move=Anim->Moves(Sequence);
        for(INT F=0; F<Seq.NumFrames; F++,Frame++)
        {
            FLOAT Time=Move.Duration*F/Seq.NumFrames;
            for(INT Bone=0; Bone<RefSkeleton.Num(); Bone++)
            {
                const FSkelBone& Ref=RefSkeleton(Bone);
                FSkelQuat Q=Ref.Orientation; FVector P=Ref.Position;
                INT Map=BoneMap(Bone);
                if(Map>=0 && Map<Move.BoneIndices.Num())
                {
                    INT Track=Move.BoneIndices(Map);
                    if(Track>=0 && Track<Move.Tracks.Num()) SampleTrack(Move.Tracks(Track),Time,Move.Duration,Q,P);
                }
                FSkelTransform T=BoneTransform(Q,P,Bone==0);
                if(Bone)
                {
                    const FSkelTransform& Parent=Transforms(Ref.Parent);
                    T.Position=Parent.Apply(T.Position);
                    T.X=Parent.Rotate(T.X); T.Y=Parent.Rotate(T.Y); T.Z=Parent.Rotate(T.Z);
                }
                Transforms(Bone)=T;
            }
            for(INT I=0; I<FrameVerts; I++) Pose(I)=FVector(0,0,0);
            for(INT Bone=0; Bone<WeightIndices.Num(); Bone++)
                for(INT K=0; K<WeightIndices(Bone).Count; K++)
                {
                    INT Index=WeightIndices(Bone).Start+K;
                    const FSkelWeight& W=Weights(Index);
                    Pose(W.Point+SpecialVerts)+=Transforms(Bone).Apply(LocalPoints(Index))*(W.Weight/65535.f);
                }
            if(SpecialVerts)
            {
                const FSkelTransform& Hand=Transforms(WeaponBoneIndex);
                FVector O=Hand.Apply(WeaponAdjust.Origin);
                FVector X=Hand.Rotate(WeaponAdjust.XAxis)*64.f;
                FVector Z=Hand.Rotate(WeaponAdjust.ZAxis)*64.f;
                Pose(0)=O-Z; Pose(1)=O-Z+X; Pose(2)=O+Z;
            }
            FBox Box(0);
            for(INT I=0; I<FrameVerts; I++)
            {
                const FVector& V=Pose(I);
                if(!(V.X>=-1024 && V.X<=1023 && V.Y>=-1024 && V.Y<=1023 && V.Z>=-512 && V.Z<=511))
                    appErrorf(TEXT("Skeletal pose exceeds vertex range: %s"),GetName());
                Verts(Frame*FrameVerts+I)=FMeshVert(V); Box+=V;
            }
            BoundingBoxes.AddItem(Box); BoundingSpheres.AddItem(FSphere(0));
        }
    }
    BoundingBox=BoundingBoxes(0);
    for(INT I=1; I<BoundingBoxes.Num(); I++) BoundingBox+=BoundingBoxes(I);
    debugf(TEXT("Skeletal poses built: %s vertices=%i frames=%i sequences=%i"),GetName(),FrameVerts,Frames,AnimSeqs.Num());
    unguardobj;
}
#endif
