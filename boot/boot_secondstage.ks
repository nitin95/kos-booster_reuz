function Notify
{
	parameter msg.
	hudtext("kOS: " + msg, 5, 2, 50, yellow, false).
}

function visviva
{
	parameter body.
	parameter r.
	parameter pe.
	parameter ap.

	set radius to body:radius.
	set real_ap to ap + radius.
	set real_pe to pe + radius.
	set real_r to r + radius.
	set a to (real_ap + real_pe) / 2.
	set mu to body:mu.
	set vsq to mu * (2 / real_r - 1 / a).
	return sqrt(vsq).
}

function getaccel
{
	return ship:availablethrust / ship:mass + 0.001.
}

function InitBurn
{
	set BurnStartBurn to 0.
	set BurnScale to 1.
}

function DoBurn
{
	parameter burnvec.
	parameter time_of_burn.
	parameter eps to 0.05.
	
	lock steering to burnvec.
	
	local dv to burnvec:mag.
	local burn_time to dv / (getaccel() + 0.001).
	local time_left to time_of_burn - time:seconds - burn_time / 2.
	
	local n1 to burnvec:normalized.
	local n2 to ship:facing:vector:normalized.
	local d to vdot(n1, n2).
	if d > cos(2) // aligned
	{
		local controlled to ship = activeship.
		if controlled
		{
			if time_left > 30 and ship:altitude > ship:body:atm:height
			{
				if warpmode <> "rails"
				{
					set warp to 0.
					set warpmode to "rails".
					wait 0.1.
				}
				warpto(time:seconds + time_left - 25).
			}
			else if time_left > 5
			{
				set warpmode to "physics".
				set warp to 3.
			}
			else
			{
				set warp to 0.
			}
		}
			
		if time_left < 0 and not BurnStartBurn
		{
			if burn_time < 3
				set BurnScale to 0.2.
			set BurnStartBurn to 1.
		}
	}
	if BurnStartBurn
	{
		if dv < eps
		{
			set BurnStartBurn to 0.
			lock throttle to 0.
			unlock steering.
			wait 0.1.
			return true.
		}
		else
		{
			lock throttle to min(1, burn_time * BurnScale).
		}
	}
	return false.
}

function AdjustOrbit
{
	parameter target_time.
	parameter target_periapsis.
	parameter target_apoapsis.
	parameter adjust_vertical_speed.
	parameter eps to 0.05.
	
	InitBurn().

	local lastvertspeed to 0.
	local lasttime to 0.
	
	until false
	{
		local current_speed to visviva(ship:body, ship:altitude, ship:periapsis, ship:apoapsis).
		local target_speed to visviva(ship:body, ship:altitude, target_periapsis, target_apoapsis).
		local dv to target_speed - current_speed.
		
		local angle to -90.

		if adjust_vertical_speed and time:seconds > target_time
		{
			local slope to 0.
			if lasttime <> 0
			{
				local dt to time:seconds - lasttime.
				set slope to (ship:verticalspeed - lastvertspeed) / dt.
			}
			set offsetangle to -ship:verticalspeed * 1.5 - slope * 3.
			set angle to -90 + offsetangle.
			set lastvertspeed to ship:verticalspeed.
			set lasttime to time:seconds.
		}

		local n1 to up + R(0, angle, 180). // direction of burn

		if DoBurn(n1:vector * dv, target_time, eps)
			break.
			
		wait 0.01.
	}
}

function GetSemimajorAxis
{
	parameter seconds.
	local k1 to seconds / (2 * constant:pi).
	return (k1 * k1 * ship:body:mu) ^ (1/3).
}

function GetDecouplerList
{
	local decouplers to list().
	for p in ship:parts
	{
		if p:name:contains("Decoupler")
		{
			if not p:children:empty()
				decouplers:add(p).
		}
	}
	return decouplers.
}

function ToggleProbePower
{
	parameter parent.
	
	if parent:name:contains("KR-2042")
	{
		local mod to parent:getmodule("kOSProcessor").
		mod:doevent("toggle power").
	}
	else if not parent:children:empty()
	{
		for p in parent:children
			ToggleProbePower(p).
	}
}

