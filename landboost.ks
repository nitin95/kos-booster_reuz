//Bart Heavy Booster Landing Script: Without Trajectories
//By NitinM95, based on Caleb9000's original RTLS script.
CLEARSCREEN.

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
set runMode to 7.
set landWeight to 0.			//Notes final weight of booster right before landing.
set pidship to 0.					//adjusts landing PID's to make the script more flexible. see Runmode 3 scenario.
set fweight to 0.
set fullfuel to 0.
//global declaration makes it easier to use these variables.


from {local x is 10.} until x=-1 step{set x to x-1.} do{//countdown.
	print "T - " + x.
	wait 1.
	if x=0 set runMode to 6.
}

RUN land_lib.ks. 					//Includes the function library

SET steeringDir TO 90. 		//0-360, 0=north, 90=east
SET steeringPitch TO 90. 	// 90 is up
LOCK STEERING TO HEADING(steeringDir,steeringPitch).

set ship:control:pilotmainthrottle to 0.
SET thrott TO 0.
LOCK THROTTLE TO thrott.
SAS OFF.
RCS OFF.

LOCK radar TO alt:radar.
SET radarOffset TO 8.	//ship:altitude - radar.


//Launchpad selection. Edit based on your need.
SET launchPad TO SHIP:GEOPOSITION. 					//for landing on launchpad
//SET launchPad TO VESSEL("Of Course I Still Love You"):GEOPOSITION. 	//for barge landing. Change vessel name to your ASDS name.

lock targetDir TO ship:heading.
SET cardVelCached TO cardVel().
SET targetDistOld TO 0.

//g in m/s^2 at sea level.
SET g TO constant:G * BODY:Mass / BODY:RADIUS^2.

LOCK maxVertAcc TO SHIP:AVAILABLETHRUST / SHIP:MASS - g. 	//max acceleration in up direction the engines can create
LOCK vertAcc TO scalarProj(SHIP:SENSORS:ACC, UP:VECTOR).
LOCK dragAcc TO g + vertAcc. 					//vertical acceleration due to drag. Same as g at terminal velocity

LOCK sBurnDist TO SHIP:VERTICALSPEED^2 / (2 * (maxVertAcc + dragAcc/2)).

SET stopLoop TO false.
//RunModes: 0 = landed, 1 = final descent, 2 = hover/maneuver, 3 = suicide burn, 4 = coast, 5 = boostback, 6 = launching, 7 = Prelaunch
SET updateSettings TO true.

SET climbPID TO PIDLOOP(0.4, 0.3, 0.005, 0, 1). //Controls vertical speed
SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -15, 15). //Controls altitude by changing climbPID setpoint
SET hoverPID:SETPOINT TO 100. 			//Altitude about 40 meters above launch pad. Change to 50 for droneship landings if you want.
SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -35, 35). //Controls horizontal speed by tilting rocket
SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -35, 35).
SET eastPosPID TO PIDLOOP(1700, 0, 100, -30, 30). //controls horizontal position by changing velPID setpoints
SET northPosPID TO PIDLOOP(1700, 0, 100, -30, 30).
SET eastPosPID:SETPOINT TO launchPad:LNG.
SET northPosPID:SETPOINT TO launchPad:LAT.

WHEN runMode = 6 THEN {
	SET thrott TO 1.
	stage.															//stage 1 engines activation.
	wait 0.1.
	set fullfuel to stage:liquidfuel.		//Measures full tank fuel to determine percentage fuel remaining.
	set fWeight to ship:mass.
	SET updateSettings TO true.
	WHEN (ship:mass/fWeight)<0.6 or stage:liquidfuel/fullfuel<0.2 or ship:apoapsis>90000 THEN {
		SET runMode TO 5.
		wait 1.
		SET thrott TO 0.
		stage.		//switching to boostback
		SET updateSettings TO true.
		WHEN runMode = 4 THEN { //Coast phase
			SET updateSettings TO true.
			SET thrott TO 0.
			when radar>10000 then{	//Warping to make coast quicker.
				set kuniverse:timewarp:mode to "PHYSICS".
				set kuniverse:timewarp:rate to 4.}
			when radar<sburnDist + 10000 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
			WHEN sBurnDist > radar - radarOffset -100 AND SHIP:VERTICALSPEED < -5 THEN {//When there is barely enough time to perform hoverslam.
				SET runMode TO 3.		//hoverslam mode.
				SET updateSettings TO true.
				SET thrott to 1.		//Landing burn starts
				WHEN SHIP:VERTICALSPEED > -1 THEN { //When it has stopped falling
					//LOG "burn end alt: " + radar TO burn.txt.
					SET runMode TO 2.	//Finetuning mode
					GEAR ON.
					SET updateSettings TO true.
					WHEN geoDistance(SHIP:GEOPOSITION, launchPad) < 5 THEN { //When it is over the launch pad
						SET runMode TO 1.	//Final approach mode
						WHEN SHIP:STATUS = "LANDED" THEN {
							SET runMode TO 0.	//End of program.
							SET updateSettings TO true.
							SET thrott TO 0.
							RCS OFF.
						}
					}
				}
			}
		}
	}
}

