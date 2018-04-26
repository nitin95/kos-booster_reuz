// boostback_boot.ks
clearscreen.
switch to 0.
wait 5.
print "boostback boot program running, waiting for message to start.".
local done is false.

if ship:status = "LANDED" {
	run landboost.
}

until done {
		ship:messages:pop.
		switch to 0.
		runpath("0:/boostback.ks", 0, msg:sender).
		set done to true.
	wait 0.4.
}
