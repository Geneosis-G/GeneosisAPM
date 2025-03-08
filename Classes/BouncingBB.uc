class BouncingBB extends DoubleSkinBaseBall;

simulated event PostBeginPlay ()
{
	// Act like rubber
	StaticMeshComponent.SetPhysMaterialOverride (PhysicalMaterial'EngineMaterials.PhysMat_Rubber');
}

function string GetActorName()
{
	return "Bouncing Baseball";
}

DefaultProperties
{
	bBounce = true
	Physics = PHYS_RigidBody
	CollisionType=COLLIDE_TouchAll
}