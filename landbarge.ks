//Autopilot 2.4 build 150719
//Boostback and landing script for reusable boosters with barge landing. Can be used for theoretically infinite boosters.
//Updates: New calibration algorithms, but they don't work. Need to fix.
//Put barge ~100km from KSC for best effect.
clearscreen.

LOCK landing to vessel("Of Course I Still Love You"):geoposition.
set dist to landing:distance.

wait until ag5.
loaddist(500000).

set horizon to 0.
set fullfuel to 0.
set tval to 0.
SET radarOffset to 20. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel) + radarOffset.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
lock steeringPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)).
set impact to ship:geoposition.
lock twr to ship:availablethrust / (ship:mass*g).


SET climbPID TO PIDLOOP(0.4, 0.3, 0.005, 0, 1). //Controls vertical speed
SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -15, 15). //Controls altitude by changing climbPID setpoint
SET hoverPID:SETPOINT TO 200. //87 is the altitude about 7 meters above launch pad
SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -35, 35). //Controls horizontal speed by tilting rocket
SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -35, 35).
SET eastPosPID TO PIDLOOP(1700, 0, 100, -30, 30). //controls horizontal position by changing velPID setpoints
SET northPosPID TO PIDLOOP(1700, 0, 100, -30, 30).
SET eastPosPID:SETPOINT TO landing:LNG.
SET northPosPID:SETPOINT TO landing:LAT.



lock hdist to vxcl(up:vector, landing:position):mag.
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
	wait 5.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
	wait until (stage:liquidfuel/fullfuel < 0.15) OR ship:groundspeed > hdist/(impactTime*ship:mass/twr) OR ship:apoapsis > 89000.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 0.
		print "MECO".
		set tval to 0.
		set horizon to abs(ship:groundspeed).
		sas off.
		lock steering to srfprograde.
		wait 2.
		unlock steering.
		unlock throttle.
		ag10 on.
		stage.
		if alt:radar>50000 ag6 on. //stages fairing, just in case.
		wait 1.
		rcs on.
		lock steering to heading(270,0).
		lock throttle to tval.
		set ship:name to "flyback".
		set kuniverse:activevessel to vessel("flyback").
		part2().
}

function part2 {
	lock calvel to hdist/(impactTime*alt:radar/1000).
	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.
	wait until ship:verticalspeed < 0.
	SET kuniverse:timewarp:RATE TO 0.
	if ship:groundspeed > landing:distance/time:SECONDS set tval to 1.
	wait until ship:groundspeed < (hdist*twr)/time:SECONDS OR ship:groundspeed < (hdist*twr+ALT:RADAR)/1000.
	set tval to 0.
	brakes on.
	lock steering to landing:altitudeposition(20000)*-1.
	wait until alt:radar < 25000 and ship:verticalspeed < -1.
	if calvel<ship:groundspeed*0.5 AND landing:heading >180{
		print "Entry burn".
		set kuniverse:timewarp:rate to 0.
		set tval to 0.3.
		wait until ship:groundspeed < (calvel).
		set tval to 0.
	}
	lock steering to landing:altitudeposition(MAX(ALT:radar-1000,0))*-1.
	if landing:distance/alt:radar >1.5 set radarOffset to 20.
	else set radarOffset to 200.
	print "Preparing for landing".

	when impactTime < 10 then{set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.
	when impactTime < 8 then brakes on. //Not necessary with grid fins
	when impactTime < 7 then lock steering to srfretrograde.

	WAIT UNTIL trueRadar < stopDist.
		print "Performing hoverslam".
		lock tval to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -5.
	lock steering to up.
		if ship:verticalspeed < -5
		set tval to ((1.2*(g * SHIP:MASS) / SHIP:availablethrust)).
		else set tval to ((0.8*(g * SHIP:MASS) / SHIP:availablethrust)).
	gear on.

	until ship:status = "landed" or ship:status = "splashed"{
	  if (landing:distance) < 2000 {
	    lock steering to heading(landing:heading,(90-min(10,((landing:distance-1000)/(-twr*tval*ship:verticalspeed*ship:groundspeed+1))))).
	    if ship:verticalspeed < -5 set tval to ((1.2*(g * SHIP:MASS) / SHIP:availablethrust)).
	    else set tval to ((0.8*(g * SHIP:MASS) / SHIP:availablethrust)).
	  }
	  else{
	    lock steering to up.
	      if ship:verticalspeed < -5
	      set tval to ((1.2*(g * SHIP:MASS) / SHIP:availablethrust)).
	      else set tval to ((0.8*(g * SHIP:MASS) / SHIP:availablethrust)).
	  }
	  WAIT 0.1.
	  PRINT LANDING:DISTANCE AT (0,7).
	  print alt:radar at (0,6).
	  if alt:radar < 50 gear on.
	}
		print "Hoverslam completed".
		set tval to 0.

		rcs on.
		sas on.
		unlock steering.
		unlock throttle.
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

//To be added
