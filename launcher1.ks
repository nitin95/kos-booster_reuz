//Autopilot 2.2 build 200219
//Simple launch script for expendable vehicles. Meant to replace MechJeb ascent autopilot.
//Updates: Bugfixes and accuracy improvements.

//Set the ship to a known configuration
SAS off.
RCS on.
lights on.
lock throttle to 0.
gear off.
set tval to 0.
clearscreen.

set targetApoapsis to 80000. //Target apoapsis in meters. Set 2850000 for KTO, 80000 for LKO, 60000000 for RTO and 100000000 for escape.
set targetPeriapsis to 70000. //Target periapsis in meters. Set according to your discretion.
set linc to 0. //target inclination.
set ldir to 90-linc. //launch direction.

set runmode to 2. //Safety in case we start mid-flight
if ALT:RADAR < 100  set runmode to 1.//If we are on the ground, prep for takeoff.

lock targetPitch to max( 5, 90 * (1 - ALT:RADAR / 40000)). //gravity turn pitch function.

wait until ag5.
set runmode to 1.

until runmode = 0 { //Run until we end the program

if stage:liquidfuel<1 and stage:solidfuel<10 and stage:monopropellant<1 AND runmode>1 {//staging function
		wait 1.
		stage.
		}
if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.

 if runmode = 1 { //Ship is on the launchpad
	 			lights off.
				wait 1.
				lock steering to UP.  //Point the rocket straight up
        set TVAL to 1.        //Throttle up to 100%
        stage.                //Same thing as pressing Space-bar
        set runmode to 2.     //Go to the next runmode
        }

    else if runmode = 2 { // Fly UP.
        if ship:VERTICALSPEED > 80 {
            set runmode to 3.
            }
        }

    else if runmode = 3 { //Gravity turn
        lock steering to heading (ldir, targetPitch). //Heading 90' (East), then pitch over gradually until levelling out to 5 degrees at 50km
				if eta:apoapsis<10 and alt:radar > 40000 pitchBal().
        if SHIP:APOAPSIS > targetApoapsis {
            set runmode to 4.
            }
					if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on.}     //Deploy solar panels & fairing, or whatever on action group 6.
        }

    else if runmode = 4 { //Coast to Ap
      lock steering to ship:srfprograde. //Stay pointing prograde to reduce drag
      set TVAL to 0. //Engines off.
      if (SHIP:ALTITUDE > 70000) and (ETA:APOAPSIS > 60) and (VERTICALSPEED > 0) {
        if WARP = 0 {        // If we are not time warping
          wait 1.         //Wait to make sure the ship is stable
          SET WARP TO 3. //Be really careful about warping
        }
      }
      else if ETA:APOAPSIS < 20{
        SET WARP to 0.
        when eta:apoapsis < 10 then {set TVAL to 0.05.
        set runmode to 5.}
      }
			if ALT:RADAR>60000 and runmode>3 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.
    }

    else if runmode = 5 { //Burn to raise Periapsis

       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or losing altitude
            	set TVAL to 1.
							pitchBal().
		}

				if ship:periapsis > 0 lock throttle to (ship:mass*g / ship:availablethrust)*0.3.
        if (SHIP:PERIAPSIS > targetPeriapsis) or (SHIP:apoapsis > targetApoapsis*1.1){	//If the periapsis is high enough or apoapsis is too far

						set TVAL to 0.
            set runmode to 10.
            }

    }

    else if runmode = 10 { //Final touches
        set TVAL to 0. //Shutdown engine.
        lights on.
        unlock steering.
	      sas on.
				panels on.
        print "SHIP SHOULD NOW BE IN SPACE!".
				set runmode to 0.
        CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
    }

    lock throttle to TVAL. //Write our planned throttle to the physical throttle
		wait 0.001.
}

function pitchBal {
		if ETA:APOAPSIS < 5 set targetPitch to 2.
		ELSE IF ETA:APOAPSIS >5 and ship:verticalspeed > 0.1 SET targetPitch to -1.
		else if ship:verticalspeed<-1 set targetPitch to 30.
		else set targetPitch to 2.
		lock steering to heading ( ldir, targetPitch).
}
