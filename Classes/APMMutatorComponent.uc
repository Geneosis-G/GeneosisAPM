class APMMutatorComponent extends GGMutatorComponent;

var GGMutator myMut;
var GGGoat gMe;
var AdvancedPitchingMachine mAPM;
var class<AdvancedPitchingMachine> apmType;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		myMut=owningMutator;
		gMe=goat;
		InitAPM( goat );
	}
}

function InitAPM( GGGoat goat )
{
	if( goat != none )
	{
		if(mAPM == none)
		{
			mAPM = myMut.Spawn (apmType,,, goat.Location,,,true);
		}
	}
}

event TickMutatorComponent(float DeltaTime)
{
	local GGPitchingMachineAbstract PM;

	super.TickMutatorComponent(DeltaTime);

	foreach gMe.BasedActors(class'GGPitchingMachineAbstract', PM)
	{
		//if the original PM is equiped, delete it
		if(AdvancedPitchingMachine(PM) == none)
		{
			PM.SetBase(none);
			PM.Shutdown();
		}
	}
}

DefaultProperties
{
	mAPM=none;
	apmType=class'AdvancedPitchingMachine';
}

