SET runLoop TO false.
SET updateSettings TO false.
SET steeringDir TO 90. //0-360, 0=north, 90=east
SET steeringPitch TO 90. // 90 is up

WHEN STAGE:NUMBER = 1 THEN {
	sas on.
	LOCK THROTTLE TO 0.
	SET updateSettings TO true.
	SET runLoop TO true.
	SET SHIP:SHIPNAME TO "kOS2Sat".
}

UNTIL false {
	if runLoop = true {
		if updateSettings = true {
			WAIT 5.
			SAS off.
			LOCK THROTTLE TO 1.
			LOCK STEERING TO HEADING(steeringDir,steeringPitch).
			SET updateSettings TO false.
		}
		SET steeringPitch TO 80.//MIN(MAX(VANG(VCRS(UP:VECTOR, NORTH:VECTOR), SHIP:VELOCITY:SURFACE), 10) + 10, 80).
		PRINT "running" + steeringPitch.
		WAIT 1.
		when ship:apoapsis > 90000 then{
		set runLoop to false.}
		//WHEN SHIP:APOAPSIS > 90000 THEN {break.}
	}
	WAIT 0.05.
	
}
	
WHEN SHIP:APOAPSIS > 90000 THEN {
		
		LOCK THROTTLE TO 0.
		lock steering to heading (90, 3). //Stay pointing 3 degrees above horizon         
        }
	if ETA:APOAPSIS < 5 or ETA:APOAPSIS > 180 or VERTICALSPEED < 0 { //If we're less 5 seconds from Ap or loosing altitude
            		set TVAL to 1.
            		}
        	if (SHIP:PERIAPSIS > 85000) { 
            		set TVAL to 0.
        		panels on.     //Deploy solar panels
        		lights on.
        		unlock steering.
        		print "SHIP IS NOW IN SPAACE!".
            }            
