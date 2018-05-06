function SetAirbrakeSteering
{
	parameter enable.

	for p in ship:parts
	{
		if p:name:contains("airbrake")
		{
			local m to p:getmodule("ModuleAeroSurface").
			m:setfield("pitch", not enable).
			m:setfield("yaw", not enable).
		}
	}
}

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
clearscreen.
print("First Stage Computer online").

wait until abort.
abort off.

set config:ipu to 500.
wait 0.01.

set ship:loaddistance:flying:unload to 250000.
set ship:loaddistance:flying:load to 240000.
wait 0.01.

set ship:loaddistance:flying:pack to 230000.
set ship:loaddistance:flying:unpack to 220000.
wait 0.01.

set ship:loaddistance:orbit:unload to 250000.
set ship:loaddistance:orbit:load to 240000.
wait 0.01.

set ship:loaddistance:orbit:pack to 230000.
set ship:loaddistance:orbit:unpack to 220000.
wait 0.01.

set ship:loaddistance:suborbital:unload to 250000.
set ship:loaddistance:suborbital:load to 240000.
wait 0.01.

set ship:loaddistance:suborbital:pack to 230000.
set ship:loaddistance:suborbital:unpack to 220000.
wait 0.01.

sas on.
SetAirbrakeSteering(false).
stage.
wait 0.01.
set fullFuel to stage:liquidfuel.
until stage:liquidfuel/fullFuel < 0.2
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
}
function GetThrust
{
	local thrust to 0.
	LIST engines in es.
    for eng in es
		set thrust to thrust + eng:thrust.
	return thrust.
}

local upper_stage_name to ship:name.

lock throttle to 0.
sas off.
stage.
wait 2.
kuniverse:forceactive(ship).

set target to vessel(upper_stage_name).

rcs on.
SetAirbrakeSteering(true).
lock steering to -ship:velocity:surface.

lock throttle to 0.

wait 15.
lock throttle to 0.4.
wait 2.
lock throttle to 0.


wait until ship:verticalspeed < 0.

local drone to vessel("Of Course I Still Love You").

local burn to 0. // 0 = no landing, 1 = coarse landing, 2 = soft touchdown
local correction_burn to 0. // 0 = not corrected, 1 = correction burn, 2 = corrected

