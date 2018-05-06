function ShutdownEngines
{
//    for p in ship:parts
  //  {
        //if p:name:contains("Engine")
        //{
        //    local m to p:getmodule("ModuleEnginesFX").
        //    m:doevent("shutdown engine").
        //}
    //}
    lock throttle to 0.
}
function ActivateEngines
{
    for p in ship:parts
    {
        if p:name:contains("Engine")
        {
            local m to p:getmodule("ModuleEnginesFX").
            m:doevent("activate engine").
        }
    }
}

wait until abort.
abort off.

sas on.

if ship:status = "SPLASHED"
{
    if ship:availablethrust < 1
        ActivateEngines().
}
else
{
    stage.

    set warp to 0.
    wait 0.1.
    set warpmode to "physics".
    set warp to 3.

    until ship:status = "SPLASHED"
    {
        local speed to ship:groundspeed.
        local targetspeed to 10.
        lock throttle to (targetspeed - speed) / 20.

        if speed > 15
            brakes on.
        if speed < 14
            brakes off.
        wait 0.01.
    }
}
wait 3.
brakes off.
gear off.
lights on.

local target_lng to -63.6. //-62.33.
local target_lat to 0.

local meters_per_degree to ship:body:radius * 2 * constant:pi / 360.

set warp to 0.
wait 0.1.
set warpmode to "physics".
set warp to 3.

local averagespeed to 0.
local speedloop to pidloop(0.01, 0.01, 0.005, 0, 1).
set speedloop:setpoint to 50.
until false
{
    local pos to ship:geoposition.
    local dx to (target_lng - pos:lng) * meters_per_degree.
    local dy to (target_lat - pos:lat) * meters_per_degree.
    local ds to sqrt(dx * dx + dy * dy).
    set speedloop:setpoint to min(50, ds / 100).
    lock throttle to speedloop:update(time:seconds, ship:groundspeed).
    local speed to ship:groundspeed.
    set averagespeed to (averagespeed * 99 + speed) / 100.
    local tta to ds / (averagespeed + 0.01).

    if ds / (ship:groundspeed + 0.01) < 20
        break.

    local yaxis to north:vector().
    local xaxis to vcrs(up:vector(), yaxis).
    local steer to (xaxis * dx + yaxis * dy):normalized().
    lock steering to steer.

    //set axis1 to vecdraw(v(0, 0, 0), xaxis, RGB(255, 0, 0), "X-Axis", 50, true, 0.1).
    //set axis2 to vecdraw(v(0, 0, 0), yaxis, RGB(0, 255, 0), "Y-Axis", 50, true, 0.1).
    //set axis3 to vecdraw(v(0, 0, 0), steer, RGB(0, 0, 255), "steer", 50, true, 0.1).

    clearscreen.

    local minutes to round(tta / 60 - 0.5, 0).
    local seconds to round(tta - minutes * 60, 0).
    local mstr to "".
    local sstr to "".
    if minutes < 10
        set mstr to "0".
    if seconds < 10
        set sstr to "0".
    print "Time to arrival: " + mstr + minutes + ":" + sstr + seconds.
}

set warp to 0.
wait 1.
brakes on.
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
wait 1.
sas off.
clearscreen.
print("Finished").

ShutdownEngines().
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Toggle Power").
