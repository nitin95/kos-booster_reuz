//Autopilot 2.5 build 200320
//Boostback and landing script for reusable boosters to land at launchpad. Can be used for theoretically infinite boosters.
//Updates:
//Integrated barge landing as a separate case.
//Changed coast steering to vector-based guidance for better accuracy.

clearscreen.
until ag5 HUDTEXT("Press 5 to Fly", 5, 2, 15, green, false).
loaddist(500000).

HUDTEXT("GNC Booting", 5, 2, 15, green, false).
wait 1.

set usname to ship:name.
set horizon to 0.
set fullfuel to 1.
set tval to 0.
SET radarOffset to 30. 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar-radarOffset.		// Offset radar to get distance from gear to ground
set g to 9.807.		// Gravity (m/s^2)
lock twr to ship:availablethrust/ship:mass.
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel)+30.		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear
lock impactDist to impactTime*abs(ship:groundspeed).
set rtls to ship:geoposition.			//RTLS Landing

if bargeflag = 0 {
	PRINT "RTLS Autopilot initializing" at (0,0).
	set landing to rtls.
	lock steeringPitch to max(65, 90 * (1 - alt:radar / 25000)).
}
else if bargeflag = 1 {
	PRINT "Barge Landing Autopilot initializing" at (0,0).
	lock landing to vessel("Of Course I Still Love You"):geoposition.	//Barge landing
	set land_lat to landing:lat.
	set land_lng to landing:lng.
	lock steeringPitch to max( 5, 90 * (1 - ALT:RADAR / 50000)).
}

set asctime to 0.
lock lantime to missiontime+eta:apoapsis+asctime.
lock hdist to vxcl(up:vector, landing:position):mag.
lock throttle to tval.
lock reqspeed to hdist/(lantime)*1.1+175.//*ship:mass/twr).

HUDTEXT("Variables Loaded", 5, 2, 15, green, false).
wait 1.

if alt:radar>10000 part2().
else{	//
	HUDTEXT("Go for Launch", 5, 2, 15, green, false).
	wait 1.
	clearscreen.
	wait 0.1.
	stage.
	lock tval to min(1,(2* g * SHIP:MASS) / (SHIP:availablethrust+0.01)).
	gear off.
	flightevent("Liftoff!").
	set fullfuel to stage:liquidfuel.
	wait 2.
	lock steering to heading(90, steeringPitch).
	wait 5.
		set kuniverse:timewarp:mode to "PHYSICS".
		set kuniverse:timewarp:rate to 4.
		if bargeflag = 0 {
			until (stage:liquidfuel)/fullfuel < 0.2 OR ship:apoapsis > 70000{
				print reqspeed at (0,5).
			}
		}
		else if bargeflag = 1 {
			until (stage:liquidfuel/fullfuel < 0.2 and ship:groundspeed < 0.5*reqspeed) OR ship:groundspeed > reqspeed OR ship:apoapsis > 89000{
				print reqspeed at (0,5).
				lock asctime to missiontime.
			}
		}
		set fpar to (stage:liquidfuel)/fullfuel.
		if bargeflag = 1 and fpar > 0.15 and ship:groundspeed < reqspeed{
			set abortflag to 1.
		}
		else set abortflag to 0.
		flightevent("MECO and Stage Separation").
		set tval to 0.
		sas off.
		wait 2.
		unlock steering.
		unlock throttle.
		set asctime to missiontime.
		ag10 on.
		stage.
		//flightevent("Stage Separation").
		if alt:radar>60000 ag6 on. //stages fairing, just in case.
		wait 1.
		rcs on.
		set horizon to abs(ship:groundspeed).
		lock steering to srfprograde.
		lock throttle to tval.
		set ship:name to "flyback".
		kuniverse:forceactive(vessel("flyback")).
		part2().
}

