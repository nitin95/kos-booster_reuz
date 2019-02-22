# kos-booster_reuz
Autopilot 2.2.1
Release: 220219

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth Persigehl's launch autopilot and I added a few features and optimized the code.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

UPDATE 2.2.1:

-Removed bug which caused boosters to get stuck while flipping for boostback.
-Further optimized final landing code for smoother experience.
-Removed redundant code for better reading.
-Upperstage autopilot gravity turn height raised to avoid atmospheric friction in certain scenarios that deorbited the stage.
-drogonland.ks is now drogon.ks. It'll be a full mission autopilot, more on that soon.
