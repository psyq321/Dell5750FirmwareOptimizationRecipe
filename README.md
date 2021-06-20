# Dell5750FirmwareOptimizationRecipe
UEFI Firmware Optimization Recipe for Connected Standby and Low Temperature (Dell Precision 5750 and XPS 17)

With these changes following issues are addressed:

1. Overheating and CPU thermal throttling (#PROCHOT), especially if system uses NVIDIA RTX GPU and 4K/8K display
2. Inability to enter fully in S0 Standby resulting either in no sleep, or significant battery drain during sleep
3. Flood of infamous "OED Event Id 19" Events in Event Viewer
4. Windows 10 Sleep Study complaining that Smart Sound is staying awake during S0 standby  
5. Windows 10 disabling ASPM power management due to firmware telling it to do so
6. Locked configuration for CPU voltage undervolting (we need it for #1 anyway)

**NOTE: Recipe is currently suitable for experts only. It assumes advanced knowledge about UEFI, Intel Platforms esp. Comet Lake and other concepts from platform engineering. Furthermore, applying the NVRAM patches could result in bricked systems in case of mistakes. Proceed with caution.**

# Example Results:

This is the behavior of Dell 5750 system after applying the recipe. Now it passes all checkpoints for S0iX standby, including CPU >and< PCH. Most of the peripherals are in D-states, except the ones that cannot be (e.g. CPU). Furthermore, temps are considerably down, and #PROCHOT is very rarely seen (in this case, CPU core voltage is changed by: -0.125v)

**Visualization of 130s trace with 100s in S0 Standby**

![Alt text](/Demo/SocWatch_60sec_Timeline_Annotated.png?raw=true)



