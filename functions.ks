function setHoverPIDLOOPS{
	//Controls altitude by changing climbPID setpoint
	SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
	//Controls vertical speed
	SET climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
	//Controls horizontal speed by tilting rocket
	SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
	SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
	 //controls horizontal position by changing velPID setpoints
	SET eastPosPID TO PIDLOOP(1700, 0, 100, -40,40).
	SET northPosPID TO PIDLOOP(1700, 0, 100, -40,40).
}
function sProj { //Scalar projection of two vectors.
	parameter a.
	parameter b.
	if b:mag = 0 { PRINT "sProj: Divide by 0. Returning 1". RETURN 1. }
	RETURN VDOT(a, b) * (1/b:MAG).
}

function cVel {
	local v IS SHIP:VELOCITY:SURFACE.
	local eVect is VCRS(UP:VECTOR, NORTH:VECTOR).
	local eComp IS sProj(v, eVect).
	local nComp IS sProj(v, NORTH:VECTOR).
	local uComp IS sProj(v, UP:VECTOR).
	RETURN V(eComp, uComp, nComp).
}
function updateHoverSteering{
	SET cVelLast TO cVel().
	SET eastVelPID:SETPOINT TO eastPosPID:UPDATE(TIME:SECONDS, SHIP:GEOPOSITION:LNG).
	SET northVelPID:SETPOINT TO northPosPID:UPDATE(TIME:SECONDS,SHIP:GEOPOSITION:LAT).
	LOCAL eastVelPIDOut IS eastVelPID:UPDATE(TIME:SECONDS, cVelLast:X).
	LOCAL northVelPIDOut IS northVelPID:UPDATE(TIME:SECONDS, cVelLast:Z).
	LOCAL eastPlusNorth is MAX(ABS(eastVelPIDOut), ABS(northVelPIDOut)).
	SET steeringPitch TO 90 - eastPlusNorth.
	LOCAL steeringDirNonNorm IS ARCTAN2(eastVelPID:OUTPUT, northVelPID:OUTPUT). //might be negative
	if steeringDirNonNorm >= 0 {
		SET steeringDir TO steeringDirNonNorm.
	} else {
		SET steeringDir TO 360 + steeringDirNonNorm.
	}
	LOCK STEERING TO HEADING(steeringDir,steeringPitch).
}
function setHoverTarget{
	parameter lat.
	parameter lng.
	SET eastPosPID:SETPOINT TO lng.
	SET northPosPID:SETPOINT TO lat.
}
function setHoverAltitude{ //set just below landing altitude to touchdown smoothly
	parameter a.
	SET hoverPID:SETPOINT TO a.
}
function setHoverDescendSpeed{
	parameter a.
	SET hoverPID:MAXOUTPUT TO a.
	SET hoverPID:MINOUTPUT TO -1*a.
	SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //control descent speed with throttle
	SET thrott TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).	
}
function setHoverMaxSteerAngle{
	parameter a.
	SET eastVelPID:MAXOUTPUT TO a.
	SET eastVelPID:MINOUTPUT TO -1*a.
	SET northVelPID:MAXOUTPUT TO a.
	SET northVelPID:MINOUTPUT TO -1*a.
}
function setHoverMaxHorizSpeed{
	parameter a.
	SET eastPosPID:MAXOUTPUT TO a.
	SET eastPosPID:MINOUTPUT TO -1*a.
	SET northPosPID:MAXOUTPUT TO a.
	SET northPosPID:MINOUTPUT TO -1*a.
}
function setThrottleSensitivity{
	parameter a.
	SET climbPID:KP TO a.
}






function calcDistance { //Approx in meters
	parameter geo1.
	parameter geo2.
	return (geo1:POSITION - geo2:POSITION):MAG.
}
function geoDir {
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
}
function updateMaxAccel {
	SET g TO constant:G * BODY:Mass / BODY:RADIUS^2.
	SET maxAccel TO (SHIP:AVAILABLETHRUST) / SHIP:MASS - g. //max acceleration in up direction the engines can create
}
function getPhaseAngleToTarget{
	parameter targetBody.
	set shippos to SHIP:VELOCITY:ORBIT.
	set targetpos to targetBody:orbit:position.
	return vang(shippos,targetpos).
}
function getKerbinOrbitAngleToTarget{
	parameter targetBody.
	set kerbinpos to Body("Kerbin"):position.
	set targetpos to targetBody:orbit:position.
	//SET drawVelocityVector1 TO VECDRAW(
      //V(0,0,0),kerbinpos,
      //RGB(0,0,1),"",1.0,TRUE,1
    //).
	return vang(kerbinpos,targetpos).
}

function getVectorRadialin{
	SET normalVec TO getVectorNormal().
	return vcrs(ship:velocity:orbit,normalVec).
}
function getVectorRadialout{
	SET normalVec TO getVectorNormal().
	return -1*vcrs(ship:velocity:orbit,normalVec).
}
function getVectorNormal{
	return vcrs(ship:velocity:orbit,-body:position).
}
function getVectorAntinormal{
	return -1*vcrs(ship:velocity:orbit,-body:position).
}
function getVectorSurfaceRetrograde{
	return -1*ship:velocity:surface.
}
function getVectorSurfacePrograde{
	return ship:velocity:surface.
}
function getOrbitLongitude{
	return MOD(OBT:LAN + OBT:ARGUMENTOFPERIAPSIS + OBT:TRUEANOMALY, 360).
}
function getBodyAscendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE.
}
function getBodyDescendingnodeLongitude{
	return SHIP:ORBIT:LONGITUDEOFASCENDINGNODE+180.
}