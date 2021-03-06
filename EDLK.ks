//Autopilot v2.4
//EDL-K: An autopilot to re-enter and land as close to KSC as possible. 

clearscreen.
lock retropitch to 90 - vang(ship:up:vector, -velocity:surface).
lock trueRadar to alt:radar.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel*sin(retropitch))+50.		// The distance the burn will require. Added a ton of safety cause mun terrain is unpredictable.
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock slope to slope_calculation(ship:geoposition).
set temp to 0.
set x to 5.
set y to 0.
set z to 0.
set tval to 0.
set count to 0.
set countx to 0.
set county to 0.
set countz to 0.
set landing to latlng(0.1025,74.57528).
panels off.
lock throttle to tval.

sas off.

wait until landing:distance<160000.
lock steering to vxcl(up:vector,-velocity:surface).
wait until VANG(retrograde:VECTOR, SHIP:FACING:VECTOR) < 10.
set tval to 1.
wait until ship:periapsis < -60000.
set tval to 0.

WAIT UNTIL ship:verticalspeed < -1.
print "Preparing for hoverslam...".
rcs on.
brakes on.
lock steering to srfretrograde.
//	when impactTime < 10 then set kuniverse:timewarp:rate to 1.
//	when impactTime < 3 then {gear on.}
WAIT UNTIL idealThrottle > 0.4.
set kuniverse:timewarp:rate to 0.
WAIT UNTIL idealThrottle > 0.85.
set kuniverse:timewarp:rate to 0.
print "Performing hoverslam".
set tval to idealThrottle.
gear on.
LOCK STEERING TO srfretrograde.
wait 5.
wait until abs(ship:groundspeed) < 1.
set tval to 0.
WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.
	lock steering to ship:srfretrograde.

WAIT UNTIL ship:verticalspeed > -5.
	lock throttle to (1 * ((9.81 * SHIP:MASS) / SHIP:availablethrust)).
	gear on.
wait until ship:status = "landed" or ship:status = "splashed".
	print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
		wait 2.
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").

FUNCTION slope_calculation {//returns the slope of p1 in degrees
PARAMETER p1.
LOCAL upVec IS (p1:POSITION - p1:BODY:POSITION):NORMALIZED.
RETURN VANG(upVec,surface_normal(p1)).
}

FUNCTION surface_normal {
	PARAMETER p1.
	LOCAL localBody IS p1:BODY.
	LOCAL basePos IS p1:POSITION.

	LOCAL upVec IS (basePos - localBody:POSITION):NORMALIZED.
	LOCAL northVec IS VXCL(upVec,LATLNG(90,0):POSITION - basePos):NORMALIZED * 2.
	LOCAL sideVec IS VCRS(upVec,northVec):NORMALIZED * 3.//is east

	LOCAL aPos IS localBody:GEOPOSITIONOF(basePos - northVec + sideVec):POSITION - basePos.
	LOCAL bPos IS localBody:GEOPOSITIONOF(basePos - northVec - sideVec):POSITION - basePos.
	LOCAL cPos IS localBody:GEOPOSITIONOF(basePos + northVec):POSITION - basePos.
	RETURN VCRS((aPos - cPos),(bPos - cPos)):NORMALIZED.
}
