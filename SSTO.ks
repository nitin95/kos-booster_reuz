//Autopilot 2.4.3 build 030320
//Simple launch script for SSTOs.
//Updates:
//Updated ascent trajectory for optimal fuel burn.

//Set the ship to a known configuration
SAS off.
RCS off.
lights on.
set twr to 0.
set tval to 0.
set Steerpitch to 0.
set g to 9.81.
lock throttle to TVAL.
lock twr to ship:availablethrust / (ship:mass*g)+0.0001.
clearscreen.

set targetApoapsis to 80000. //Target apoapsis in meters. Set 2850000 for KTO, 80000 for LKO, 60000000 for RTO and 100000000 for escape.
set targetPeriapsis to 70000. //Target periapsis in meters. Set according to your discretion.
set linc to 0. //target inclination.
set ldir to 90-linc. //launch direction.

set runmode to 2.
if ALT:RADAR < 100 and ship:groundspeed < 5 set runmode to 1.//If we are on the ground, prep for takeoff.

lock targetPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)). //gravity turn pitch function.

until ag5 HUDTEXT("Press 5 to Fly", 5, 2, 15, green, false).



until runmode = 0 { //Run until we end the program

if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.

 if runmode = 1 { //Ship is on the runway
	 			lights off.
        sas on.
        set tval to 1.
        stage. //Ignite engines.
				wait until ship:groundspeed>120. //V1
        sas off.
        set Steerpitch to 15.
				lock steering to heading(ldir,Steerpitch).  //Rotate
        lock tval to 2/twr.
        wait until ship:verticalspeed > 2. //positive climb
        gear off. //gear up.
				wait until VANG(HEADING(90,15):VECTOR, SHIP:FACING:VECTOR) < 2.
        set runmode to 2.     //Go to the next runmode
        }

    else if runmode = 2 { // Airbreathing Mode.
        print Steerpitch at (0,0).
        if ship:groundspeed>320 and ship:groundspeed<500 lock Steerpitch to min(5,arcsin(min(1,1/twr))).
        else if ship:groundspeed < 320 and alt:radar > 3000 lock Steerpitch to min(5,arcsin(min(1,1/twr))).
        else lock Steerpitch to min(15, arcsin(min(1,1/twr))).
        //lock steering to heading(ldir,Steerpitch).
				if twr <0.5 and alt:radar > 15000
				{ag1 on.
        lights on.
				set runmode to 3.}
        clearscreen.
        }

    else if runmode = 3 { //Gravity turn
        rcs on.
        lock steering to heading (ldir, min(20, arcsin(1/(min(4,2*twr))))).
				wait until ship:apoapsis > targetApoapsis.
        set runmode to 4.
        }

    else if runmode = 4 { //Coast to Ap
      lock steering to ship:srfprograde. //Stay pointing prograde to reduce drag
      set TVAL to 0. //Engines off.
      set targetApoapsis to ship:apoapsis.
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
    }

    else if runmode = 5 { //Burn to raise Periapsis

       	if ETA:APOAPSIS < 5 or VERTICALSPEED < -1 or eta:apoapsis>100 { //If we're less 5 seconds from Ap or losing altitude
            	lock TVAL to 0.8/twr.
							pitchBal().
		}

				if ship:periapsis > 0 set tval to 0.1/twr.
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
        if ag7 CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
    }

    lock throttle to TVAL. //Write our planned throttle to the physical throttle
    if ALT:RADAR>70000 and runmode>3 {wait 1. ag6 on. wait 1. panels on.}     //Deploy solar panels & fairing, or whatever on action group 6.
		wait 0.001.
}

function pitchBal {
		IF ship:verticalspeed > 1 SET targetPitch to 0.
		else if ship:verticalspeed<-1 set targetPitch to min(20, arcsin(1/(3*twr))).
		else set targetPitch to 5.
		lock steering to heading ( ldir, targetPitch).
}