function Decouple
{
	parameter decoupler.
	
	local mod to decoupler:getmodule("ModuleDecouple").
	mod:doaction("decouple", true).
}

function TimeToLng
{
	parameter lng.
	
	local period to ship:orbit:period.
	local lngdiff to lng - ship:geoposition:lng.
	if lngdiff < 0
		set lngdiff to lngdiff + 360.
	return period * lngdiff / 360.
}

function WarpToLngCoarse
{
	parameter lng.
	parameter mintime.
	
	local offset to TimeToLng(lng).
	if offset < mintime
		set offset to offset + ship:orbit:period.
	local lng_time to time:seconds + offset.
	
	if warpmode <> "rails"
	{
		set warp to 0.
		set warpmode to "rails".
		wait 0.1.
	}
	warpto(lng_time - 1).
	wait until lng_time < time:seconds.
}

function WarpToLngFine
{
	parameter lng.
	
	local lng_time to time:seconds + TimeToLng(lng).
	
	until ship:geoposition:lng > lng - 1
	{
		if warpmode <> "physics"
		{
			set warp to 0.
			set warpmode to "physics".
			wait 0.1.
		}
		if warp <> 3
			set warp to 3.
		wait 1.
	}
	set warp to 0.
	wait until ship:geoposition:lng > lng.
}

function GetSunLng
{
	local planetpos to ship:body:position.
	local sunpos to body("sun"):position - planetpos.
	local planetvec to -planetpos:normalized().
	local ortho to vcrs(planetvec, v(0,1,0)).
	local sunvec to sunpos:normalized().

	local x to vdot(planetvec, sunvec).
	local y to vdot(ortho, sunvec).
	local angle to arctan2(y, x).
	local shipangle to ship:geoposition:lng.
	local sunangle to shipangle + angle.
	if sunangle < -180
	  set sunangle to sunangle + 360.
	if sunangle > 180
	  set sunangle to sunangle - 360.
	return sunangle.
}

print("Second Stage Computer Online").

local GeoSemi to GetSemimajorAxis(6 * 3600).
local TransferSemi to GetSemimajorAxis(4.5 * 3600).
local GeoApoapsis to GeoSemi - ship:body:radius.
local TransferPeriapsis to 2 * TransferSemi - GeoSemi - ship:body:radius.

local DeorbitLng to 1.89. // found by testing

