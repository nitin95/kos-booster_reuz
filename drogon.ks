//Autopilot 2.2 build 200219
//Experimental autopilot to fly a capsule to the Mun.

clearscreen.
set radarOffset to 2.8.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:airspeed^2 / (2 * maxDecel)+50.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

sas off.


//this section is for mun and minmus. comment out if going to Duna.
lock steering to retrograde.
lock throttle to 1.
wait until ship:groundspeed < 50.
lock throttle to 0.

WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam...".
	rcs on.
	brakes on.
	lock steering to srfretrograde.
	when impactTime < 10 then set kuniverse:timewarp:rate to 1.
	when impactTime < 3 then {gear on.}

WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -5.
	lock throttle to (0.95 * ((9.81 * SHIP:MASS) / SHIP:availablethrust)).
	lock steering to up.
	wait until ship:status = "landed".
		print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
	sas on.

		wait 10.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