until false
{
	local thrust to ship:availablethrust.
	local center_distance to ship:altitude + ship:body:radius.
	local g to ship:body:mu / (center_distance * center_distance).
	local a to thrust / ship:mass - g.
	local vy to -ship:verticalspeed.
	local h to ship:altitude.

	// predict path without engine power
	local k1 to vy / g.
	//print("h: " + h).
	//print("g: " + g).
	//print("k1: " + k1).
	local time_to_impact to sqrt(2 * h / g + k1 * k1) - k1.
	local yaxis to north:vector().
	local xaxis to vcrs(up:vector(), yaxis).
	local velocity to ship:velocity:surface.
	local xvel to vdot(velocity, xaxis).
	local yvel to vdot(velocity, yaxis).

	local xdist to xvel * time_to_impact.
	local ydist to yvel * time_to_impact.
	local degreescale to 360 / (ship:body:radius * 2 * constant:pi).
	local impact_lng_offset to xdist * degreescale.
	local impact_lat_offset to ydist * degreescale.
	set impact_lng_offset to impact_lng_offset * 0.74. // aerodynamic factor found by testing
	local ship_lng to ship:geoposition:lng.
	local impact_lng to impact_lng_offset + ship_lng.

	//print("tti: " + time_to_impact).
	//print("yvel: " + yvel).
	//print("ydist: " + ydist).
	//print("drone: " + drone:geoposition:lat).
	//print("ship: " + ship:geoposition:lat).
	//print("speed: " + impact_lat_offset).

	local latdiff to drone:geoposition:lat - ship:geoposition:lat - impact_lat_offset.
	local offset_axis to north:vector() * latdiff * 15.
	if burn = 0
		lock steering to (offset_axis - ship:velocity:surface:normalized()).
	if (abs(latdiff) > 1 / 200)
		lock throttle to 0.03.
	else
		lock throttle to 0.

	if (ship:altitude < 20000)
		lock throttle to 0.

	if correction_burn = 0
	{
		if h < 16000
		{
			set correction_burn to 1.
			brakes on.
		}
	}
	else if correction_burn = 1
	{
		//print("drone lng: " + drone:geoposition:lng).
		//print("ship lng: " + ship_lng).
		//print("impact lng: " + impact_lng).

		local steer to 0.
		if drone:geoposition:lng < impact_lng
			set steer to up:vector() - xaxis.
		else
			set steer to up:vector() + xaxis.

		lock steering to steer.

		lock throttle to 1.
		if abs(drone:geoposition:lng - impact_lng) < 1 / 120 or h < 5000
		{
			lock throttle to 0.
			set correction_burn to 2.
		}
	}

	if h < 2200 and not burn
		set burn to 1.

	if burn
	{
		local time_to_land to 0.
		if burn = 1
		{
			local target_a to vy * vy / (2 * max(h - 70, 10)).
			set time_to_land to vy / target_a.
			//print("time to land: " + time_to_land).

			local thrust to (target_a + g) * ship:mass / (thrust + 0.01).
			lock throttle to thrust.
		}
		else
		{
			local target_v to 10.
			if ship:altitude < 50
				set target_v to 5.
			if ship:altitude < 30
				set target_v to 2.
			local target_a to vy - target_v.
			set time_to_land to ship:altitude / target_v.
			local thrust to (target_a + g) * ship:mass / (thrust + 0.01).
			lock throttle to thrust.
		}

		//local target_pos to drone:position + drone:facing:vector() * 0.7.
		//local ground_target to target_pos - up:vector() * vdot(target_pos, up:vector()).
		//set ground_vel to ship:velocity:surface - up:vector() * vdot(ship:velocity:surface, up:vector()).
		//set ground_pos to ground_vel * 5.
		//local ground_direction to ground_target - ground_pos.
		//lock steering to lookdirup(up:vector() * max(min(ship:altitude, 500), 100) + ground_direction, north:vector()).

		local target_pos to drone:position + drone:facing:vector() * 0.7.
		local ground_target to target_pos - up:vector() * vdot(target_pos, up:vector()).
		set ground_vel to ship:velocity:surface - up:vector() * vdot(ship:velocity:surface, up:vector()).
		local Kp to 0.1.
		local Kd to 0.8.
		if h < 100
			set Kd to 0.4.
		local correction_accel to ground_target * Kp - ground_vel * Kd.
		local accel to GetThrust() / ship:mass.
		local max_correction to tan(20) * accel.
		if correction_accel:mag() > max_correction
			set correction_accel to correction_accel:normalized() * max_correction.
		local newup to up:vector() * accel + correction_accel.
		lock steering to lookdirup(newup, north:vector()).

		//set drawaxis1 to vecdraw(v(0,0,0), target_pos, RGB(255, 0, 0), "tar", 1, true, 0.1).
		//set drawaxis2 to vecdraw(v(0,0,0), ground_vel, RGB(0, 255, 0), "vel", 1, true, 0.1).
		//set drawaxis3 to vecdraw(v(0,0,0), newup, RGB(0, 0, 255), "newup", 10, true, 0.1).
		//set drawaxis4 to vecdraw(v(0,0,0), ground_target, RGB(255, 0, 0), "groundtarget", 1, true, 0.1).

		if ship:altitude < 80
		{
			gear on.
			brakes off.
			set burn to 2.
		}
		if ship:status = "LANDED"
		{
			lock throttle to 0.
			lock steering to up.
			brakes off.
			break.
		}
	}

	wait 0.01.
}

wait 3.
rcs off.
set ship:control:pilotmainthrottle to 0.
clearvecdraws().
