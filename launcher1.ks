//Autopilot 2.4.1 build 190120
//Simple launch script for expendable vehicles. Meant to replace MechJeb ascent autopilot.
//Updates: Dropped runmode 2 and brought back TWR control for launch.

//Set the ship to a known configuration
SAS off.
RCS on.
lights on.
lock throttle to 0.
gear off.
set tval to 0.
set g to 9.81.
lock throttle to TVAL.

clearscreen.

set targetApoapsis to 80000. //Target apoapsis in meters. Set 2850000 for KTO, 80000 for LKO, 60000000 for RTO and 100000000 for escape.
set targetPeriapsis to 70000. //Target periapsis in meters. Set according to your discretion.
set linc to 0. //target inclination.
set ldir to 90-linc. //launch direction.
lock twr to ship:availablethrust / (ship:mass*g)+0.0001.

set runmode to 2. //Safety in case we start mid-flight
if ALT:RADAR < 100  set runmode to 1.//If we are on the ground, prep for takeoff.

lock targetPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)). //gravity turn pitch function.

wait until ag5.

until runmode = 0 { //Run until we end the program

if stage:liquidfuel<1 and stage:solidfuel<10 and stage:monopropellant<1 AND runmode>1 {//staging function
		wait 1.
		stage.
		}
if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.

 if runmode = 1 { //Ship is on the launchpad
	 			lights off.
				wait 1.
				lock steering to heading (ldir, targetPitch). //Heading according to desired inclination, then pitch over gradually until levelling out to 5 degrees at 50km
        lock TVAL to 1.5/twr.        //Throttle up to desired TWR
        stage.                //Burn baby, burn!
        if ship:VERTICALSPEED > 80 set runmode to 2. //Once in stable flight
        }

    else if runmode = 2 { //Atmospheric Phase
				lock TVAL to 1. //Full power, Unlimited power!!!
				if eta:apoapsis<10 and alt:radar > 50000 pitchBal().
        if SHIP:APOAPSIS > targetApoapsis {
            set runmode to 3.
            }
					if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on.}     //Deploy solar panels & fairing, or whatever on action group 6.
        }

    else if runmode = 3 { //Coast to Ap
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
        set runmode to 4.}
      }
			if ALT:RADAR>60000 and runmode>2 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.
    }

    else if runmode = 4 { //Burn to raise Periapsis

       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If near apoapsis or losing altitude
            	set TVAL to 1.
							pitchBal().
		}

				if ship:periapsis > 0 set tval to (ship:mass*g / ship:availablethrust)*0.3.
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
				print "To shut down computer, press 7.".
				wait 5.
				set runmode to 0.

    }

    lock throttle to TVAL. //Write our planned throttle to the physical throttle
		wait 0.01.
}
if ag7 CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").

function pitchBal {
		IF ship:verticalspeed > 1 SET targetPitch to 0.
		else if ship:verticalspeed<-1 set targetPitch to 20.
		else set targetPitch to 5.
		lock steering to heading ( ldir, targetPitch).
}
