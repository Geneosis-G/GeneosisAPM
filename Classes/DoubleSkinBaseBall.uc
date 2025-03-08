class DoubleSkinBaseBall extends GGKActorBaseBallContent
	implements( DoubleSkinInterface );

var bool shouldAim;
var float maxSpeed;
var float rotationInterpSpeed;

delegate vector GetTargetLoc();

function SetSkin(MaterialInterface newMat)
{
	StaticMeshComponent.SetMaterial(0, newMat);
}

event Tick(float deltaTime)
{
	local float currSpeed;
	local vector targetLoc, newDirection;

	super.Tick(DeltaTime);
	// Aim at target
	targetLoc=GetTargetLoc();
	if(shouldAim && !IsZero(targetLoc))
	{
		currSpeed=VSize(StaticMeshComponent.GetRBLinearVelocity());
		if(VSize(Location-targetLoc) < 1.f ||
		(maxSpeed > 0.f && currSpeed == 0.f))
		{
			shouldAim=false;
		}
		else if(currSpeed > 0.f)
		{
			if(currSpeed > maxSpeed)
			{
				maxSpeed=currSpeed;
			}
			else
			{
				newDirection=AimAt(deltaTime, targetLoc);
				StaticMeshComponent.SetRBLinearVelocity(newDirection*maxSpeed);
			}
		}
	}
}

function vector AimAt(float deltaTime, vector aimLocation)
{
	local rotator dir, expectedDir;
	local vector newDirection;

	dir=rotator(Normal(StaticMeshComponent.GetRBLinearVelocity()));
	expectedDir=rotator(Normal(aimLocation-Location));

	newDirection=Normal(vector(RInterpTo( dir, expectedDir, deltaTime, rotationInterpSpeed, false )));

	return newDirection;
}

function bool shouldIgnoreActor(Actor act)
{
	//WorldInfo.Game.Broadcast(self, "shouldIgnoreActor=" $ act);
	return (
	act == none
	|| Volume(act) != none
	|| GGApexDestructibleActor(act) != none
	|| act == self
	|| act == Owner
	|| act.Owner == Owner
	|| AdvancedPitchingMachine(act) != none);
}

simulated event TakeDamage( int damage, Controller eventInstigator, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	super.TakeDamage(damage, eventInstigator, hitLocation, momentum, damageType, hitInfo, damageCauser);
	//WorldInfo.Game.Broadcast(self, "TakeDamage=" $ damageCauser);
	StopAimAfterHit(damageCauser);
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
    super.Bump(Other, OtherComp, HitNormal);
	//WorldInfo.Game.Broadcast(self, "Bump=" $ other);
	StopAimAfterHit(other);
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex);
	//WorldInfo.Game.Broadcast(self, "RBCollision=" $ OtherComponent.Owner);
	StopAimAfterHit(OtherComponent!=none?OtherComponent.Owner:none);
}

function StopAimAfterHit(optional Actor target)
{
	if(shouldIgnoreActor(target))
		return;

	//WorldInfo.Game.Broadcast(self, "stopAim=" $ target);
	shouldAim=false;
}

DefaultProperties
{
	Begin Object name=StaticMeshComponent0
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
	End Object

	bCollideActors=true
	bBlockActors=true
	bCollideWorld=true

	rotationInterpSpeed=10.f
}