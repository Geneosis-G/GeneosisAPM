//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ExplodingRFA extends GGRadialForceActor
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

var EmitterPool mEmitterPool;
var ParticleSystem mDemonicParticleTemplate;
var ParticleSystemComponent mDemonicParticle;

var AudioComponent mAC;

var SoundCue mDemonicCue;

/*
 * Activate the black hole
 */
function ActivateRFA()
{
	//WorldInfo.Game.Broadcast(self, "Black Hole!");
	mEmitterPool = Spawn(class'EmitterPool');
	mDemonicParticle = mEmitterPool.SpawnEmitter(mDemonicParticleTemplate, Location, Rotation,);
	mAC = CreateAudioComponent( mDemonicCue, false );
	mAC.Play();
	ragdollNPCs(ForceRadius);
	SetTimer(5.0f, false, 'StopRFA');
	bForceActive = true;
}

function StopRFA()
{
	mEmitterPool.Destroy();
	Destroy();
}

function ragdollNPCs(float range)
{
	local GGNpc hitNPC;
	local TraceHitInfo hitInfo;

	foreach VisibleCollidingActors( class'GGNpc', hitNPC, range, Location,,,,, hitInfo )
	{
		hitNPC.SetRagdoll(true);
	}
}

/*
 * Make the black hole explode when destroyed
 */
simulated event Destroyed()
{
	super.Destroyed();
	
	//WorldInfo.Game.Broadcast(self, "Boum!");
	mAC.Stop();
	bForceActive = false;
	Explode();
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
	
	mDemonicParticleTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'

	mDemonicCue=SoundCue'Goat_Sound_Ambience_01.Cue.SummoningCircle_Cue'
	
	ForceRadius = 600
	ForceStrength = -1000
	bForceActive = false
}