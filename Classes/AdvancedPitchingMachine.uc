class AdvancedPitchingMachine extends GGPitchingMachineContent
	implements(DoubleSkinInterface);

enum EAPMType
{
    EAPM_Exploding,
    EAPM_Compactor,
	EAPM_BlackHole,
    EAPM_Bouncing,
    EAPM_Repulsive,
    EAPM_Basic
};
var EAPMType currAPMType;

var MaterialInterface explodingMaterial;
var MaterialInterface compactorMaterial;
var MaterialInterface blackHoleMaterial;
var MaterialInterface bouncingMaterial;
var MaterialInterface repulsiveMaterial;

var float autoFireStartDelay;
var float autoFireInterval;
var float eraseDelay;
var bool isFireKeyPressed;
var bool isRateKeyPressed;
var float previewPressTime;

var bool isGuided;
var float guidedBBStartDelay;
var float mRange;
var GGCrosshairActor mCrosshairActor;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	ChangeType(EAPM_Exploding);
}

event Touch( Actor other, PrimitiveComponent otherComp, vector hitLocation, vector hitNormal)
{
	local GGGoat lastGoat;

	lastGoat=mGoat;
	super.Touch( other, otherComp, hitLocation, hitNormal );

	if(mGoat != lastGoat)
	{
		SkeletalMeshComponent.SetLightEnvironment( mGoat.mesh.lightenvironment );
		if(mCrosshairActor == none)
		{
			mCrosshairActor = mGoat.Spawn(class'GGCrosshairActor');
			mCrosshairActor.SetColor(MakeLinearColor( 0.0f, 0.0f, 1.0f, 1.0f ));
			mCrosshairActor.SetHidden(!isGuided);
		}
	}
}


function GGKActorBaseBallAbstract Pitch()
{
	local DoubleSkinBaseBall baseBall;

	baseBall=DoubleSkinBaseBall(super.Pitch());
	if(baseBall != none)
	{
		baseBall.SetOwner(mGoat);
		baseBall.SetSkin(SkeletalMeshComponent.Materials[0]);
		baseBall.GetTargetLoc=GetCrosshairLocation;
		baseBall.SetCollisionChainGoatNr( GGCollidableActorInterface( mGoat ) );
		if(isGuided)
		{
			baseBall.shouldAim=true;
		}
	}

	return baseBall;
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;
	local float pressTime, deltaTime;

	if(PCOwner != mGoat.Controller)
		return;

	localInput = GGPlayerInputGame( PlayerController( mGoat.Controller ).PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			isFireKeyPressed=true;

			if(isRateKeyPressed)
			{
				PotentialErase(true);
			}

			if(IsTimerActive(NameOf(AutoFire)))
			{
				ClearTimer(NameOf(AutoFire));
				return;
			}

			PotentialAutoFire(true);
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			isRateKeyPressed=true;

			if(isFireKeyPressed)
			{
				PotentialErase(true);

				pressTime=GetCurrentTimeMS();
				//WorldInfo.Game.Broadcast(self, "pressTime=" $ pressTime);
				if(previewPressTime > 0.f)
				{
					deltaTime=pressTime-previewPressTime;
					//WorldInfo.Game.Broadcast(self, "deltaTime=" $ deltaTime);
					if(deltaTime < 2.f)
					{
						if(deltaTime > 1.f)
						{
							deltaTime=1.f;
						}
						autoFireInterval=deltaTime;
					}
				}

				previewPressTime=pressTime;
			}
			//WorldInfo.Game.Broadcast(self, mGoat $ " lick, isRagdoll=" $ mGoat.mIsRagdoll);
			if(mGoat.mIsRagdoll)
			{
				SetTimer(guidedBBStartDelay, false, NameOf(SwitchGuidedBaseballs));
			}
		}

		// Trigger explosive balls
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			TriggerExplosions();
		}

		//switch APM
		if(newKey == 'LEFTCONTROL' || newKey == 'XboxTypeS_DPad_Down')
		{
			SwitchAPM();
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			isFireKeyPressed=false;
			PotentialAutoFire(false);
			PotentialErase(false);
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			isRateKeyPressed=false;
			PotentialErase(false);
			if(IsTimerActive(NameOf(SwitchGuidedBaseballs)))
			{
				ClearTimer(NameOf(SwitchGuidedBaseballs));
			}
		}
	}

	super.KeyState(newKey, keyState, PCOwner);
}