function part2 {
	SET kuniverse:timewarp:rate to 0.
	if bargeflag = 0 or (bargeflag = 1 and abortflag = 1) {	//RTLS if enabled, or if barge is too far, divert for RTLS.
		set landing to rtls.	//Pad coordinates
		lock ang_land to vang(ship:velocity:surface, landing:position).
		lock ang_vert to vang(landing:position, up:vector*-1).
		//flightevent("Flip Maneuver").
		SET steeringDir TO landing:heading. 	//point towards landing pad
		SET steeringPitch TO 0.
		lock steering to heading(steeringDir,steeringPitch).
		set steerdiff to 0.
		lock steerdiff to VANG(HEADING(steeringDir,steeringPitch):VECTOR, SHIP:FACING:VECTOR).
		until ship:groundspeed < 50{
			//wait until pointing in right direction, saves fuel.
			if steerdiff > 25 HUDTEXT("Press F if booster is stuck.", 5, 2, 15, green, false).
			if steerdiff < 25 {
				set tval TO min((2* g * SHIP:MASS) / (SHIP:availablethrust+0.01),1/(steerdiff+0.01)).
				set kuniverse:timewarp:mode to "PHYSICS".
				set kuniverse:timewarp:rate to 4.
				flightevent("Boostback").
			}
			else set tval to 0.
		}
		until ship:groundspeed > (hdist/lantime)*1.2//Guesstimate of the groundspeed needed to get back to landing pad.
		//ang_land < (180-1.8*ang_vert)//Trying to nail the horizontal velocity needed using vector angles.
		{
			set kuniverse:timewarp:rate to 0.
			if eta:apoapsis < 5 or ship:verticalspeed < 0 lock lantime to missiontime.
			print "Boostback speed needed:" + hdist/lantime*1.2 at (0,5).
			wait 0.1.
		}
		set tval to 0.
	}

	else if bargeflag = 1 and fpar > 0.2 lock steering to srfretrograde.	//Barge landing

	flightevent("Preparing for Landing"). 	//Coasting to landing

	set kuniverse:timewarp:mode to "PHYSICS".
	set kuniverse:timewarp:rate to 4.

	lock steering to srfretrograde.
	until ship:verticalspeed < 0{
		if vang(ship:facing:vector, srfretrograde:vector) < 3 rcs off.
		else rcs on.
		wait 0.5.
	}

	//Vector based steering code here:

	set land_lat_final to landing:lat.
	set land_lng_final to landing:lng.
	if bargeflag = 0 set finlanding to latlng(land_lat_final, land_lng_final).
	else lock finlanding to vessel("Of Course I Still Love You"):geoposition.	//Barge landing

	SET finland to VECDRAW(V(0,0,0), finlanding:position, green, "Landing Pad", 1.0, TRUE).
	set finland:show to true.
	set finland:vecupdater to {return finlanding:position.}.

	lock tgt_vec to landing:position*-1.
	set xcl_vec TO VECDRAW(V(0,0,0), tgt_vec:NORMALIZED , blue, "Steer Vector", 1.0, TRUE, 0.2, TRUE).
	set xcl_vec:vecupdater to {return tgt_vec.}.

	//lock steering to landing:altitudeposition(max(alt:radar-(ship:airspeed*impactTime),5))*-1.	//Old coast steering command.
	brakes on.

	//Coast commands

	UNTIL trueRadar < stopDist{
		if stockflag = 1 {//for non-grid fin rockets; use airbrakes to control descent speed for optimal aero steering.
			if ship:airspeed < 500 brakes off.
			else brakes on.
		}

		if trueRadar < 3000 {set kuniverse:timewarp:rate to 0.}	//exiting timewarp to land.

			lock weight to max(1.5, 2+(alt:radar/10000-1)).
			steerarocket(finlanding, weight).
			if trueRadar < 20000 set kuniverse:timewarp:rate to 0.
			if trueRadar < stopDist*3 lock steering to srfretrograde.
			rcs on.
	}
	clearscreen.
	clearvecdraws().
	flightevent("Performing Hoverslam").
	LOCK tval to idealThrottle.

	WAIT UNTIL ship:verticalspeed > -10.
	flightevent("Touching Down").
	gear on.
	until ship:status = "landed" or ship:status = "splashed"
	{
		if landing:distance < alt:radar*4 and landing:distance > alt:radar{
			lock tval to (g * SHIP:MASS) / SHIP:availablethrust.
			steerarocket(finlanding, 0.1).
		}
		else {
			lock steering to up.
			if ship:verticalspeed < -5
			lock tval to ((1.2*(g * SHIP:MASS) / SHIP:availablethrust)).
			else lock tval to ((0.8*(g * SHIP:MASS) / SHIP:availablethrust)).
			wait 0.01.
		}
	}
		flightevent("The booster has landed!").
		HUDTEXT(finlanding:distance, 5, 2, 15, green, false).
		set throttle to 0.
		rcs on.
		sas on.
		set ship:name to "Booster".
		wait 1.
		ag5 off.
		//kuniverse:forceactive(vessel(usname)).
		CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
}

