# kos-booster_reuz
Autopilot 2.4.2
Release: 210120

Set of autopilots cobbled together aiming to fully automate launch and recovery of orbital rocket boosters and SSTOs. Right now, only booster landings are supported.

Hoverslam functions are derived from mrbradleyjh's script, boostback algorithms are mine, orbital autopilot is a trimmed down version of Seth Persigehl's launch autopilot and I added a few features and optimized the code.

Some basic rules for designing ships to work with the code:

1. Fairings cannot be staged. Some weird KSP logic results in stage fuel becoming unreadable if a fairing is to be staged. So use action group 6 for fairings.

2. Make sure engines and decouplers are on the same stage.

3. The core of the ship MUST be on stage zero. If there's more stages after the core, the code automatically stages the vehicle (again due to stage fuel being unreadable) and you'll lose the payload.

Feel free to use the code for your own scripts. If you're posting content based on this, I'd really appreciate it if you tagged me in the post. (u/nitinm95 on Reddit).

NOTE:

I'm back to work on the code. More updates to come in the next few months. If you feel like tinkering, again, the code is yours to do as you wish. Cheers.

UPDATE 2.4.2:

- Land.ks now does the boostback burn right after staging, improving fuel efficiency.

- Land.ks ascent trajectory made a bit shallower (pitch 65 from 75) to make use of new boostback technique.

- Added a prototype interface to land.ks terminal.
