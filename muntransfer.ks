//Autopilot 2.4 build 150719
//Program to perform a transfer maneuver to Mun.
//Updates: first file version.

clearscreen.
run once functions.ks.
set step to "WarpToMunInject".
set thrott to 0.
lock throttle to thrott.
set genoutputmessage to "".
sas off.

set bodyTarget to body("Mun").
until (step="MunWarpToIncAdjustLandBurnWait") {

  if stage:liquidfuel<1 and stage:solidfuel<10 and stage:monopropellant<1 {//staging function
      wait 1.
      stage.
      }
      print genoutputmessage at (0,5).


  if(step="WarpToMunInject"){
  		SET kuniverse:timewarp:mode to "RAILS".
  		SET kuniverse:timewarp:warp to 3.
  		SET step TO "WaitMunInject".
  	}

  	if(step="WaitMunInject"){
  		SET steeringDir TO VANG(SHIP:PROGRADE:VECTOR, SHIP:UP:VECTOR). // point prograde
  		SET shipPitch TO 0.
  		lock munPhaseAngle TO getPhaseAngleToTarget(bodyTarget).
  		lock kerbinVectMunDiff TO getKerbinOrbitAngleToTarget(bodyTarget).
  		lock genoutputmessage TO round(munPhaseAngle,2)+" "+round(kerbinVectMunDiff,2).
      until munPhaseAngle < 25{
        print genoutputmessage at (0,5).
        wait 0.1.
      }
  		wait until (munPhaseAngle<25 AND kerbinVectMunDiff<80).
  			SET kuniverse:timewarp:warp to 0.
  			until kuniverse:timewarp:issettled wait 1.
        lock STEERING to prograde.
  			WAIT 8. //wait for vessel to turn
  			SET step TO "MunInjectBurn".
  			SET thrott TO 1.
  	}

  	if(step="MunInjectBurn"){
  		if(SHIP:ORBIT:TRANSITION="ENCOUNTER"){
  			SET thrott TO 0.05.
  			if(ship:orbit:nextpatch:periapsis<20000){
  				SET thrott TO 0.
  				WAIT 0.5.
  				SET kuniverse:timewarp:warp to 5.
  				if(SHIP:BODY:NAME="Mun"){
  					SET step TO "WarpToMunEncounter".
  				}
  			}
  		}
  		SET genoutputmessage TO "Orbit Transition: "+SHIP:ORBIT:TRANSITION.
  	}

  	if(step="WarpToMunEncounter"){
  		SET kuniverse:timewarp:warp to 0.
  		until kuniverse:timewarp:issettled {
  			wait 1.
  		}
  		if(SHIP:PERIAPSIS>10000){
  			LOCK STEERING TO getVectorRadialin().
  		}else{
  			LOCK STEERING TO getVectorRadialout().
  		}
  		WAIT 10.
  		SET step TO "AdjustMunPeriapsis".
  	}

  	if(step="AdjustMunPeriapsis"){
  		SET genoutputmessage TO "Periapsis: "+CEILING(SHIP:PERIAPSIS)+"m".
  		if(ABS(10000-SHIP:PERIAPSIS)>20000){
  			SET thrott to 1.
  		}else{
  			SET thrott to 0.1.
  		}
  		if(SHIP:PERIAPSIS>10000 and SHIP:PERIAPSIS<11000){

  			SET thrott to 0.
  			LOCK STEERING TO SHIP:RETROGRADE:VECTOR.

  			kuniverse:timewarp:warpto(time:seconds + ETA:PERIAPSIS - 40).
  			UNTIL(ETA:PERIAPSIS<28) {
  				wait 0.1.
  			}
  			SET step TO "MunCircularize".

  		}
  	}

  	if(step="MunCircularize"){
  		SET genoutputmessage TO "Eta Periapsis "+CEILING(ETA:PERIAPSIS).
  		SET thrott to 1.
  		if(SHIP:PERIAPSIS<8000){
  			SET thrott TO 0.
  			SET step TO "MunWarpToIncAdjustLandBurnWait".
  		}
  	}
    wait 0.1.
}
