//Autopilot 2.5 build 200320
//Landing script for orbital vessels. Non-precision approach.
//Updates:
//Fixing bugs with warp cancellation and touchdown detection.
//Cleaning up old code.
//Encapsulating slope detection code for further development.

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

//Deorbit Burn
lock steering to retrograde.
wait until VANG(retrograde:VECTOR, SHIP:FACING:VECTOR) < 10.
set tval to 1.
wait until ship:periapsis < -60000. //Note: need to translate perigee to downrange distance.
set tval to 0.

//Coast Phase
WAIT UNTIL ship:verticalspeed < -1.
print "Preparing for hoverslam...".
rcs on.
brakes on.
lock steering to srfretrograde.
WAIT UNTIL idealThrottle > 0.4. //Note: constant should be replaced with a TWR and horizontal-velocity based function.

//Retro burn a bit earlier than ideal hoverslam due to horizontal velocity cancellation needed
set kuniverse:timewarp:rate to 0.
print "Performing hoverslam".
set tval to 1.
wait until ship:groundspeed < 5.

print("Landing.").
gear on.
set tval to ((0.5*(g * SHIP:MASS) / SHIP:availablethrust)).
LOCK STEERING TO srfretrograde.
wait 5.
wait until abs(ship:groundspeed) < 1.
set tval to 0.
wait until trueRadar < stopDist-950.
until ship:status = "LANDED"{
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

function slopered {
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
}
