//Autopilot 2.4.3 build
//Boostback and landing script for reusable boosters to land at launchpad. Can be used for theoretically infinite boosters.
//Updates:
//Boostback throttling rework to reduce fuel wastage.
//Added edge case for landing fully stock boosters.
//Autopilot now shuts down when splashed as well as landed.

clearscreen.
PRINT "RTLS Autopilot initializing" at (0,0).
until ag5 HUDTEXT("Press 5 to Fly", 5, 2, 15, green, false).
loaddist(500000).

HUDTEXT("GNC Booting", 5, 2, 15, green, false).
wait 1.

set horizon to 0.
set fullfuel to 1.
set tval to 0.
SET radarOffset to 30. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock twr to ship:availablethrust/ship:mass.
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+30.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(65, 90 * (1 - alt:radar / 25000)).
lock SPos to ship:geoposition.
set landing to ship:geoposition.
set asctime to 0.
lock lantime to missiontime+eta:apoapsis+asctime.
lock hdist to vxcl(up:vector, landing:position):mag.
lock throttle to tval.

clearscreen.
HUDTEXT("Variables Loaded", 5, 2, 15, green, false).
wait 1.
HUDTEXT("Go for Launch", 5, 2, 15, green, false).
wait 1.

if alt:radar>10000 part2().
else{	//
	clearscreen.
	wait 0.1.
	stage.
	lock tval to min(1,(2* g * SHIP:MASS) / (SHIP:availablethrust+0.01)).
	gear off.
	flightevent("Liftoff!").
	set fullfuel to stage:liquidfuel.
	wait 2.
	lock steering to heading(90, steeringPitch).
	wait 5.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
	wait until (stage:liquidfuel)/fullfuel < 0.2 OR ship:apoapsis > 89000.
		flightevent("MECO").
		set tval to 0.
		sas off.
		wait 2.
		unlock steering.
		unlock throttle.
		set asctime to missiontime.
		ag10 on.
		stage.
		flightevent("Stage Separation").
		if alt:radar>50000 ag6 on. //stages fairing, just in case.
		wait 1.
		rcs on.
		set horizon to abs(ship:groundspeed).
		lock steering to srfprograde.
		lock throttle to tval.
		set ship:name to "flyback".
		set kuniverse:activevessel to vessel("flyback").
		part2().
}

function part2 {
	SET kuniverse:timewarp:rate to 0.
	flightevent("Flip Maneuver").
	SET steeringDir TO landing:heading. 	//point towards landing pad
	SET steeringPitch TO 0.
	lock steering to heading(steeringDir,steeringPitch).
	flightevent("Boostback").
	set steerdiff to 0.
	lock steerdiff to VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR).
	until ship:groundspeed < 50{
		if steerdiff > 25 HUDTEXT("Press F if booster is stuck.", 5, 2, 15, green, false).
		if steerdiff < 25 set tval TO min((2* g * SHIP:MASS) / (SHIP:availablethrust+0.01),1/(steerdiff+0.01)). //wait until pointing in right direction, saves fuel.
		else set tval to 0.
	}
	until ship:groundspeed > (hdist/lantime)*1.2//Guesstimate of the groundspeed needed to get back to landing pad.
	{
		if eta:apoapsis < 5 or ship:verticalspeed < 0 lock lantime to missiontime.
		print hdist/lantime at (0,5).
		wait 0.1.
	}
	set tval to 0.
	flightevent("Preparing for Landing").
	lock steering to landing:altitudeposition(max(alt:radar-(ship:airspeed*impactTime),5))*-1.
	//coast commands
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		brakes on.
	UNTIL trueRadar < stopDist{
		if stockflag = 1 {//for non-grid fin rockets; use airbrakes to control descent speed for optimal aero steering.
			if ship:airspeed < 500 brakes off.
			else brakes on.
		}
		if impactTime < 10 {set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.

		if impactTime < 5 lock steering to srfretrograde.
		}
		clearscreen.
		flightevent("Performing Hoverslam").
		LOCK tval to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -10.
	lock steering to up.
	flightevent("Touching Down").
	gear on.
	until ship:status = "landed" or ship:status = "splashed"
	{
		if ship:verticalspeed < -5
		lock tval to ((1.2*(g * SHIP:MASS) / SHIP:availablethrust)).
		else lock tval to ((0.8*(g * SHIP:MASS) / SHIP:availablethrust)).
		wait 0.01.
	}
		flightevent("The booster has landed!").
		set throttle to 0.
		rcs on.
		sas on.
		set ship:name to "Booster".
		wait 1.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
}

function loaddist {	//Physics range hack from u/Ozin's code
	parameter dist.
	// Note the order is important.  set UNLOAD BEFORE LOAD,
	// and PACK before UNPACK.  Otherwise the protections in
	// place to prevent invalid values will deny your attempt
	// to change some of the values:
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNLOAD TO dist.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:LOAD TO dist-500.
	WAIT 0.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:PACK TO dist - 1.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNPACK TO dist - 1000.
	WAIT 0.

	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNLOAD TO dist.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:LOAD TO dist-500.
	WAIT 0.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:PACK TO dist - 1.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNPACK TO dist - 1000.
	WAIT 0.
}

function flightevent{
	parameter even.
	clearscreen.
	HUDTEXT("Current Event:"+even, 5, 2, 15, green, false).
	print"Current Event:"+even at (0,1).
}
