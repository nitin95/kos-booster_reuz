//Autopilot 2.0.5 build 200718
//Boostback and landing script for reusable boosters. Can be used for theoretically infinite boosters.
//Updates: New boostback algo and workflow.
clearscreen.

set horizon to 0.
set fullfuel to 0.
set tval to 0.
SET radarOffset to alt:radar*-0.6. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(80, 90 * (1 - alt:radar / 25000)).
lock SPos to ship:geoposition.
set impact to ship:geoposition.
set landing to ship:geoposition.
lock latt to arcsin(sin(SPos:lat)*cos(impactDist)+cos(SPos:lat)*sin(impactDist)*cos(270)).
lock lone to mod(SPos:lng-arccos(sin(impactDist)/cos(SPos:lat))+3.14,2*3.14)-3.14.
lock impact to latlng(latt,lone).
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
	wait until stage:liquidfuel/fullfuel < 0.1 OR ship:apoapsis > 89000.
		print "MECO".
		PRINT targetDist.
		set tval to 0.
		sas off.
		wait 2.
		unlock steering.
		unlock throttle.
		stage.
		if alt:radar>50000 ag6 on. //stages fairing, just in case.
		wait 1.
		rcs on.
		set horizon to abs(ship:groundspeed).
		lock steering to heading(270,0).
		lock throttle to tval.
		part2().
}

function part2 {
	set ship:name to "flyback".
//	set kuniverse:activevessel to vessel("flyback"). //doesn't work in atmo.
	set fullfuel to stage:liquidfuel.
	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.
	wait until eta:apoapsis<10.
		set kuniverse:activevessel to vessel("flyback").
		SET kuniverse:timewarp:rate to 0.
		print "Boostback".
		SET steeringDir TO 270. 	//point towards landing pad
		SET steeringPitch TO 0.
		lock steering to heading(270,0).
		wait until VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR) < 10.  //wait until pointing in right direction, saves fuel.
			set tval TO 0.3.
			print targetDist.
		 	wait until ship:groundspeed > horizon*(1+(40/impactTime)).//
			set tval to 0.
	lock steering to srfretrograde.
	//coast commands
	when impactTime > 15 then{	//Warping to make coast quicker.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		brakes on.
	}
	run hoverslam.ks.
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
