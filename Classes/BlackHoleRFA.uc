//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BlackHoleRFA extends GGRadialForceActor;

var EmitterPool mEmitterPool;
var ParticleSystem mDemonicParticleTemplate;
var ParticleSystemComponent mDemonicParticle;

var AudioComponent mAC;

var SoundCue mDemonicCue;

var float destroyRange;

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
	SetTimer(5.0f, false, 'StopRFA');
	bForceActive = true;
}

function StopRFA()
{
	mEmitterPool.Destroy();
	Destroy();
}

/*
 * Stop the black hole
 */
simulated event Destroyed()
{
	super.Destroyed();

	//WorldInfo.Game.Broadcast(self, "Boum!");
	mAC.Stop();
	bForceActive = false;
}

/*
 * Detect objects in range
 */
event Tick(float DeltaTime)
{
	local Actor hitActor;
	local TraceHitInfo hitInfo;

	super.Tick(DeltaTime);

	foreach VisibleCollidingActors( class'Actor', hitActor, destroyRange, Location,,,,, hitInfo )
	{
		//WorldInfo.Game.Broadcast(self, "Actor found "$hitActor);
		desintegrate(hitActor);
	}
}

/*
 * Destroy the object
 */
function desintegrate(Actor other)
{
	local GGKactor kActor;
	local GGNpc npc;
	local GGInterpActor interpActor;
	local GGApexDestructibleActor adActor;
	local GGSVehicle vehicle;
	local GGKAsset asset;
	local bool canBeDestroyed;
	local int i;

	kActor = GGKActor( Other );
	npc = GGNpc( Other );
	interpActor = GGInterpActor( Other );
	adActor = GGApexDestructibleActor(other);
	vehicle = GGSVehicle(other);
	asset = GGKAsset(other);

	canBeDestroyed=false;
	if( kActor != none )
	{
		canBeDestroyed=true;
	}
	else if( npc != none )
	{
		npc.SetRagdoll(false);
		canBeDestroyed=true;
	}
	else if( interpActor != none )
	{
		canBeDestroyed=true;
	}
	else if( adActor != none )
	{
		canBeDestroyed=true;
	}
	else if(vehicle != none)
	{
		canBeDestroyed=true;
	}
	else if(asset != none)
	{
		canBeDestroyed=true;
	}
	else
	{
		//WorldInfo.Game.Broadcast(self, "Object detected: "$other);
	}

	if(canBeDestroyed)
	{
		for( i = 0; i < other.Attached.Length; i++ )
		{
			if(GGGoat(other.Attached[i]) == none)
			{
				other.Attached[i].ShutDown();
				other.Attached[i].Destroy();
			}
		}
		//Haxx to force destruction if the Destroy function is not enough
		other.SetPhysics(PHYS_None);
		other.SetHidden(true);
		other.SetLocation(vect(0, 0, -1000));
		other.Shutdown();
		other.Destroy();
	}
}

DefaultProperties
{
	mDemonicParticleTemplate=ParticleSystem'Goat_Effects.Effects.DemonicPower'

	mDemonicCue=SoundCue'Goat_Sound_Ambience_01.Cue.SummoningCircle_Cue'

	ForceRadius = 600
	ForceStrength = -1000
	bForceActive = false

	destroyRange=6;
}