UNTIL stopLoop = true { //Main loop
	if runMode = 6 {
		if updateSettings = true {
			set thrott to 1.
			LOCK STEERING TO HEADING(steeringDir,steeringPitch).
			LOCK THROTTLE TO thrott.
			SET updateSettings TO false.
			CLEARSCREEN.
		}
		if ship:VERTICALSPEED>20 GEAR OFF.
		set steeringPitch to max(45, 90 * (1 - radar / 35000)).
	if runMode = 5 { //boostback
		SET shipProVec TO (SHIP:VELOCITY:SURFACE * -1):NORMALIZED.
		if SHIP:VERTICALSPEED < -10 {
			SET launchPadVect TO (launchPad:POSITION):NORMALIZED. 	//vector with magnitude 1 from impact to landing pad
			SET rotateBy TO MIN(targetDist()*2, 20). 			//how many degrees to rotate the steeringVect
			PRINT "rotateBy: " + rotateBy at(0,7).
			SET steeringVect TO shipProVec * 40. //velocity vector lengthened
			SET loopCount TO 0.
			UNTIL (rotateBy - VANG(steeringVect, shipProVec)) < 2 { //until steeringVect gets close to desired angle
				PRINT "entered loop" at(0,9).
				if VANG(steeringVect, shipProVec) > rotateBy { 	//stop from overshooting
					PRINT "broke loop" at(0,9).
					BREAK.
				}
				if targetDist() > 1000 break.
				SET loopCount TO loopCount + 1.
				SET steeringVect TO steeringVect - launchPadVect. //essentially rotate steeringVect in small increments by subtracting the small vector.
			}
			PRINT "steeringAngle: " + VANG(steeringVect, shipProVec) at(0,8).
			LOCK STEERING TO steeringVect:DIRECTION.
		} else {
			LOCK STEERING TO (shipProVec):DIRECTION.
		}
		set landWeight to ship:mass. 	//landing weight of booster.
		if landWeight< 10 set pidship to 5.
		else if landWeight > 10 set pidship to 10.
		else if landWeight > 20 set pidship to 20.//this ensures steering PIDs are dependent on launcher, rather than a fixed value. Works for launchers in 1.25 and 2.5m class, 3.75 needs some testing.
		if radar < sBurnDist+(landweight*200) {
			brakes on.			//brakes engage at the last moment to avoid messing up Trajectories prediction.
		}
	}
	if runMode = 3 {		//Suicide burn. Mainly handled by WHEN statement earlier.
		if updateSettings = true {
			SET eastVelPID:MINOUTPUT TO -pidship.
			SET eastVelPID:MAXOUTPUT TO pidship.
			SET northVelPID:MINOUTPUT TO -pidship.
			SET northVelPID:MAXOUTPUT TO pidship.
			SET steeringDir TO 0.
			SET steeringPitch TO 90.
			LOCK STEERING TO HEADING(steeringDir,steeringPitch).
			SET updateSettings TO false.
			brakes off.
		}
		SET cardVelCached TO cardVel().
		steeringPIDs().
	}
	if runMode = 2 { //Powered flight to launch pad
		IF targetDist() > 100 set runmode to 1.
		if updateSettings = true {
			SAS OFF.
			RCS OFF.
			SET eastVelPID:MINOUTPUT TO -pidship.
			SET eastVelPID:MAXOUTPUT TO pidship.
			SET northVelPID:MINOUTPUT TO -pidship.
			SET northVelPID:MAXOUTPUT TO pidship.
			SET updateSettings TO false.
		}
		SET cardVelCached TO cardVel().
		SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //lower ship down while flying to launch pad
		SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
		steeringPIDs().
	}
	if runMode = 1 { //Final landing
		SET cardVelCached TO cardVel().
		steeringPIDs().
		SET climbPID:SETPOINT TO MAX(radar - radarOffset, 1.5) * -1.
		PRINT "climbPID:SETPOINT: " + climbPID:SETPOINT at(0,8).
		SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
	}
	if runMode = 0 {
		SET thrott TO 0.
		sas on.			//to avoid booster tipping over. Thanks to u/noudje001 for spotting this.
		SET updateSettings TO false.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
	}

	printData2().
	WAIT 0.01.
}
function printData2 {
	PRINT "runMode: " + runMode AT(0,1).
	PRINT "radar: " + ROUND(radar, 2) AT(0,2).
	PRINT "Impact point dist from pad: " + ROUND(targetDist(),2) at(0,6). }
}
