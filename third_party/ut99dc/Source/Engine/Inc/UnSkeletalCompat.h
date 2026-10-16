#pragma once

#if defined(PLATFORM_ANDROID)
// UT bonus-pack skeletal data. Disk order follows the public UT SDK format.
struct FSkelQuat
{
    FLOAT X,Y,Z,W;
    friend FArchive& operator<<(FArchive& Ar,FSkelQuat& Q) { return Ar<<Q.X<<Q.Y<<Q.Z<<Q.W; }
};
struct FSkelNamedBone
{
    FName Name; DWORD Flags; INT Parent;
    friend FArchive& operator<<(FArchive& Ar,FSkelNamedBone& B) { return Ar<<B.Name<<B.Flags<<B.Parent; }
};
struct FSkelTrack
{
    DWORD Flags;
    TArray<FSkelQuat> Rotations;
    TArray<FVector> Positions;
    TArray<FLOAT> Times;
    friend FArchive& operator<<(FArchive& Ar,FSkelTrack& T) { return Ar<<T.Flags<<T.Rotations<<T.Positions<<T.Times; }
};
struct FSkelMove
{
    FVector RootSpeed; FLOAT Duration; INT StartBone; DWORD Flags;
    TArray<INT> BoneIndices; TArray<FSkelTrack> Tracks; FSkelTrack RootTrack;
    friend FArchive& operator<<(FArchive& Ar,FSkelMove& M) { return Ar<<M.RootSpeed<<M.Duration<<M.StartBone<<M.Flags<<M.BoneIndices<<M.Tracks<<M.RootTrack; }
};
class ENGINE_API UAnimation : public UObject
{
    DECLARE_CLASS(UAnimation,UObject,0)
public:
    UAnimation() {}
    TArray<FSkelNamedBone> RefBones;
    TArray<FSkelMove> Moves;
    TArray<FMeshAnimSeq> AnimSeqs;
    void Serialize(FArchive& Ar);
};

struct FSkelBone
{
    FName Name; DWORD Flags; FSkelQuat Orientation; FVector Position;
    FLOAT Length,XSize,YSize,ZSize; INT NumChildren,Parent;
    friend FArchive& operator<<(FArchive& Ar,FSkelBone& B)
    { return Ar<<B.Name<<B.Flags<<B.Orientation<<B.Position<<B.Length<<B.XSize<<B.YSize<<B.ZSize<<B.NumChildren<<B.Parent; }
};
struct FSkelExtWedge
{
    _WORD Vertex,Flags; FLOAT U,V;
    friend FArchive& operator<<(FArchive& Ar,FSkelExtWedge& W) { return Ar<<W.Vertex<<W.Flags<<W.U<<W.V; }
};
struct FSkelWeightIndex
{
    _WORD Start,Count,DetailA,DetailB;
    friend FArchive& operator<<(FArchive& Ar,FSkelWeightIndex& W) { return Ar<<W.Start<<W.Count<<W.DetailA<<W.DetailB; }
};
struct FSkelWeight
{
    _WORD Point,Weight;
    friend FArchive& operator<<(FArchive& Ar,FSkelWeight& W) { return Ar<<W.Point<<W.Weight; }
};
class ENGINE_API USkeletalMesh : public ULodMesh
{
    DECLARE_CLASS(USkeletalMesh,ULodMesh,0)
public:
    USkeletalMesh() {}
    TArray<FSkelExtWedge> ExtWedges;
    TArray<FVector> Points;
    TArray<FSkelBone> RefSkeleton;
    TArray<FSkelWeightIndex> WeightIndices;
    TArray<FSkelWeight> Weights;
    TArray<FVector> LocalPoints;
    INT WeaponBoneIndex;
    UAnimation* DefaultAnimation;
    INT SkeletalDepth;
    FCoords WeaponAdjust;
    void Serialize(FArchive& Ar);
    void PostLoad();
    void BuildVertexAnimations();
};
#endif
