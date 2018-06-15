clearscreen.
SET radarOffset to 0. 				// The value of alt:radar when landed (on gear)
set count to 0.
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock steeringPitch to max(80, 90 * (1 - alt:radar / 50000)).

if(count = 0){
	set radarOffset to alt:radar.
	wait 2.
	stage.
	set fullfuel to stage:liquidfuel.
	lock throttle to 1.
	lock steering to heading(90, steeringPitch).
	wait until stage:liquidfuel/fullfuel < 0.1 OR ship:apoapsis > 89000.
		lock throttle to 0.
		sas off.
		stage.
		rcs on.
		set horizon to abs(ship:groundspeed).
		set count to 1.
}

else if (count=1){
	WAIT UNTIL ship:verticalspeed < -1.
		print "Boostback".
		lock steering to heading(270,0).
		wait 5.
		lock throttle to 0.33.
		wait until ship:groundspeed > horizon.//20.
		lock throttle to 0.
		print "Preparing for hoverslam...".
		brakes on.
		lock steering to srfretrograde.
		when impactTime < 5 then {gear on.}

	WAIT UNTIL trueRadar < (stopDist).
		print "Performing hoverslam".
		lock throttle to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -0.01.
		print "Hoverslam completed".
		set ship:control:pilotmainthrottle to 0.
		rcs off.
}
