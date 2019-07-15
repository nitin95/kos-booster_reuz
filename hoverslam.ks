//Autopilot v2.4
//Autopilot to land a vehicle using a suicide burn.

clearscreen.
set radarOffset to 9.184.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+100.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

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
	lock steering to ship:srfretrograde.

WAIT UNTIL ship:verticalspeed > -5.
	lock throttle to ((g * SHIP:MASS) / SHIP:availablethrust).
wait until ship:status = "landed".
	print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
		wait 10.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