function TriggerExplosions()
{
	local ExplodingBB ebb;
	local CompactorBB cbb;
	local BlackHoleBB bhbb;

	if(currAPMType==EAPM_Exploding)
	{
		foreach AllActors(class'ExplodingBB', ebb)
		{
			ebb.Destroy();
		}
	}
	else if(currAPMType==EAPM_Compactor)
	{
		foreach AllActors(class'CompactorBB', cbb)
		{
			cbb.Destroy();
		}
	}
	else if(currAPMType==EAPM_BlackHole)
	{
		foreach AllActors(class'BlackHoleBB', bhbb)
		{
			bhbb.Destroy();
		}
	}
}

function float GetCurrentTimeMS()
{
	local float time;
	local int Year;
	local int Month;
	local int DayOfWeek;
	local int Day;
	local int Hour;
	local int Min;
	local int Sec;
	local int MSec;

	GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec);

	time=MSec/1000.f + Sec + Min*60.f + Hour*60.f*60.f + Day*60.f*60.f*24.f;

	return time;
}

function PotentialAutoFire(bool activate)
{
	if(IsTimerActive(NameOf(StartAutoFire)))
	{
		ClearTimer(NameOf(StartAutoFire));
	}

	if(activate)
	{
		SetTimer(autoFireStartDelay, false, NameOf(StartAutoFire));
	}
}

function StartAutoFire()
{
	AutoFire();
}

function AutoFire()
{
	Pitch();
	SetTimer(autoFireInterval, false, NameOf(AutoFire));
}

function PotentialErase(bool activate)
{
	if(IsTimerActive(NameOf(EraseBalls)))
	{
		ClearTimer(NameOf(EraseBalls));
	}

	if(activate)
	{
		SetTimer(eraseDelay, false, NameOf(EraseBalls));
	}
}

function EraseBalls()
{
	local GGKActorBaseBallAbstract tmpBall;

	//WorldInfo.Game.Broadcast(self, "erase");
	foreach AllActors( class'GGKActorBaseBallAbstract', tmpBall )
	{
		tmpBall.Shutdown();
		tmpBall.Destroy();
	}
}

function SwitchAPM()
{
	switch(currAPMType)
	{
		case EAPM_Exploding:
			ChangeType(EAPM_Compactor);
			break;
	    case EAPM_Compactor:
	    	ChangeType(EAPM_BlackHole);
	    	break;
		case EAPM_BlackHole:
			ChangeType(EAPM_Repulsive);
			break;
	    case EAPM_Repulsive:
	    	ChangeType(EAPM_Bouncing);
	    	break;
	    case EAPM_Bouncing:
	    	ChangeType(EAPM_Basic);
	    	break;
	    case EAPM_Basic:
	    	ChangeType(EAPM_Exploding);
	    	break;
	}
}

function ChangeType(EAPMType type)
{
	currAPMType=type;
	switch(currAPMType)
	{
		case EAPM_Exploding:
			SetSkin(explodingMaterial);
			mBaseBaseClass=class'ExplodingBB';
			WorldInfo.Game.Broadcast(self, "Exploding APM");
			break;
	    case EAPM_Compactor:
	    	SetSkin(compactorMaterial);
	    	mBaseBaseClass=class'CompactorBB';
	    	WorldInfo.Game.Broadcast(self, "Compactor APM");
	    	break;
		case EAPM_BlackHole:
			SetSkin(blackHoleMaterial);
			mBaseBaseClass=class'BlackHoleBB';
			WorldInfo.Game.Broadcast(self, "Black Hole APM");
			break;
	    case EAPM_Repulsive:
	    	SetSkin(repulsiveMaterial);
	    	mBaseBaseClass=class'RepulsiveBB';
	    	WorldInfo.Game.Broadcast(self, "Repulsive APM");
	    	break;
		case EAPM_Bouncing:
	    	SetSkin(bouncingMaterial);
	    	mBaseBaseClass=class'BouncingBB';
	    	WorldInfo.Game.Broadcast(self, "Bouncing APM");
	    	break;
	    case EAPM_Basic:
	    	SetSkin(none);
	    	mBaseBaseClass=class'DoubleSkinBaseBall';
	    	WorldInfo.Game.Broadcast(self, "Basic APM");
	    	break;
	}
}

