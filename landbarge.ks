//Autopilot 2.2 build 200219
//Boostback and landing script for reusable boosters with barge landing. Can be used for theoretically infinite boosters.
//Updates: Improved accuracy, but still can't precisely hit target. Recommended to try landing boosters on islands, this will be implemented in a future update.
clearscreen.

wait until ag5.
loaddist(500000).

set horizon to 0.
set fullfuel to 0.
set tval to 0.
SET radarOffset to 35. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+50.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(20, 90 * (1 - alt:radar / 25000)).
lock SPos to ship:geoposition.
set impact to ship:geoposition.
set landing to vessel("Of Course I Still Love You"):geoposition.
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
	wait until stage:liquidfuel/fullfuel < 0.05 OR ship:apoapsis > 89000.
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
		lock steering to heading(270,0).
		lock throttle to tval.
		set ship:name to "flyback".
		set kuniverse:activevessel to vessel("flyback").
		part2().
}

function part2 {
	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.
	print "Preparing for hoverslam...".
	lock steering to srfprograde.
	wait until ship:verticalspeed < -1.
	lock steering to landing:altitudeposition(5)*-1.
	//coast commands
	when impactTime > 15 then{	//Warping to make coast quicker.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		brakes on.
	}

	//Entry burn
//	wait until alt:radar < 20000.
	//set kuniverse:timewarp:rate to 0.
	//set tval to 1.
//	wait UNTIL ship:airspeed < 340.
//	set tval to 0.
//	set kuniverse:timewarp:rate to 4.

	when impactTime < 10 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
//	when impactTime < 8 then brakes on. //If your vessel has airbrakes.
	when impactTime < 2 then gear on.

	WAIT UNTIL trueRadar < stopDist.
		print "Performing hoverslam".
		LOCK tval to idealThrottle.
		lock steering to srfretrograde.

		WAIT UNTIL ship:verticalspeed > -10.
		lock throttle to (0.95 * ((9.81 * SHIP:MASS) / SHIP:availablethrust)).
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
