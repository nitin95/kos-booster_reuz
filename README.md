# kos-booster_reuz
Autopilot 2.2
Release: 200219

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth Persigehl's launch autopilot and I added a few features and optimized the code.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

UPDATE 2.2:

-Optimization of landing scripts for better accuracy. Land.ks now flies correctly to KSC given enough aero control authority.
-Barge landing script accuracy improved. However, landing is still not possible regularly. I'll add an option in the future to land on islands.
-hoverslam can be independently used for powered landing, provided horizontal velocity isn't too high. I'll patch that in the next update.
-Further optimizing launcher1.ks for ease of use. It is now almost a one-click autopilot, but needs a bit more testing to be complete.
-Added upperstage.ks for Falcon 9 - style reusable vehicles. As the name suggests, it's to be used on the orbital stage of the rocket to get the payload to low Kerbin orbit.
-Added drogonland.ks, which will support propulsive or chute landing of capsules from orbit in the future. I'll keep you posted on that.
