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
	WHEN (stage:liquidfuel/fullFuel)<0.15 AND STAGE:LIQUIDFUEL > 0 or ship:apoapsis>90000 then set thrott to 0.
	WHEN sBurnDist > radar - radarOffset THEN {
		SET runMode TO 3.		//hoverslam mode.
		SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //lower ship down while flying to launch pad
		SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).		//Landing burn starts
		WHEN SHIP:STATUS = "LANDED" THEN {
			SET runMode TO 0.	//End of program.
			SET updateSettings TO false.
			SET thrott TO 0.
			RCS OFF.
			sas on.
			CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
		}
	}
}

UNTIL stopLoop = true { //Main loop

	if(updateSettings=true){
		//set thrott to 1.
		LOCK STEERING TO HEADING(steeringDir,steeringPitch).
		LOCK THROTTLE TO thrott.
		SET updateSettings TO false.
		if (runMode = 3) AND (sBurnDist > radar - radarOffset) {		//Suicide burn. Mainly handled by WHEN statement earlier.
			set landWeight to ship:mass. 	//landing weight of booster.
			if landWeight< 10 set pidship to 5.
			else if landWeight > 10 set pidship to 10.
			else if landWeight > 20 set pidship to 20.
			SET eastVelPID:MINOUTPUT TO -pidship.
			SET eastVelPID:MAXOUTPUT TO pidship.
			SET northVelPID:MINOUTPUT TO -pidship.
			SET northVelPID:MAXOUTPUT TO pidship.
			SET steeringDir TO 0.
			SET steeringPitch TO 90.
			LOCK STEERING TO HEADING(steeringDir,steeringPitch).
			SET updateSettings TO false.
			brakes off.
			SET cardVelCached TO cardVel().
			steeringPIDs().
			if radar < 1000 {
					SAS OFF.
					RCS OFF.
					SET eastVelPID:MINOUTPUT TO -pidship.
					SET eastVelPID:MAXOUTPUT TO pidship.
					SET northVelPID:MINOUTPUT TO -pidship.
					SET northVelPID:MAXOUTPUT TO pidship.
				//	SET updateSettings TO false.
					SET cardVelCached TO cardVel().
				//SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //lower ship down while flying to launch pad
				SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).
				steeringPIDs().
				if radar<20 {
					SET thrott TO 0.
					sas on.			//to avoid booster tipping over. Thanks to u/noudje001 for spotting this.
					CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
			//		SET updateSettings TO false.
				}
			}
		}
	printData2().
	WAIT 0.01.
	}
}
function printData2 {
	PRINT "runMode: " + runMode AT(0,1).
	PRINT "radar: " + ROUND(radar, 2) AT(0,2).
}
