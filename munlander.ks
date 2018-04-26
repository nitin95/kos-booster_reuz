function updateReadouts{
	print "Step: "+step+"          " AT(0,0).
	print "Steering Direction = "+round(steeringDir,3)+"          " AT(0,2).
	print "Pitch = "+round(shipPitch,3)+"          " AT(0,3).
	print "Ground speed = "+round(SHIP:GROUNDSPEED,3)+"          " AT(0,4).
	print genoutputmessage+"                           " AT(0,6).
}

RUN functions.ks. //Includes the function library

CLEARSCREEN.
//Auto open terminal.
//CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").



//Variables
if(DEFINED step){
	//step is already set
}else{
	//SET step TO "BoosterReturn".
	//SET step TO "BoosterRetroBurnWait".
	//SET step TO "BoosterReentry".
	//SET step TO "BoosterReentryBurn".
	//SET step TO "BoosterLandBurn".
	
	SET step TO "Launch".
	//SET step TO "WaitKerbinCircularize".
	//SET step TO "MunInjectBurn".
	//SET step TO "WarpToMunInject".
	//SET step TO "WarpToMunEncounter".
	//SET step TO "AdjustMunPeriapsis".
	//SET step TO "MunCircularize".
	//SET step TO "MunWarpToLandBurn".
	//SET step TO "MunWarpToLandBurnWait".
	//SET step TO "WaitForSuicideBurn". 
}


SET looping TO TRUE.
SET thrott TO 0.
SET steeringDir TO 90.
SET shipPitch TO 90.
SET targetAP TO 0.
SET b_fairingDeployed TO false.
SET bodyTarget TO Body("Mun").
SET genoutputmessage TO "".
SET targetMunVessel TO VESSEL("Farside Tower Ship").
SET munLandTarget TO Mun:GEOPOSITIONLATLNG(targetMunVessel:GEOPOSITION:LAT-0.006,targetMunVessel:GEOPOSITION:LNG).

//VAB ROOF
SET boosterLandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.0968021288249016,-74.6187406216331).
SET boosterLandAltitude TO 220.

//LAUNCHPAD
//SET boosterLandTarget TO Kerbin:GEOPOSITIONLATLNG(-0.0971980934745649,-74.5576639199546).
//SET boosterLandAltitude TO 115.

//Locks
LOCK THROTTLE TO thrott.
LOCK STEERING TO HEADING(steeringDir,shipPitch).


