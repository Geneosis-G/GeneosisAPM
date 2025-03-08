class RepulsiveBB extends DoubleSkinBaseBall
	placeable;

var int mDamage;
var float mBallForce;
var float mDamageRadius;
var class< GGDamageTypeExplosiveActor > mDamageType;

function string GetActorName()
{
	return "Repulsive Baseball";
}

function bool shouldIgnoreActor(Actor act)
{
	//WorldInfo.Game.Broadcast(self, "shouldIgnoreActor=" $ act);
	return (
	act == none
	|| Volume(act) != none
	|| act == self
	|| act == Owner
	|| act.Owner == Owner);
}

simulated event TakeDamage( int damage, Controller eventInstigator, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	super.TakeDamage(damage, eventInstigator, hitLocation, momentum, damageType, hitInfo, damageCauser);
	//WorldInfo.Game.Broadcast(self, "TakeDamage=" $ damageCauser);
	HitActor(damageCauser);
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
    super.Bump(Other, OtherComp, HitNormal);
	//WorldInfo.Game.Broadcast(self, "Bump=" $ other);
	HitActor(other);
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	super.RigidBodyCollision(HitComponent, OtherComponent, RigidCollisionData, ContactIndex);
	//WorldInfo.Game.Broadcast(self, "RBCollision=" $ OtherComponent.Owner);
	HitActor(OtherComponent!=none?OtherComponent.Owner:none);
}

function HitActor(optional Actor target)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local GGKactor kActor;
	local GGSVehicle vehicle;
	local float mass;
	local vector targetPos, direction, newVelocity;
	local int damage;

	if(shouldIgnoreActor(target))
		return;

	gpawn = GGPawn(target);
	mmoEnemy = GGNPCMMOEnemy(target);
	zombieEnemy = GGNpcZombieGameModeAbstract(target);
	kActor = GGKActor(target);
	vehicle = GGSVehicle(target);
	// Get correct angle depending on mBall angle
	targetPos = gpawn==none?target.Location:gpawn.mesh.GetPosition();
	direction = Normal(targetPos-Location);
	if(gpawn != none)
	{
		mass=50.f;
		if(!gpawn.mIsRagdoll)
		{
			gpawn.SetRagdoll(true);
		}
		//gpawn.mesh.AddImpulse(direction * mass * mBallForce,,, false);
		newVelocity = gpawn.Mesh.GetRBLinearVelocity() + (direction * mBallForce);
		gpawn.Mesh.SetRBLinearVelocity(newVelocity);
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			damage = int(RandRange(1, 5));
			mmoEnemy.TakeDamageFrom(damage, Owner, class'GGDamageTypeExplosiveActor');
		}
		else
		{
			gpawn.TakeDamage( 0.f, GGGoat(Owner).Controller, gpawn.Location, vect(0, 0, 0), class'GGDamageType',, Owner);
		}
		//Damage zombies
		if(zombieEnemy != none)
		{
			damage = int(RandRange(5, 10));
			zombieEnemy.TakeDamage(damage, GGGoat(Owner).Controller, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode' );
		}
	}
	else if(kActor != none)
	{
		mass=kActor.StaticMeshComponent.BodyInstance.GetBodyMass();
		//WorldInfo.Game.Broadcast(self, "Mass : " $ mass);
		kActor.ApplyImpulse(direction,  mass * mBallForce,  -direction);
	}
	else if(vehicle != none)
	{
		mass=vehicle.Mass;
		vehicle.AddForce(direction * mass * mBallForce);
	}
	else if(GGApexDestructibleActor(target) != none)
	{
		target.TakeDamage(10000000, GGGoat(Owner).Controller, target.Location, direction * mass * mBallForce, class'GGDamageType',, Owner);
	}
}

simulated event Tick( float delta )
{
	local GGPawn gpawn;

	super.Tick(delta);

	//WorldInfo.Game.Broadcast(self, self $ " at " $ Location);

	// Try to prevent pawns from walking on it
	foreach BasedActors(class'GGPawn', gpawn)
	{
		HitActor(gpawn);
	}

	// Find missed items
	if(VSize(Velocity) > 0.1f)
	{
		HurtRadius( mDamage, mDamageRadius, mDamageType, mBallForce*100.f, Location, , GGGoat( Owner ).Controller );
	}
}

DefaultProperties
{
	mDamage=10
	mBallForce=500.0f
	mDamageRadius=20.0f

	mDamageType=class'DamageTypeFastBall'
}