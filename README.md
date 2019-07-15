# kos-booster_reuz
Autopilot 2.4
Release: 150719

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth Persigehl's launch autopilot and I added a few features and optimized the code.

Some basic rules for designing ships to work with the code:

1. Fairings cannot be staged. Some weird KSP logic results in stage fuel becoming unreadable if a fairing is to be staged. So use action group 6 for fairings.

2. Make sure engines and decouplers are on the same stage.

3. The core of the ship MUST be on stage zero. If there's more stages after the core, the code automatically stages the vehicle (again due to stage fuel being unreadable) and you'll lose the payload.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

NOTE:

I will no longer be maintaining this repo from 15/07/2019. This has been a fun journey, but IRL commitments means I'll have to stop gaming entirely for a while. I don't know when I'll be back, but if you feel like tinkering, again, the code is yours to do as you wish. Cheers.

UPDATE 2.4:

-drogon.ks now capable of a full Mun mission. Watch your staging though :-).

-Converted previous drogon.ks to standalone landing script drogonland.ks, which any ship can use for deorbiting any body provided enough fuel is available.

-New rudimentary SSTO launch autopilot. Press 5 on the runway to get to orbit! Also assign AG1 to switch Rapier modes.

-Updated first stage throttle control in all launch scripts. Locked to 1.6 for launcher1 and landbarge and 2.0 for land (higher apoapsis required for RTLS, TWR<2 results in longer boostback burn).

-landbarge now calculates MECO based on position of droneship at liftoff, still dialing in the equations.

-launcher1 trajectory optimized to reduce drag losses, and modified to work with drogon.ks as well as standalone.

TBD (just some notes for if I return):
-Full droneship and precision LZ landings using PID's and vectors to steer the rocket.
-Interplanetary mission autopilots, with one click from launch to landing.
-Rudimentary booster refurbishment program (This can be simulated using the Kerbal Construction Time and Scrapyard mods, which reduces the time required to assemble the vessel if any components are recovered).