if ship:altitude < 1000 // init on launchpad
{
	Notify("Wait for user. Press ABORT to launch").
	wait until ship:verticalspeed > 5.
	Notify("Liftoff").
	wait until ship:verticalspeed > 100. // we are flying

	local decouplers to GetDecouplerList().
	for dec in decouplers
		ToggleProbePower(dec).
	
	local currentstage to stage:number.

	// wait until seperation
	wait until stage:number <> currentstage.
	Notify("Second Stage seperated").
	
	wait 2.
	lock throttle to 1.

	Notify("Second Stage ignition. Continue to orbit").
	
	until false
	{
		local target_height to 80000.
		local turn_end to 15000.
		local turn_angle to 50.
				
		local x to ship:altitude / 1000.
		local maxspeed to 0.
		if x < 35
			set maxspeed to x / 35 * 900 + 200.
		else
			set maxspeed to (x - 35) / 15 * 1000 + 1100.
		local shipspeed to ship:velocity:surface:mag().
		local target_throttle to 1 - 10 * (shipspeed / maxspeed - 1).
		lock throttle to target_throttle.
		
		local angle to 0.
		if ship:altitude < 400
			set angle to alt:radar / 400 * 5.
		else if ship:altitude < turn_end
			set angle to min(ship:altitude / turn_end * (turn_angle - 5) + 5, turn_angle).
		else
			set angle to max(90 - (target_height - ship:apoapsis) / 1000, turn_angle).
		lock steering to up + R(0, -angle, 180).
		
		if ship:apoapsis > target_height
		{
			lock throttle to 0.
			break.
		}
		wait 0.01.
	}

	Notify("Second Stage coasting to Apoapsis").
	
	AdjustOrbit(time:seconds + eta:apoapsis, ship:apoapsis, ship:apoapsis, true).
	
	Notify("Second Stage has reached orbit").
	
	lights on.
}
else if ship:periapsis < TransferPeriapsis * 0.9 and ship:periapsis > 70000 // in orbit but not in transfer orbit
{
	if ship:apoapsis < GeoApoapsis * 0.9 // apoapsis not yet adjusted
	{
		wait until abort.
		abort off.
		
		if stage:number > 2
			stage. // deploy fairing
		wait 5.
		
		local notified to false.
		until false
		{
			if notified
				Notify("Waiting another orbit for sun alignment").
			else
				Notify("Waiting until sun alignment").
			set notified to true.
			//print("pre coarse warp").
			WarpToLngCoarse(DeorbitLng - 2, 30).
			//print("post coarse warp").
			local shiplng to ship:geoposition:lng.
			local sunlng to GetSunLng().
			if shiplng - 90 < sunlng and shiplng > sunlng
				break.
		}
		print("start lng coarse: " + ship:geoposition:lng).
		WarpToLngFine(DeorbitLng).
		
		print("start lng: " + ship:geoposition:lng).

		// first burn
		AdjustOrbit(time:seconds + 100, ship:periapsis, GeoApoapsis, false).
		// fine tune
		AdjustOrbit(time:seconds + 20, ship:periapsis, GeoApoapsis, false, 0.01).
	}
	if eta:apoapsis > 120
	{				
		if warpmode <> "rails"
		{
			set warp to 0.
			set warpmode to "rails".
			wait 0.1.
		}
		if warp = 0
		{
			warpto(time:seconds + eta:apoapsis - 120).
			wait 1.
		}
	}
	
	// adjust peri
	AdjustOrbit(time:seconds + eta:apoapsis, TransferPeriapsis, ship:apoapsis, true).
	// fine tune
	AdjustOrbit(time:seconds + 20, TransferPeriapsis, ship:apoapsis, true, 0.01).
	
	reboot.
}
else // in transfer orbit or deorbiting
{
	// get all decouplers
	local decouplers to GetDecouplerList().
	if decouplers:empty // all satellites deployed, deorbit
	{
		local deorbit_periapsis to 30000.
		
		if ship:periapsis * 0.9 > deorbit_periapsis
		{
			AdjustOrbit(time:seconds + eta:apoapsis, deorbit_periapsis, ship:apoapsis, false).
		}
		
		until ship:altitude < 100000
		{
			if warpmode <> "rails"
			{
				set warp to 0.
				set warpmode to "rails".
				wait 0.1.
			}
			if warp <> 5
				set warp to 5.
			wait 0.01.
		}
		set warp to 0.
		wait 1.
		until false
		{
			if ship:altitude < 80000
			{
				lights off.
			}
			if ship:altitude < 70000
				lock steering to -ship:velocity:surface.
			if ship:altitude < 30000
				unlock steering.
			if alt:radar < 12
			{
				local target_v to 5.
				lock throttle to (-ship:verticalspeed - target_v).
				if ship:status <> "FLYING"
				{
					print("stop lng: " + ship:geoposition:lng).
					break.
				}
			}
			wait 0.01.
		}
	}
	else
	{
		// warp to apoapsis - 45
		until eta:apoapsis < 230
		{
			if warpmode <> "rails"
			{
				set warp to 0.
				set warpmode to "rails".
				wait 0.1.
			}
			if eta:apoapsis > 240 and warp = 0
			{
				warpto(time:seconds + eta:apoapsis - 230).
				wait 1.
			}
			wait 1.
		}
						
		// enable power
		ToggleProbePower(decouplers[0]).
		
		wait until brakes.
		// decouple
		Decouple(decouplers[0]).
		
		wait 1.
		brakes off.
		
		wait until ship <> activeship.
		wait 10.
		wait until ship = activeship.
		// reboot for next pass
		reboot.
	}
}

set ship:control:pilotmainthrottle to 0.
