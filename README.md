## UEFI Firmware Optimization Recipe for Dell Precision 5750 (and XPS 17*) 
UEFI Firmware Optimization Recipe for Connected Standby and Low Temperature (Dell Precision 5750 and XPS 17)

With these changes following issues are addressed:

1. Overheating and CPU thermal throttling (#PROCHOT), especially if system uses NVIDIA RTX GPU and 4K/8K display
2. Inability to enter fully in S0 Standby resulting either in no sleep, or significant battery drain during sleep
3. Flood of infamous "OED Event Id 19" Events in Event Viewer
4. Windows 10 Sleep Study complaining that Smart Sound is staying awake during S0 standby  
5. Windows 10 disabling ASPM power management due to firmware telling it to do so
6. Locked configuration for CPU voltage undervolting (we need it for #1 anyway)

**NOTE: Recipe is currently suitable for experts only. It assumes advanced knowledge about UEFI, Intel Platforms esp. Comet Lake and other concepts from platform engineering. Furthermore, applying the NVRAM patches could result in bricked systems in case of mistakes. Proceed with caution.**

## Example Results:

This is the behavior of Dell 5750 system after applying the recipe. Now it passes all checkpoints for S0iX standby, including CPU >and< PCH. Most of the peripherals are in D-states, except the ones that cannot be (e.g. CPU). Furthermore, temps are considerably down, and #PROCHOT is very rarely seen (in this case, CPU core voltage is changed by: -0.125v)

**Visualization of 130s trace with 100s in S0 Standby**

The main giveaway is PCH asserting SLP-S0 - Anybody who dealt with this knows the number of constraints that need to happen before PCH finally dozes off. We can see this (partially) on the screenshot: almost all devices must go into D3+ standby before PCH can get itself to deep sleep. Every miss translates into extra hundreds of mW, sometimes more, to the horror of your battery and you the following day.

![Alt text](/Demo/SocWatch_60sec_Timeline_Annotated.png?raw=true)

**ThrottleStop showing a nice picture**

While not in standby, the system is also drawing a meager amount of power. We can see that the CPU consumes down to 0.5 W of power, mainly thanks to aggressive C-state promotion to C7 (CPU cores) and C10 (CPU Package). If the system is not appropriately configured, the CPU is also often disrupted by other peripherals bombarding the CPU with interrupts or, sadly, crappy software being crappy software.

![Alt text](/Demo/ThrottleStop_CST_WhileIdle.png?raw=true)

**At the end of the day, battery sensors do not lie :-)**

Finally, getting everything in order also means reaching advertised battery life, or... exceeding it a bit:

![Alt text](/Demo/PoweDrain_Idle.jpg?raw=true)

And before you compare this with your latest and greatest thinner-than-razor Tiger Lake Ultrabook, please bear in mind that this is a mobile workstation we are talking about! This one, in particular, has an eight-core 5.1 GHz Intel Comet Lake CPU, NVIDIA RTX 3000 Quadro GPU, 64 GB of RAM, 2 SSDs, and a power-hungry 4K UHD display. Therefore, you must adjust expectations somewhat.

(*) Not Tested, but systems are very similar.

