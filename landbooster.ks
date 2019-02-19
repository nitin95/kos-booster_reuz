//Autopilot 2.2 build 200219
//Boostback and landing script for reusable strapon boosters. Can be used for theoretically infinite boosters.

clearscreen.

wait until ag5.
loaddist(500000).

global oldD is 0.
global oldT is time:seconds.

set horizon to 0.
set fullfuel to 1.
set tval to 0.
SET radarOffset to alt:radar*0.3. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+50.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(75, 90 * (1 - alt:radar / 25000)).
lock SPos to ship:geoposition.
set impact to ship:geoposition.
set landing to ship:geoposition.
lock impact to impactPoint().
LOCK targetDir TO geoDir(impact, landing).
lock targetDist to distance(impact,landing).
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
		PRINT targetDist.
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
//	set kuniverse:activevessel to vessel("flyback"). //doesn't work in atmo.
	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.
	wait until eta:apoapsis<10.
		SET kuniverse:timewarp:rate to 0.
		print "Boostback".
		SET steeringDir TO 270. 	//point towards landing pad
		SET steeringPitch TO 0.
		lock steering to heading(270,0).
		wait until VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR) < 10.  //wait until pointing in right direction, saves fuel.
			set tval TO 0.3.
			print targetDist.
		 	wait until ship:groundspeed > horizon*(1+(70/impactTime)).//
			set tval to 0.
	print "Preparing for hoverslam...".
	lock steering to landing:altitudeposition(100)*-1.
	//coast commands
	when impactTime > 15 then{	//Warping to make coast quicker.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		brakes on.
	}
	when impactTime < 10 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
//	when impactTime < 8 then brakes on. //Not necessary with grid fins
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

function geoDir {
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
}

function distance {
  declare parameter pos1, pos2.
  local dif to V(pos1:lat - pos2:lat, pos1:lng - pos2:lng, 0).
  return dif:mag.
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

function impactPoint {
    local tti is impactTime.

    local impactUT is time + tti.
    local impactVec is positionat(ship, impactUT).

    local ll is body:geoPositionOf(impactVec).
    local lon is ll:lng - (body:angularVel:mag * Constant:RadToDeg * tti).

    return latlng(ll:lat, lon).
}
