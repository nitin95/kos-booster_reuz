//Autopilot 2.4 build 150719
//Landing script for orbital vessels. Non-precision approach.
//Updates: Converted to standalone landing script.

clearscreen.
lock retropitch to 90 - vang(ship:up:vector, -velocity:surface).
lock trueRadar to alt:radar.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel*sin(retropitch))+1000.		// The distance the burn will require. Added a ton of safety cause mun terrain is unpredictable.
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

panels off.
gear on.
lock throttle to tval.

sas off.


//this section is for mun and minmus. comment out if going to Duna.
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
wait until ship:groundspeed < 0.5.
set tval to (g * SHIP:MASS) / (SHIP:availablethrust).
until slope < 10{
  print slope at (5,5).
  if slope>temp {
    set x to -x.
    if countx>1{
      lock steering to srfretrograde.
      wait until ship:groundspeed < 0.1.
    }
    set countx to countx+1.
    if countx>5{
      set y to 5.
      if slope>temp set y to -y.
      set county to county+1.
      if county > 5{
        set z to 5.
        if slope>temp set z to -z.
        set countz to countz+1.
        if countz > 5 break.
      }
    }
  }
  set tval to (g * SHIP:MASS) / (SHIP:availablethrust).
  LOCK STEERING TO Up + R(x,y,z).
  wait 10.
  lock steering to srfretrograde.
  wait until ship:groundspeed < 0.5.
  set temp to slope.
}
print("Landing.").
gear on.
set tval to ((0.5*(g * SHIP:MASS) / SHIP:availablethrust)).
LOCK STEERING TO srfretrograde.
wait 5.
wait until abs(ship:groundspeed) < 1.
set tval to 0.
wait until trueRadar < stopDist-950.
until ship:verticalspeed > -0.5	and alt:radar<50{
  if ship:verticalspeed < -4
  set tval to idealThrottle.
  else set tval to ((0.9*(g * SHIP:MASS) / SHIP:availablethrust)).
}
  print "Landed.".
set tval to 0.
unlock steering.
sas on.
wait 5.
panels on.
set runtrig to "off".
CORE:DOEVENT("Toggle Power").

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
