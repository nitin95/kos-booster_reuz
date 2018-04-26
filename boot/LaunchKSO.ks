// Auto-launch program for achieving circular orbits of desired altitude and inclination
// Written by /u/only_to_downvote

// USAGE: 
// run launchToCirc(<desired orbital altitude>,  // in km (only required input)
//                  [desired inclination],       // in degrees, default value 0. (>0 for Northward, <0 for S)
//                  [auto ascent T/F],           // 'True' or 'False', default True
//                  [turn end altitude],         // in meters, default 35000
//                  [turn exponent],             // unitless, recommend 0.25-1.5 range, default 0.7.
//                  [turn start altitude] ).     // in meters, default is 2x starting altitude above terrain 
//   

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
clearscreen.
switch to 0.
run launchtoCirc(2863000).