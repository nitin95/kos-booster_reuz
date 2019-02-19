//Autopilot 2.2 build 200219
//Upper stage autopilot for partiallyu reusable vehicles. Parks into a ~90x70 km Kerbin orbit.
//Updates: Bugfixes and improvements.

SAS off.
RCS on.
lights on.
gear off.
wait until ag10.
wait 5.
set runmode to 3.
set targetPitch to 0.
SET g to 9.81.
clearscreen.

set targetApoapsis to 90000. //Target apoapsis in meters
set targetPeriapsis to 80000. //Target periapsis in meters. Leave a 5-10km gap to account for guidance error, you can circularize later.
print "Standby".
until runmode=0{

    if runmode = 3 {
      wait 0.1.
      print "Start".
      set ship:name to "stage2".
      //set target to "flyback".
      lock throttle to 1.
      pitchBal().
      if SHIP:APOAPSIS > targetApoapsis set runmode to 4.
}

    else if runmode = 4 { //Coast to Ap
      PRINT "Coast".
      if ship:altitude>55000 ag6 on. //fairing deploy, or whatever's on action group 6.
      lock steering to heading ( 90, 3). //Stay pointing 3 degrees above horizon
      lock throttle to 0. //Engines off.
      when ETA:APOAPSIS < 20 then{
        SET WARP to 0.
        set runmode to 5.
      }
    }

    else if runmode = 5 { //Burn to raise Periapsis
      print "Circularization".
       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or loosing altitude
            	lock throttle to 1.
		if ETA:APOAPSIS < 5 set targetPitch to eta:apoapsis.
		ELSE IF ETA:APOAPSIS >5 AND ETA:APOAPSIS < 100 SET targetPitch to eta:apoapsis.
 		else if eta:apoapsis>100 set targetPitch to 30.
		else set targetPitch to 5.
		lock steering to heading ( 90, targetPitch).
		}
        if ship:periapsis > 0 lock throttle to (ship:mass*g / ship:availablethrust)*0.3.
        if (SHIP:PERIAPSIS > targetPeriapsis*0.9) or (SHIP:apoapsis > targetApoapsis*1.2){
            //If the periapsis is high enough or apoapsis is too far
            lock throttle to 0.
            set runmode to 10.
            }
        }

    else if runmode = 10 { //Final touches
        lock throttle to 0. //Shutdown engine.
        panels on.     //Deploy solar panels
        lights on.
        unlock steering.
	      sas on.
        print "SHIP SHOULD NOW BE IN SPACE!".
        ag9.  //payload decoupler
        run EDLK.
        }

        if stage:liquidfuel<1 and stage:solidfuel<1 and stage:monopropellant<1 AND runmode>1 {//staging function
        		wait 0.1.
        		stage.
        		}
    if ship:altitude>55000 ag6 on. //fairing deploy, or whatever's on action group 6.
    wait 0.001.
    clearscreen.
}

function pitchBal {
		if ETA:APOAPSIS < 5 set targetPitch to max(5, 90*(1-alt:radar/40000)).
		ELSE IF ETA:APOAPSIS >5 AND ETA:APOAPSIS < 100 SET targetPitch to max(5, 90*(1-alt:radar/40000)).
		else if ship:verticalspeed<-1 set targetPitch to 30.
		else set targetPitch to 2.
		lock steering to heading ( 90, targetPitch).
}