function loaddist {	//Physics range hack from u/Ozin's code
	parameter dist.
	// Note the order is important.  set UNLOAD BEFORE LOAD,
	// and PACK before UNPACK.  Otherwise the protections in
	// place to prevent invalid values will deny your attempt
	// to change some of the values:
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNLOAD TO dist.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:LOAD TO dist-500.
	WAIT 0.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:PACK TO dist - 1.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNPACK TO dist - 1000.
	WAIT 0.

	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNLOAD TO dist.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:LOAD TO dist-500.
	WAIT 0.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:PACK TO dist - 1.
	SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNPACK TO dist - 1000.
	WAIT 0.
}

function flightevent{	//Displays events on screen.
	parameter even.
	clearscreen.
	HUDTEXT("Current Event:"+even, 5, 2, 15, green, false).
	print"Current Event:"+even at (0,1).
}

function steerarocket{
	parameter land.
	parameter deviate.
	set land_lat to land:lat.
	set land_lng to land:lng.
	lock impactPos TO POSITIONAT(ship,3+time).
	lock impactGEO TO BODY:GEOPOSITIONOF(impactPos).
	SET bodyrot TO 360 * 3 / BODY:ROTATIONPERIOD.
	//calculate the impact longitude
	SET ang TO impactGEO:LNG - bodyrot.
	if (ang > 180) {
					SET ang TO ang -(360 * CEILING((ang - 180) / 360)).
	} else if (ang <= -180) {
					SET ang TO ANG -(360 * FLOOR((ang + 180) / 360)).
	}.
	SET impactLNG TO ang.
	SET impactLAT TO impactGEO:LAT.
	clearscreen.
	PRINT "Lat: " + impactLAT.
	PRINT "Long: " + impactLNG.
	PRINT "Target Lat: " + land_lat_final.
	PRINT "Target Long: " + land_lng_final.
	wait 0.2.

	if impactLNG < land_lng_final{
		set dlng to land_lng_final - impactLNG.
		set land_lng to land_lng + dlng*deviate.
		if impactLAT < land_lat_final{
			set dlat to land_lat_final - impactLAT.
			set land_lat to land_lat + dlat*deviate.
		}
		else{
			set dlat to impactLAT - land_lat_final.
			set land_lat to land_lat - dlat*deviate.
		}
	}
	else{
		set dlng to impactLNG - land_lng_final.
		set land_lng to land_lng - dlng*deviate.
		if impactLAT < land_lat_final{
			set dlat to land_lat_final - impactLAT.
			set land_lat to land_lat + dlat*deviate.
		}
		else{
			set dlat to impactLAT - land_lat_final.
			set land_lat to land_lat - dlat*deviate.
		}
	}
	set landing to latlng(land_lat, land_lng).
	lock steering to landing:position*-1.
}