function SetSkin(MaterialInterface newMat)
{
	SkeletalMeshComponent.SetMaterial(0, newMat);
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if(isGuided)
	{
		UpdateCrosshair();
	}
}

function vector GetCrosshairLocation()
{
	return mCrosshairActor.Location;
}

function SwitchGuidedBaseballs()
{
	isGuided=!isGuided;
	mCrosshairActor.SetHidden(!isGuided);
}

function UpdateCrosshair()
{
	local vector			StartTrace, EndTrace, AdjustedAim, socketLocation, camLocation;
	local rotator 			socketRotation, camRotation;
	local Array<ImpactInfo>	ImpactList;
	local ImpactInfo 		RealImpact;
	local float 			Radius;

	if(mGoat != None)
	{
		SkeletalMeshComponent.GetSocketWorldLocationAndRotation( mPitchingSocketName, socketlocation, socketRotation );
		StartTrace = socketLocation;

		GGPlayerControllerGame( mGoat.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
		camRotation.Pitch+=1800.f;
		AdjustedAim = vector(camRotation);

		Radius = mCrosshairActor.SkeletalMeshComponent.SkeletalMesh.Bounds.SphereRadius;
		EndTrace = StartTrace + AdjustedAim * (mRange - Radius);

		RealImpact = CalcWeaponFire(StartTrace, EndTrace, ImpactList);

		mCrosshairActor.UpdateCrosshair(RealImpact.hitLocation, -AdjustedAim);
	}
}

simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList)
{
	local vector			HitLocation, HitNormal;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local ImpactInfo		CurrentImpact;

	HitActor = CustomTrace(HitLocation, HitNormal, EndTrace, StartTrace, HitInfo);

	if( HitActor == None )
	{
		HitLocation	= EndTrace;
	}

	CurrentImpact.HitActor		= HitActor;
	CurrentImpact.HitLocation	= HitLocation;
	CurrentImpact.HitNormal		= HitNormal;
	CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
	CurrentImpact.StartTrace	= StartTrace;
	CurrentImpact.HitInfo		= HitInfo;

	ImpactList[ImpactList.Length] = CurrentImpact;

	return CurrentImpact;
}

function Actor CustomTrace(out vector HitLocation, out vector HitNormal, vector EndTrace, vector StartTrace, out TraceHitInfo HitInfo)
{
	local Actor hitActor, retActor;

	foreach TraceActors(class'Actor', hitActor, HitLocation, HitNormal, EndTrace, StartTrace, ,HitInfo)
    {
		if(AdvancedPitchingMachine(hitActor) == none && GGKActorBaseBallAbstract(hitActor) == none && hitActor != mGoat && !hitActor.bHidden)
		{
			retActor=hitActor;
			break;
		}
    }

    return retActor;
}

simulated event Destroyed()
{
 	mCrosshairActor.DestroyCrosshair();

	super.Destroyed();
}

DefaultProperties
{
	autoFireStartDelay=1.f
	autoFireInterval=1.f
	eraseDelay=3.f
	guidedBBStartDelay=3.f

	mRange=10000.f

	explodingMaterial=Material'Props_01.Materials.Bicycle_Red'
	compactorMaterial=Material'Props_01.Materials.Bicycle_Green'
	blackHoleMaterial=Material'Props_01.Materials.Bicycle_Black_Mat_01'
	repulsiveMaterial=Material'Props_01.Materials.Bicycle_Yellow_Mat';
	bouncingMaterial=Material'Camper.Materials.CrystalBreath_Mat'

	bNoDelete=false
	mBaseBaseClass=class'DoubleSkinBaseBall'
	DrawScale=0.75f
}
