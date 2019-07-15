//Autopilot 2.4 build 150719
//Upper stage autopilot for partially reusable vehicles. Parks into a ~90x70 km Kerbin orbit (Hopefully).
//Updates: Slightly higher gravity turn to account for high TWR second stages.

SAS off.
RCS on.
lights on.
gear off.
set oname to ship:name.
set runmode to 3.
set targetPitch to 0.
SET g to 9.81.
wait until ag10.
set thr to 0.
lock throttle to thr.
clearscreen.
wait 2.

set targetApoapsis to 90000. //Target apoapsis in meters
set targetPeriapsis to 80000. //Target periapsis in meters. Leave a 5-10km gap to account for guidance error, you can circularize later.
print "Standby" at (0,5).
until runmode=0{

    if runmode = 3 {
      wait 0.1.
      print "Start".
      set ship:name to "stage2".
      //set target to "flyback".
      set thr to 1.
      if alt:radar < 50000 and ship:verticalspeed>0{
      lock targetPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)).
      lock steering to heading (90, targetPitch).
      }
      else if ship:verticalspeed<-0.1 pitchBal().
      if SHIP:APOAPSIS > targetApoapsis set runmode to 4.
}

    else if runmode = 4 { //Coast to Ap
      //PRINT "Coast".
      //if ship:altitude>55000 ag6 on. //fairing deploy, or whatever's on action group 6.
      lock steering to heading (90, 3). //Stay pointing 3 degrees above horizon
      set thr to 0. //Engines off.
      when ETA:APOAPSIS < 20 then{
        SET WARP to 0.
        set runmode to 5.
      }
    }

    else if runmode = 5 { //Burn to raise Periapsis
      print "Circularization".
       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or loosing altitude
            	lock thr to 1.
              pitchBal().
		}
        if ship:periapsis > 0 lock thr to (ship:mass*g / ship:availablethrust)*0.3.
        if (SHIP:PERIAPSIS > targetPeriapsis*0.9) or (SHIP:apoapsis > targetApoapsis*1.2){
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
        set ship:name to oname.
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
		else if ship:verticalspeed<-1 set targetPitch to min(90,90/tan(ship:mass*g/ship:availablethrust)).
		else set targetPitch to 5.
		lock steering to heading ( 90, targetPitch).
}
