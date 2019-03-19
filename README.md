# kos-booster_reuz
Autopilot 2.3
Release: 200319

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth Persigehl's launch autopilot and I added a few features and optimized the code.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

UPDATE 2.3:

-Suicide burn and boostback steering optimization.

-drogon.ks now performs a deorbit and landing on an airless body. It's got no targeting abilities though, just lands at the nearest possible point.

-Optimized booster landing script to increase delta-V contribution.

-Updated pitch balance function to work based on vertical speed, not time to apoapsis.

-Updated upperstage.ks to push the stage out of atmosphere to avoid burning up. This happened a surprising number of times.
