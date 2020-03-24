# kos-booster_reuz
Autopilot 2.5
Release: 240320

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth 'KK4TEE' Persigehl's launch autopilot and I added a few features and optimized the code.

Some basic rules for designing ships to work with the code:

1. Fairings cannot be staged. Some weird KSP logic results in stage fuel becoming unreadable if a fairing is to be staged. So use action group 6 for fairings.

2. Make sure engines and decouplers are on the same stage.

3. The core of the ship MUST be on stage zero. If there's more stages after the core, the code automatically stages the vehicle (again due to stage fuel being unreadable) and you'll lose the payload.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

UPDATE 2.5:

- Adding new boot file for stock barge landing case.

- Removed landbarge as it's now integrated into land.ks as a use case.

- Cleaned up drogonland.ks and removed slope detection for now.

- Added a steering fix to hoverslam.ks which makes sure the booster lands upright and doesn't try to follow the retrograde vector for too long.

- Reworked coast steering for land.ks. It's now based on a vector which compensates better for overshoots.

- Minor code fix in launcher1.ks which sets thrust to max at takeoff and then regulates it during flight.

- Removed coast warp in upperstage.ks as it's interfering with the land autopilot.
