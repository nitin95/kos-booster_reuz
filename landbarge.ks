//Autopilot 2.0.3 build 02072018
//Boostback and landing script for reusable boosters. Can be used for theoretically infinite boosters.
//Updates: Optimizing ocean landing accuracy.
clearscreen.
SET radarOffset to 0. 				// The value of alt:radar when landed (on gear)
set count to 0.
set horizon to 0.
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock steeringPitch to max(80, 90 * (1 - alt:radar / 20000)).
lock impactDist to impactTime*abs(ship:groundspeed).
lock SPos to ship:geoposition.
set impact to ship:geoposition.
set landing to vessel("Of Course I Still Love You"):geoposition.

//CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").	//for debug purposes.
if alt:radar>100 part2().
else{
		set radarOffset to alt:radar.
		wait 2.
		stage.
		print count.
		lock throttle to 1.
		wait 1.
		gear off.
		set fullfuel to stage:liquidfuel.
		lock steering to heading(90, steeringPitch).
		wait until stage:liquidfuel/fullfuel < 0.1 OR ship:apoapsis > 89000.
			print "MECO".
			lock throttle to 0.
			sas off.
			unlock steering.
			stage.
			if alt:radar>30000 ag6 on. //stages fairing, just in case.
			wait 1.
			rcs on.
			set horizon to abs(ship:groundspeed).
			lock steering to ship:prograde.
			part2().
	}

function part2 {
		WAIT UNTIL ship:verticalspeed < 10.
			print "Boostback".
				lock steering to heading(270,0).
				wait 5.
				//TBD: Barge landing algorithm to be implemented for boostback burn time.
				lock throttle to 0.33.
				until distance(landing,impact) < 0.1{
				 	lock latt to arcsin(sin(SPos:lat)*cos(impactDist)+cos(SPos:lat)*sin(impactDist)*cos(270)).
	  			lock lone to mod(SPos:lng-arcsin(sin(270)*sin(impactDist)/cos(SPos:lat))+3.14,2*3.14)-3.14.
					lock impact to latlng(latt,lone).
				}
				wait until distance(landing,impact) < 0.1 OR ship:groundspeed > horizon*(1+(50/impactTime)).
				lock steering to srfretrograde.
				brakes on.
				lock throttle to 0.
			print "Preparing for hoverslam...".
				lock steering to srfretrograde.
				when impactTime < 8 then brakes on.
				when ship:verticalspeed > -20 then {gear on.}

		WAIT UNTIL trueRadar < (stopDist).
			print "Performing hoverslam".
				lock throttle to idealThrottle.

		WAIT UNTIL ship:verticalspeed > -0.1.
			print "Landed. (Hopefully)".
				lock throttle to 0.
				rcs on.
				sas on.
				CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
	}

function distance {
  declare parameter pos1, pos2.
  local dif to V(pos1:lat - pos2:lat, pos1:lng - pos2:lng, 0).
  return dif:mag.
}
