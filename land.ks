//Autopilot 2.2.1 build 220219
//Boostback and landing script for reusable boosters to land at launchpad. Can be used for theoretically infinite boosters.
//Updates: Code optimization and fixed steering bug.

clearscreen.

wait until ag5.
loaddist(500000).

set horizon to 0.
set fullfuel to 1.
set tval to 0.
SET radarOffset to alt:radar. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+20.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(75, 90 * (1 - alt:radar / 25000)).
lock SPos to ship:geoposition.
set landing to ship:geoposition.
lock throttle to tval.

if alt:radar>10000 part2().
else{
	//
	wait 0.1.
	stage.
	set tval to 1.
	gear off.
	set fullfuel to stage:liquidfuel.
	wait 2.
	lock steering to heading(90, steeringPitch).
	wait until (stage:liquidfuel)/fullfuel < 0.2 OR ship:apoapsis > 89000.
		print "MECO".
		set tval to 0.
		sas off.
		wait 2.
		unlock steering.
		unlock throttle.
		ag10 on.
		stage.
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
	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.
	wait until eta:apoapsis<10.
		SET kuniverse:timewarp:rate to 0.
		print "Boostback".
		SET steeringDir TO landing:heading. 	//point towards landing pad
		SET steeringPitch TO 0.
		lock steering to heading(steeringDir,steeringPitch).
		wait until VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR) < 25.  //wait until pointing in right direction, saves fuel.
			SAS OFF.
			set tval TO 0.05.
		wait until VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR) < 10.  //wait until pointing in right direction, saves fuel.
			set tval TO 0.3.
		 	wait until ship:groundspeed > horizon*(1+(65/impactTime)).//The number varies between rockets. You might have to do some trial and error before you get the sweet spot.
			set tval to 0.
	print "Preparing for hoverslam...".
	lock steering to landing:altitudeposition(50)*-1.
	//coast commands
	when impactTime > 15 then{	//Warping to make coast quicker.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		brakes on.
	}
	when impactTime < 10 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
	when impactTime < 8 then brakes on. //Not necessary with grid fins
	when impactTime < 5 then lock steering to srfretrograde.
	when impactTime < 2 then gear on.

	WAIT UNTIL trueRadar < stopDist.
		print "Performing hoverslam".
		LOCK tval to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -5.
	lock throttle to (0.95 * ((9.81 * SHIP:MASS) / SHIP:availablethrust)).
	wait 1.
	lock steering to up.
	wait until ship:status = "landed".
		print "Hoverslam completed".
		LOCK throttle to 0.
		rcs on.
		sas on.
		set ship:name to "Booster".
		wait 1.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
}

function loaddist {
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
