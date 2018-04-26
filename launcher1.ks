//launcher1.ks: By @NitinM95, based off Seth Persigehl's script.
//This program launches a ship from the KSC and flies it into orbit.
//Meant for expendable/chute recovered vehicles.

//Set the ship to a known configuration
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SAS off.
RCS on.
lights on.
lock throttle to 0.
gear off.
set tval to 0.
clearscreen.

set targetApoapsis to 80000. //Target apoapsis in meters
set targetPeriapsis to 70000. //Target periapsis in meters

set runmode to 2. //Safety in case we start mid-flight
if ALT:RADAR < 50 { //Guess if we are waiting for take off
    set runmode to 1.
    }

from {local x is 10.} until x=-1 step{set x to x-1.} do{
	print "T - " + x.
	wait 1.
	if x=0 set runMode to 1.}

until runmode = 0 { //Run until we end the program

if stage:liquidfuel<1 and stage:solidfuel<1 and stage:monopropellant<1 AND runmode>1 {//staging function
		wait 0.1.
		stage.
		}
if ship:altitude>50000 ag6 on. //fairing deploy, or whatever on action group 6.

 if runmode = 1 { //Ship is on the launchpad
        lock steering to UP.  //Point the rocket straight up
        set TVAL to 1.        //Throttle up to 100%
        stage.                //Same thing as pressing Space-bar
        set runmode to 2.     //Go to the next runmode
        }

    else if runmode = 2 { // Fly UP to 10,000m
        lock steering to heading (90,90). //Straight up.
        set TVAL to 1.
        if VERTICALSPEED > 80 {
            //Once altitude is higher than 10km, go to Gravity Turn mode
            set runmode to 3.
            }
        } //Make sure you always close out your if statements.

    else if runmode = 3 { //Gravity turn
        set targetPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)).
            //Pitch over gradually until levelling out to 5 degrees at 50km
        lock steering to heading ( 90, targetPitch). //Heading 90' (East), then target pitch
        set TVAL to 1.
        if SHIP:APOAPSIS > targetApoapsis {
            set runmode to 4.
            }
        }

    else if runmode = 4 { //Coast to Ap
      lock steering to heading ( 90, 3). //Stay pointing 3 degrees above horizon
      set TVAL to 0. //Engines off.
      if (SHIP:ALTITUDE > 70000) and (ETA:APOAPSIS > 60) and (VERTICALSPEED > 0) {
        if WARP = 0 {        // If we are not time warping
          wait 1.         //Wait to make sure the ship is stable
          SET WARP TO 3. //Be really careful about warping
        }
      }.
      else if ETA:APOAPSIS < 20 OR ETA:APOAPSIS > 100 {
        SET WARP to 0.
        set runmode to 5.
      }
    }

    else if runmode = 5 { //Burn to raise Periapsis
       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or loosing altitude
            	set TVAL to 1.
		if ETA:APOAPSIS < 5 set targetPitch to eta:apoapsis.
		ELSE IF ETA:APOAPSIS >5 AND ETA:APOAPSIS < 100 SET targetPitch to -eta:apoapsis.
 		else if eta:apoapsis>100 set targetPitch to 45.
		else set targetPitch to 5.
		lock steering to heading ( 90, targetPitch).
		}
        if (SHIP:PERIAPSIS > targetPeriapsis) or (SHIP:apoapsis > targetApoapsis*2){
            //If the periapsis is high enough or apoapsis is too far
            set TVAL to 0.
            set runmode to 10.
            }
        }

    else if runmode = 10 { //Final touches
        set TVAL to 0. //Shutdown engine.
        panels on.     //Deploy solar panels
        lights on.
        unlock steering.
	      sas on.
        print "SHIP SHOULD NOW BE IN SPACE!".
        CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
        set runmode to 0.
        }

    lock throttle to TVAL. //Write our planned throttle to the physical throttle

    //Print data to screen.
    print "RUNMODE:    " + runmode + "      " at (5,4).
    print "ALTITUDE:   " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:   " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:  " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:  " + round(ETA:APOAPSIS) + "      " at (5,8).

}