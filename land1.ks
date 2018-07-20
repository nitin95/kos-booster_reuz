//Autopilot 2.0.5 build 200718
//Boostback and landing script for reusable boosters. Can be used for theoretically infinite boosters.
//Updates: New boostback algo and workflow.
clearscreen.
SET radarOffset to alt:radar. 				// The value of alt:radar when landed (on gear)
set count to 0.
set horizon to 0.
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max(80, 90 * (1 - alt:radar / 20000)).
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").	//for debug purposes.
lock SPos to ship:geoposition.
set impact to ship:geoposition.
set landing to ship:geoposition.
lock latt to arcsin(sin(SPos:lat)*cos(impactDist)+cos(SPos:lat)*sin(impactDist)*cos(270)).
lock lone to mod(SPos:lng-arcsin(sin(impactDist)/cos(SPos:lat+0.01))+3.14,2*3.14)-3.14.
lock impact to latlng(latt,lone).
LOCK targetDir TO geoDir(impact, landing).
lock targetDist to distance(impact,landing).

if alt:radar>100 part2().
else{
		set radarOffset to alt:radar.
		wait 0.1.
		stage.
		print count.
		lock throttle to 1.
		gear off.
		set fullfuel to stage:liquidfuel.
		wait 2.
		lock steering to heading(90, steeringPitch).
		wait until stage:liquidfuel/fullfuel < 0.1 OR ship:apoapsis > 89000.
			print "MECO".
			PRINT targetDist.
			lock throttle to 0.
			sas off.
			wait 2.
			unlock steering.
			unlock throttle.
			stage.
			if alt:radar>30000 ag6 on. //stages fairing, just in case.
			wait 1.
			rcs on.
			set horizon to abs(ship:groundspeed).
			lock steering to heading(270,0).
			part2().
	}

function part2 {
		print "Boostback".
		lock steering to heading(270,0).
		SET steeringDir TO targetDir - 180. 	//point towards landing pad
		SET steeringPitch TO 0.
		wait until VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR) < 20.  //wait until pointing in right direction, saves fuel.
			lock throttle TO targetDist / 1000 + 0.3.
			print targetDist.
			wait until targetDist < 20.
				lock throttle to 0.
		print "Preparing for hoverslam...".
		lock steering to srfretrograde.

		//coast commands
		when impactTime > 15 then{	//Warping to make coast quicker.
			set kuniverse:timewarp:mode to "PHYSICS".
			set kuniverse:timewarp:rate to 4.}
		when impactTime < 10 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
		when impactTime < 8 then brakes on.
		when impactTime < 4 then {gear on.}

		WAIT UNTIL trueRadar < (stopDist).
			print "Performing hoverslam".
			lock throttle to idealThrottle.

		WAIT UNTIL ship:verticalspeed > -0.1.
			print "Hoverslam completed".
			set ship:control:pilotmainthrottle to 0.
			rcs on.
			sas on.
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
