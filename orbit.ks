//orbit.ks
// This program flies a second stage to orbit. To be used in conjunction with land.ks.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
set runmode to 3. //startup well beyond gravity turn conditions.
lights on.
set targetApoapsis to 100000. //Target apoapsis in meters
set targetPeriapsis to 75000. //Target periapsis in meters
set tval to 0.

if stage:number>=2{
	print "Program yet to initialize" at (5,4).
	wait 0.5.
	clearscreen.
}

else {
	until runmode=0{
	//Set the ship to a known configuration


		lock throttle to TVAL.
		if runmode = 3 { //Gravity turn
		        lock steering to heading(90,60). //Heading 90' (East), then target pitch
			if SHIP:APOAPSIS > targetApoapsis {
		            set runmode to 4.
				set tval to 0.
		            }
			if stage:liquidfuel<1 {
				wait 2.
				stage.//discard booster.
				}
			if TVAL=0 wait 10.//waits for ship to stabilize.
			set TVAL to 1.
		        }

		else if runmode = 4 { //Coast to Ap
		        lock steering to heading ( 90, 3). //Stay pointing 3 degrees above horizon
		        set TVAL to 0. //Engines off.
		        if (SHIP:ALTITUDE > 70000) and (ETA:APOAPSIS > 20) and (VERTICALSPEED > 0) {
		            if WARP = 0 {        // If we are not time warping
		                wait 1.         //Wait to make sure the ship is stable
		                SET WARP TO 2. //Be really careful about warping
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
				ELSE IF ETA:APOAPSIS >5 AND ETA:APOAPSIS < 100 SET targetPitch to (eta:apoapsis*-1).
		 		else if eta:apoapsis>100 set targetPitch to 45.
				else set targetPitch to 5.
				lock steering to heading ( 90, targetPitch).
		  }
			if stage:liquidfuel<1 {
				wait 0.5.
				stage.//discard booster.
			}
		  if (SHIP:PERIAPSIS > targetPeriapsis) or (SHIP:apoapsis > targetApoapsis*2) {
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
				print "SHIP SHOULD NOW BE IN SPACE!".
				CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
				set runmode to 0.
		}

		lock throttle to TVAL.

    //Print data to screen.
    print "RUNMODE:    " + runmode + "      " at (5,4).
    print "ALTITUDE:   " + round(SHIP:ALTITUDE) + "      " at (5,5).
    print "APOAPSIS:   " + round(SHIP:APOAPSIS) + "      " at (5,6).
    print "PERIAPSIS:  " + round(SHIP:PERIAPSIS) + "      " at (5,7).
    print "ETA to AP:  " + round(ETA:APOAPSIS) + "      " at (5,8).
		wait 0.001.
	}
}