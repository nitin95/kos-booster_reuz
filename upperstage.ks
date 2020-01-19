//Autopilot 2.4.1 build 190120
//Upper stage autopilot for partially reusable vehicles. Parks into a ~90x70 km Kerbin orbit (Hopefully).
//Updates:
//Better circularization burn control based on stage TWR;
//Cleaning up code;
//Better warp to circularization.

SAS off.
RCS on.
lights on.
set runmode to 1.
set targetPitch to 0.
SET g to 9.81.
print "Standby" at (0,5).
wait until ag10.
clearscreen.
print "Start".
set thr to 0.
lock throttle to thr.
lock twr to ship:availablethrust / (ship:mass*g)+ 0.001.
lock targetPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)).
clearscreen.
wait 2.

set targetApoapsis to 88000. //Target apoapsis in meters
set targetPeriapsis to 72000. //Target periapsis in meters.

until runmode=0{

    if runmode = 1 {
      lock thr to 1.
      lock steering to heading (90, targetPitch).
      if ship:verticalspeed<-0.1 pitchBal().
      if SHIP:APOAPSIS > targetApoapsis
      {
        lock steering to srfprograde. //Stay pointing prograde for minimal drag.
        lock thr to 0. //Engines off.
        set runmode to 2.
      }
    }

    else if runmode = 2 { //Coast to Ap
      set kuniverse:timewarp:mode to "PHYSICS".
  		set kuniverse:timewarp:rate to 4.
      wait until alt:radar > 70000.
      SET WARP to 0.
      set kuniverse:timewarp:mode to "rails".
  		set WARP to 3.
      wait until ETA:APOAPSIS < 40.
        SET WARP to 0.
        set runmode to 3.
    }

    else if runmode = 3 { //Burn to raise Periapsis
      print "Circularization".
       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or loosing altitude
            	lock thr to 1.
              pitchBal().
		}
        if ship:periapsis > 0 lock thr to (ship:mass*g / ship:availablethrust)*0.3.
        if (SHIP:PERIAPSIS > targetPeriapsis) or (SHIP:apoapsis > targetApoapsis*1.2){
            //If the periapsis is high enough or apoapsis is too far
            set runmode to 10.
            }
        }

    else if runmode = 10 { //Final touches
        lock thr to 0. //Shutdown engine.
        panels on.     //Deploy solar panels
        lights on.
        unlock steering.
	      sas on.
        print "SHIP SHOULD NOW BE IN SPACE!".
        ag9.  //payload decoupler
        //run EDLK. //to be used when EDLK is stable.
        CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
        }

        if stage:liquidfuel<1 and stage:solidfuel<1 and stage:monopropellant<1 AND runmode>1 {//staging function
        		wait 0.1.
        		stage.
        		}
    if ship:altitude>55000 ag6 on. //fairing deploy, or whatever's on action group 6.
    wait 0.01.
    clearscreen.
}

kuniverse:timewarp:warpto(time:seconds+900).
run edlk.

function pitchBal {
		IF ship:verticalspeed > 1 SET targetPitch to 1.
		else if ship:verticalspeed<-1 and twr<1.5 set targetPitch to min(45, arcsin(1/(2*twr))).
    else if ship:verticalspeed<-1 and twr>1.5 set targetPitch to min(20, arcsin(1/(3*twr))).
		else set targetPitch to 5.
		lock steering to heading (90, targetPitch).
}
