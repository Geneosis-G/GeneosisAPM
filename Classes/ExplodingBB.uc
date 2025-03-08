class ExplodingBB extends DoubleSkinBaseBall
	implements( GGExplosiveActorInterface )
	placeable;

/** If the bomb is already exploding it should not explode again */
var bool mIsExploding;

/** The momentum caused at an explosion */
var float mExplosiveMomentum;

/** The damage caused at an explosion */
var int mDamage;

/** The radius the explosion will affect */
var float mDamageRadius;

/** The damage type for the explosion */
var class< GGDamageTypeExplosiveActor > mDamageType;

/** The sound for the explosion */
var SoundCue mExplosionSound;

/** The particle effect for the explosion */
var ParticleSystem mExplosionEffectTemplate;

/** Class of ExplosionLight */
var class< UDKExplosionLight > mExplosionLightClass;

/** Where this actor is when it explodes */
var vector mExplosionLoc;

var bool isDestroyed;

function string GetActorName()
{
	return "Exploding Baseball";
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
	if(shouldIgnoreActor(target))
		return;

	Destroy();
}

/*
 * Make the ball explode when destroyed
 */
simulated event Destroyed()
{
	if(!isDestroyed)
	{
		isDestroyed=true;
		super.Destroyed();

		//WorldInfo.Game.Broadcast(self, "Boum!");
		Explode();
	}
}

function Explode()
{
	if( mIsExploding )
	{
		return;
	}

	mIsExploding = true;

	mExplosionLoc = Location;

	// Notify kismet and the game about the explosion
	TriggerEventClass( class'GGSeqEvent_Explosion', self );
	GGGameInfo( WorldInfo.Game ).OnExplosion( self );

	HurtRadius( mDamage, mDamageRadius, mDamageType, mExplosiveMomentum, Location, , GGGoat( Owner ).Controller );

	SpawnExplosionEffects();

	Shutdown();
}

simulated function SpawnExplosionEffects()
{
	if( mExplosionSound != none )
	{
		PlaySound( mExplosionSound, true, true );
	}

	if( mExplosionEffectTemplate != none )
	{
		WorldInfo.MyEmitterPool.SpawnEmitter( mExplosionEffectTemplate, Location );
	}

	if( mExplosionLightClass != none && UDKEmitterPool( WorldInfo.MyEmitterPool ) != none )
	{
		UDKEmitterPool( WorldInfo.MyEmitterPool ).SpawnExplosionLight( mExplosionLightClass, Location );
	}
}

function float GetDamageRadius()
{
	return mDamageRadius;
}

function vector GetExplosionLocation()
{
	return mExplosionLoc;
}

function int GetDamage()
{
	return mDamage;
}

function float GetExplosiveMomentum()
{
	return mExplosiveMomentum;
}

function Actor GetInstigator()
{
	return none;
}

DefaultProperties
{
	mExplosiveMomentum=50000.0f
	mDamage=100
	mDamageRadius=600.0f
	mDamageType=class'GGDamageTypeExplosiveActor'

	mExplosionSound=SoundCue'Goat_Sounds.Cue.Explosion_Car_Cue'
	mExplosionEffectTemplate=ParticleSystem'Goat_Effects.Effects.Projectile_Explosion_01'
	mExplosionLightClass=class'GGExplosionLight'
}