UNTIL looping = false {

	updateReadouts(). //update all readouts
	
	if(step="Launch"){	
		STAGE.
		BRAKES OFF.
		SAS OFF.
		LIGHTS OFF.
		RCS OFF.
		SET thrott TO 1. //full throttle
		SET step TO "InitClimb".
	}
	
	if(step="InitClimb"){	
		if SHIP:VERTICALSPEED>80{
			SET step TO "GravityTurn".
		}
	}
	
	if(step="GravityTurn"){
		wait 0.2. //combine wait with pitch change to get nice gravity turn
		if(shipPitch>1){
			SET shipPitch To shipPitch-0.2.
		}		
		
		if(SHIP:APOAPSIS>70000){
			SET thrott TO 0.2.
		}
		
		if(SHIP:APOAPSIS>80100){
			SET thrott TO 0.
			SET step TO "WaitKerbinCircularize".
		}
	}
	
	if(step="WaitKerbinCircularize"){
		if(b_fairingDeployed=false and SHIP:ALTITUDE>55000){
			SET b_fairingDeployed TO true.
			STAGE.
		}
		SET shipPitch To 0.
		if(eta:apoapsis<5){
			SET thrott TO 1.
			SET shipPitch To 0.
			SET step TO "KerbinCircularize".
			SET targetAP TO SHIP:APOAPSIS+1500.
		}
	}
	
	if(step="KerbinCircularize"){
		if(SHIP:PERIAPSIS>20000){
			SET thrott TO 0.2.
		}else{
			SET thrott TO 1.
		}
		if(eta:apoapsis>500){
			SET shipPitch To 6. //pitch up
		}else{
			SET shipPitch To -1. //pitch down
		}
		if(targetAP < SHIP:APOAPSIS){
			SET thrott TO 0.
			SET step TO "Deploy".
		}
	}
	
	if(step="Deploy"){
		AG10 ON. //solar
		wait 4.
		AG9 ON. //comms
		WAIT 2.
		STAGE. //drop booster
		WAIT 2.
		STAGE. //engage engines for stage 2.
		SET thrott TO .2.
		WAIT 3.
		SET thrott TO 0.
		WAIT 3.
		SET step TO "WarpToMunInject".
	}
	
	if(step="WarpToMunInject"){
		SET kuniverse:timewarp:mode to "RAILS".
		SET kuniverse:timewarp:warp to 3.
		SET step TO "WaitMunInject".
	}
	
	if(step="WaitMunInject"){
		SET steeringDir TO VANG(SHIP:PROGRADE:VECTOR, SHIP:UP:VECTOR). // point prograde
		SET shipPitch TO 0.
		SET munPhaseAngle TO getPhaseAngleToTarget(bodyTarget).
		SET kerbinVectMunDiff TO getKerbinOrbitAngleToTarget(bodyTarget).
		SET genoutputmessage TO round(munPhaseAngle,2)+" "+round(kerbinVectMunDiff,2).
		if(munPhaseAngle<25 AND kerbinVectMunDiff<80){
			SET kuniverse:timewarp:warp to 0.
			until kuniverse:timewarp:issettled {
				wait 1.
			}
			WAIT 8. //wait for vessel to turn
			SET step TO "MunInjectBurn".
			SET thrott TO 1.
		}
	}
	
	if(step="MunInjectBurn"){
		if(SHIP:ORBIT:TRANSITION="ENCOUNTER"){
			SET thrott TO 0.05.
			if(ship:orbit:nextpatch:periapsis<20000){
				SET thrott TO 0.
				WAIT 0.5.
				SET kuniverse:timewarp:warp to 5.			
				if(SHIP:BODY:NAME="Mun"){
					SET step TO "WarpToMunEncounter".
				}
			}
		}
		SET genoutputmessage TO "Orbit Transition: "+SHIP:ORBIT:TRANSITION.
	}
	
	if(step="WarpToMunEncounter"){
		SET kuniverse:timewarp:warp to 0.
		until kuniverse:timewarp:issettled {
			wait 1.
		}
		if(SHIP:PERIAPSIS>10000){
			LOCK STEERING TO getVectorRadialin().
		}else{
			LOCK STEERING TO getVectorRadialout().
		}
		WAIT 10.
		SET step TO "AdjustMunPeriapsis".	
	}
	
	if(step="AdjustMunPeriapsis"){
		SET genoutputmessage TO "Periapsis: "+CEILING(SHIP:PERIAPSIS)+"m".
		if(ABS(10000-SHIP:PERIAPSIS)>20000){
			SET thrott to 1.
		}else{
			SET thrott to 0.1.
		}
		if(SHIP:PERIAPSIS>10000 and SHIP:PERIAPSIS<11000){

			SET thrott to 0.
			LOCK STEERING TO SHIP:RETROGRADE:VECTOR.
			
			kuniverse:timewarp:warpto(time:seconds + ETA:PERIAPSIS - 40).
			UNTIL(ETA:PERIAPSIS<28) {
				wait 0.1.
			}
			SET step TO "MunCircularize".
			
		}
	}
	
	if(step="MunCircularize"){
		SET genoutputmessage TO "Eta Periapsis "+CEILING(ETA:PERIAPSIS).
		SET thrott to 1.
		if(SHIP:PERIAPSIS<8000){
			SET thrott TO 0.
			SET step TO "MunWarpToIncAdjustLandBurnWait".
		}
	}
	
	if(step="MunWarpToIncAdjustLandBurnWait"){
		//adjust inclination
		if(defined incAdjust=FALSE){
			if(getOrbitLongitude()>getBodyAscendingnodeLongitude()){
				SET incAdjust TO "DN".
				LOCK STEERING TO getVectorNormal().
				//warp to descending node.
			}else{
				SET incAdjust TO "AN".
				LOCK STEERING TO getVectorAntinormal().
				//warp to ascending node.
			}
			WAIT 10.
		}else{
			if(incAdjust="AN") { SET lngDiff TO ABS(getOrbitLongitude()-getBodyAscendingnodeLongitude()). }
			if(incAdjust="DN") { SET lngDiff TO ABS(getOrbitLongitude()-getBodyDescendingnodeLongitude()). }
			if(lngDiff<10){
				SET kuniverse:timewarp:warp to 2.
			}else{
				SET kuniverse:timewarp:warp to 3.
			}
			if(lngDiff<3){ //just need to offset a little due to timewarp lag.
				SET kuniverse:timewarp:warp to 0.
				until kuniverse:timewarp:issettled {
					wait 1.
				}
				SET step TO "AdjustInclination".
			}
		}
		SET genoutputmessage TO "Longitude - Current:"+round(getOrbitLongitude(),2)+
			", AN:"+round(getBodyAscendingnodeLongitude(),2)+", DN:"+round(getBodyDescendingnodeLongitude(),2).
	}
	
	if(step="AdjustInclination"){
		if(defined prevInc=FALSE){
			SET prevInc TO SHIP:ORBIT:inclination.
		}
		SET thrott TO 0.5.
		if(round(SHIP:ORBIT:inclination,3)>round(prevInc,3)){
			SET thrott TO 0.
			wait 1.
			SET step TO "MunWarpToLandBurn".
		}else{
			SET prevInc TO SHIP:ORBIT:inclination.
		}
		SET genoutputmessage TO "Inclination:"+round(SHIP:ORBIT:inclination,3).
	}
	
	if(step="MunWarpToLandBurn"){
		SET kuniverse:timewarp:warp to 3.
		SET step TO "MunWarpToLandBurnWait".
	}
	
	if(step="MunWarpToLandBurnWait"){
		LOCK STEERING TO SHIP:RETROGRADE:VECTOR.
		SET geoDist TO calcDistance(targetMunVessel:GEOPOSITION, SHIP:GEOPOSITION).
		SET genoutputmessage TO "Geo Distance to Target: "+CEILING(geoDist)+"m".
		if(geoDist<48000){
			SET kuniverse:timewarp:warp to 0.
			until kuniverse:timewarp:issettled {
				wait 1.
			}
			if(geoDist<28000){
				SET thrott TO 1.
				SET step TO "MunLandBurn".
			}
		}
	}
	
	if(step="MunLandBurn"){
		if(ADDONS:TR:HASIMPACT){
			SET impactDist TO calcDistance(munLandTarget, ADDONS:TR:IMPACTPOS).
			SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, munLandTarget).
			SET genoutputmessage TO "ImpactDist: "+CEILING(impactDist)+"m  Target Direction: "+CEILING(targetDir).
			SET steeringDir TO targetDir - 180.
			LOCK STEERING TO HEADING(steeringDir,1). //pitch of 1
			
			if(impactDist<200){
				SET thrott TO 0.
				SET step TO "WaitForSuicideBurn".
				
			}else if(impactDist<600){
				SET thrott TO 0.3.
			}
		}else{
			SET genoutputmessage TO "No Impact".
		}
	}
	
	if(step="WaitForSuicideBurn"){
		LOCK STEERING TO getVectorSurfaceRetrograde().
		if(SHIP:ALTITUDE<5000){
			LIGHTS ON.
			setHoverPIDLOOPS(). //you can manually set them, but these are some good defaults.
			setHoverTarget(munLandTarget:LAT,munLandTarget:LNG).
			setHoverMaxSteerAngle(50).
			setHoverMaxHorizSpeed(7).
			SET step TO "suicideburn".
		}
	}
	
	if(step="suicideburn"){
		RCS ON.
		GEAR ON. //landing legs
		SET maxDescendSpeed TO 100.
		if(ALT:RADAR<1600){
			SET maxDescendSpeed TO 20.
		}
		if(ALT:RADAR<70){
			SET maxDescendSpeed TO 4.
		}
		
		setHoverDescendSpeed(maxDescendSpeed). //set PID to control descent

		SET terrainAlt TO SHIP:ALTITUDE-ALT:RADAR.
		SET geoDist TO calcDistance(munLandTarget, SHIP:GEOPOSITION).
		if(shipPitch>80 AND SHIP:GROUNDSPEED<3){
			setHoverTarget(SHIP:GEOPOSITION:LAT,SHIP:GEOPOSITION:LNG).
			setHoverAltitude(terrainAlt-10). //time to land
		}else{
			setHoverAltitude(terrainAlt+40). //hover above surface until we are stable
		}
		
		if(ABS(SHIP:VERTICALSPEED)>80){
			//main suicide burn to wipe off most velocity			
			LOCK STEERING TO getVectorSurfaceRetrograde().
			SET genoutputmessage TO "Max V-speed: "+CEILING(maxDescendSpeed)+", Target Dist: "+CEILING(geoDist).
		}else{
			//final landing
			updateHoverSteering(). //will automatically steer the vessel towards the target.
			SET genoutputmessage TO "Target Steer, Terrain Alt: "+CEILING(ALT:RADAR)+", Target Dist: "+CEILING(geoDist).
		}
		
		if(ADDONS:TR:HASIMPACT){
			//Still landing
		}else{
			SET step TO "end".
		}
	}
	
	
	
	
	

	if(step="BoosterReturn"){
		//Booster needs way more torque than default to actually move - Thanks Pand5461! :)
		//Default is 1.
		set STEERINGMANAGER:pitchtorquefactor to 5.
		set STEERINGMANAGER:yawtorquefactor to 5.
		set STEERINGMANAGER:rolltorquefactor to 5.
		set STEERINGMANAGER:MAXSTOPPINGTIME to 1. //default=2
		
		SET STEERING TO SHIP:RETROGRADE:VECTOR.
		RCS ON.
		
		SET step TO "BoosterReturnTurn".
	}
	
	if(step="BoosterReturnTurn"){
		SET orbitAngle TO VANG(SHIP:PROGRADE:VECTOR, boosterLandTarget:POSITION). // point prograde
		
		SET geoDist TO calcDistance(boosterLandTarget, SHIP:GEOPOSITION).
		SET kuniverse:timewarp:mode to "RAILS".
		SET kuniverse:timewarp:warp to 4.
		SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist)+", angToKSC: "+CEILING(orbitAngle).
		if(geoDist<600000 AND orbitAngle<55){
			SET kuniverse:timewarp:warp to 0.
			until kuniverse:timewarp:issettled {
				wait 1.
			}
			SET step TO "BoosterRetroBurnWait".		
		}
	}
	
	if(step="BoosterRetroBurnWait"){
		SET STEERING TO SHIP:RETROGRADE:VECTOR.

		RCS ON.
		SET geoDist TO calcDistance(boosterLandTarget, SHIP:GEOPOSITION).
		if(geoDist<360000){	
			SET thrott TO 1.
			
			until(ADDONS:TR:HASIMPACT){ 
				wait 0.2.
			}
			RCS OFF. WAIT 0.2.
			SET step TO "BoosterReentryBurn".			
		}
		SET genoutputmessage TO "KSC Distance: "+CEILING(geoDist).
	}
	
	if(step="BoosterReentryBurn"){
		SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, boosterLandTarget).
		SET impactDist TO calcDistance(boosterLandTarget, ADDONS:TR:IMPACTPOS).
		SET steeringDir TO targetDir - 180.
		LOCK STEERING TO HEADING(steeringDir,1).
		if(impactDist < 30000){
			SET thrott TO 0.2.
		}
		if(impactDist < 15000){
			SET thrott TO 0.
			SET step TO "BoosterReentry".
		}
		SET genoutputmessage TO "Impact dist: "+CEILING(impactDist).
	}
	
	if(step="BoosterReentry"){
		UNLOCK STEERING.
		SET geoDist TO calcDistance(boosterLandTarget, SHIP:GEOPOSITION).
		SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, boosterLandTarget).
		SET impactDist TO calcDistance(boosterLandTarget, ADDONS:TR:IMPACTPOS).
		if(SHIP:ALTITUDE<22000 AND SHIP:GROUNDSPEED>1350){
			SET steeringDir TO targetDir - 180.
			LOCK STEERING TO HEADING(steeringDir,20). //pitch 20 (about where it would be at this point anyway)
			SET thrott TO 1.
		}else{
			LOCK STEERING TO SHIP:RETROGRADE:VECTOR.
			SET thrott TO 0.
		}
		if(SHIP:GROUNDSPEED<1700){
			BRAKES ON. //airbrakes
		}else{
			BRAKES OFF.
		}
		if(geoDist<2300){
			SET step TO "BoosterLandBurn".
		}
		SET genoutputmessage TO "Impact from target: "+CEILING(impactDist).
	}	
	
	if(step="BoosterLandBurn"){
		SET targetDir TO geoDir(ADDONS:TR:IMPACTPOS, boosterLandTarget).
		SET impactDist TO calcDistance(boosterLandTarget, ADDONS:TR:IMPACTPOS).
		SET steeringDir TO targetDir - 180.
		LOCK STEERING TO HEADING(steeringDir,20).
		
		if(impactDist<150){ //overshoot just a little
			SET thrott TO 0.
			wait 1.
			SET step TO "BoosterLand".
			
			setHoverPIDLOOPS(). //you can manually set them, but these are some good defaults.
			setHoverTarget(boosterLandTarget:LAT,boosterLandTarget:LNG).
		
		}else if(impactDist<300){
			SET thrott TO 0.2.
		}else{
			SET thrott TO 1.
		}

		SET genoutputmessage TO "Impact dist from target: "+ROUND(impactDist,2).
	}
	
	if(step="BoosterLand"){
		RCS ON.
		SET geoDist TO calcDistance(boosterLandTarget, SHIP:GEOPOSITION).
		setHoverMaxSteerAngle(5).
		if(SHIP:ALTITUDE<600){
			setHoverMaxHorizSpeed(5).
		}else{
			setHoverMaxHorizSpeed(60).
		}
		
		if(geoDist<10 AND SHIP:ALTITUDE<300 AND shipPitch>85 AND SHIP:GROUNDSPEED<3){ //time to touchdown
			setHoverAltitude(boosterLandAltitude). //set altitude to hover at.
			SET distAltitude TO SHIP:ALTITUDE-boosterLandAltitude.
			SET distAltToStartBreak TO 90.
			if(distAltitude<distAltToStartBreak){
				SET maxDescendSpeed TO 10.
				SET descendSpeed TO (maxDescendSpeed/distAltToStartBreak) * distAltitude.
				if(descendSpeed<0.5){ SET descendSpeed TO 0.5.}
				setHoverDescendSpeed(descendSpeed).
			}
		}else{
			setHoverAltitude(boosterLandAltitude+30). //set altitude to hover at.
			SET maxDescendSpeed TO 100.
			setHoverDescendSpeed(maxDescendSpeed).
		}
		
		updateHoverSteering(). //will automatically steer the vessel towards the target.
				
		SET genoutputmessage TO "Distance from target: "+CEILING(geoDist).
		
		if(ADDONS:TR:HASIMPACT){
			//Still landing
		}else{
			SET step TO "end".
		}
	}
	
	if(step="end"){
		SET thrott TO 0.
		SET looping TO false.
		
		UNLOCK STEERING.
		wait 1.
		AG8 ON.
		wait 1.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		WAIT 1.
		RCS OFF.
		WAIT 1.
	}
}
