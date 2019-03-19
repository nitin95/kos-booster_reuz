//Autopilot v2.2
//EDL-K: An autopilot to re-enter and land as close to KSC as possible. Useful for SSTO boosters.
//Note: New algo needs to be implemented, timing deorbit burn using phase angle.

clearscreen.
set radarOffset to 9.184.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+20.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
set landing to Kerbin:GEOPOSITIONLATLNG(-0.0971980934745649,-74.5576639199546).
lock targetDir to targetPosition:direction.

	print "Deorbiting".
	rcs on.
	set warp to 0.
	lock steering to HEADING(270,0).
	wait until VANG(HEADING(270,0):VECTOR, SHIP:FACING:VECTOR) < 10.
	set throttle to 1.
	when ship:periapsis < -160000 then
		set throttle to 0.
		brakes on.
WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam...".
	LOCK STEERING TO srfretrograde.
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


		wait 1.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
