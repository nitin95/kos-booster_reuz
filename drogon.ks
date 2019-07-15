//Autopilot 2.4 build 150719
//Experimental autopilot to fly a capsule to the Mun.

set runtrig to "on".

until runtrig="off"{
if alt:radar<100 and ship:groundspeed < 1 and ship:body:name = "Kerbin" run launcher1.ks.

else if ship:body:name = "Kerbin" and ship:periapsis>70000 run muntransfer.ks.

else if ship:body:name = "Mun" and ship:periapsis>7000	run drogonland.ks.
}
