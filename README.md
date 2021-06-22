## UEFI Firmware Optimization Recipe for Dell Precision 5750 (and XPS 17*) 
UEFI Firmware Optimization Recipe for Connected Standby and Low Temperature (Dell Precision 5750 and XPS 17)


Dell Precision 5750 is a workstation version of XPS 17 - and, on paper and the first look, as of late 2020 / early 2021, was the absolute best PC laptop, in my opinion. And this is coming from a long-time user of high-end laptops (from fully maxed-out Sony Vaio Z-s, Apple Retina Macbook Pros to Lenovo W and p-s). 

Sadly, due to factors outside of OEMs control, this system, like many comparable ones, suffers from heavy battery drain in the so-called "Connected Standby" (technical term: S0iX). Also, due to the coincidence to be released after a zero-day exploit called "Plundervolt," Intel and OEMs decided to lock users out of lower CPU voltages. Unfortunately, reducing CPU voltage is greatly missed if you cram together 45W (haha) Core i7-10850H or Xeon W-10885M, 60W Quadro RTX 3000 Max-Q, 64 GB of RAM, and top it up with two NVMe SSDs... 

The image below is what I am getting while using an 8K monitor (requires forcing dGPU): CPU shoots to TJMax temperature (even more!) within a second.

![Alt text](/Demo/Original_TempsWith8K.jpg?raw=true)

Ouch... then there is the whole problem of "Modern Standby", these are some extremes:

- https://www.reddit.com/r/Dell/comments/miug49/brand_new_xps_17_sleeps_at_27_watts/  - Sleep with 27W... really?

Again, I have no reason to believe this is just a Dell problem. Unfortunately, these systems are hit worst because they deviate from the "Reference Design" the most (so much more things could go bad) and contain the most power-hungry components from different IHVs. Furthermore, modern CPUs are extremely powerful: this Comet Lake system has `IccMax` of 155 A and can, for a short time shoot well past 100 W of power.

My case was moderate: battery discharge rate was "just" 2,199 mW - enough to deplete a good chunk of the battery by morning. And that is on a good day. It would just refuse to sleep on a bad day and randomly go to full power while in the backpack while becoming too hot to touch. People were "solving" these problems by forcing Windows to the S3 standby regime. Still, since Windows 10 build 2004, this is impossible (no, an alternative registry hack is just disabling S0iX - it does not magically bring good old S3, for that one needs system firmware that cooperates). Even while this was possible, due to nobody caring about S3 anymore and testing it, what you gained in standby, you would lose soon after resume, as CPU would lose the ability to promote low-power C-states until the next reset.

![Alt text](/Demo/Original_PowerDrain1.jpg?raw=true)

Finally, there is the case of Intel "Smart Sound" (SST) from the pic above flooding Windows Event Log with infamous "Event Id 19":

https://www.dell.com/community/XPS/Intel-SST-OED-event-log-id-19/td-p/7803734

OED Event 19 also affects other OEMs (google it), and apparently SoC vendor is also struggling to answer, pointing people back to OEMs.

I would not be surprised if you stopped reading by now! But, worry not, we're going to fix ALL of this!

**Yes, all of it:**

1. Frequent overheating and CPU throttling, especially if the system uses NVIDIA RTX GPU and outputs on, e.g., 8K display
2. Inability to enter fully S0iX state ("Connected Standby") resulting either in a) no sleep or b) significant battery drain during "sleep"
3. System "awaking" in backpacks, etc. (actually it is more of system never sleeping in the first place)
4. Flood of infamous "OED Event Id 19" entries in Event Viewer (I did not eliminate this fully, but it appears rarely now) 
5. Windows 10 Sleep Study complaining that Intel SST Audio Controller stayed awake during "sleep." 
6. Windows 10 disabling Active-state Power Management (ASPM) due to system firmware telling it to do so
7. CPU voltage and control locked, preventing undervolting or adjusting CPU performance params by user

**NOTE: For now, the recipe is currently suitable for experts only. It expects users possess advanced knowledge about UEFI, Intel Platforms esp. Comet Lake as well as Microsoft "Connected Standby" requirements and guidelines. Furthermore, applying the NVRAM patches could result in bricked systems in case of mistakes. Proceed with caution.**

## Theory of Operation (or, how are we going to do it)

First, one needs to divide this mess of problems into managable parts. Fortunately, in this case, problems are actually caused by two different root causes:

1. Platform not entering S0iX state, or failing to fully power down all components
2. CPU + GPU simply too hot for the package under stock conditions 

Beware, both root causes are complex, and could be broken down - especially the first one, it consists of many contributing factors (all of which we need to solve!). Fortunately, solutions also follow the same split, and both root causes share big chunk of work in one area: **patching the firmware**.

But before we start hacking, following steps are highly recommended (I'd say must be observed if one does not want surprises):

## Prerequisites

- Latest BIOS update from Dell 
- System BIOS image dumped to file (e.g. via `FPT` tool) and UEFI IFRs extracted from the "Setup" firmware binary (`UEFITool`, `ifrextract`)
- Clean Windows installation (this guide does not deal with Linux for now) - preferably the latest released build
- Latest set of official Dell-approved drivers (from their website) - ideally slipstreamed in Windows installation (WinPE)
- No 3rd party software for now (you can add it after confirming things are fixed!)
- `ThrottleStop` (we will need it at the end) - you could also program settings in firmware after proven stable

Basically, by deploying clean Windows 10 install with slipstreamed Dell drivers, on the latest firmware (so, latest CPU uCode/mRC, ME, SST DSP firmware) you are as close as possible to so-called "Best Known Configuration" (BKC) one gets from the platform vendor as possible as ordinary customer. This also helps minimize the number of variables under consideration.

## Patch Preparation (IMPORTANT)

TBD

## Firmware Patching

- After reviewing the patch script and ensuring variable locations (and values) are correct, you can boot in the modified GRUB2 environment
- Ensure that the notebook is connected to AC power and not hot (to prevent thermal shutdown while patching)
- Run the firmware patch script from within the GRUB console: it will patch your system "live."
- You shall see no errors, but if you do and they are of 0x1A sort (security violation), you might need to restore BIOS to defaults and re-patch
- Power off, Power On, go to Windows

**At this point, you shall:**

- Ensure Windows is (still) booting :)
- Check Device Manager for any signs of faults: if you see yellow bangs, likely, we went overboard with PCIe power management (ASPM)
- The problem above is notoriously tricky, and of course, depends on the hardware downstream, so you will need to locate the actual port and modify ASPM
- Validate that system is still S0 capable with = `powercfg -a`
- Validate that the system does not have any power management errors with `powercfg -energy` - particularly, we do not want to see ASPM errors.
- Over time, keep checking results of Sleep Studies (`powercfg -sleepstudy`) to ensure everything is "green" (no, really green - this is not a pun)

If you are still stuck here, you might want to download **Intel Soc Watch** and start collecting and reviewing traces with excellent Intel VTune Amplifier (you can see the "good" results visualized in VTune below)

This command will log interesting things for us:

`socwatch.exe -t 60 -f cpu-cstate -f acpi-sstate -f pch-slps0 -f pch-slps0-dbg -f pkg-pwr -f acpi-dstate -r vtune --max-detail`

You will need to put your system to sleep after SoC Watch starts, as the monitoring duration is only 60 seconds here. SoC Watch can do it for you and manage the sleep state, but only if you have a "button" driver bundled with Windows Driver Kit...

What you want to see afterward is something like this:

```
================
PCH SLP-S0 State
================

The residency reported below could under-report the actual SLP-S0 time when PMC clock throttling occurs.

PCH SLP-S0 State Summary: Residency (Percentage and Time)
PCH SLP-S0 States, PCH Residency (%), PCH Residency (msec)
-----------------, -----------------, --------------------
Not in SLP-S0    , 17.59            , 23788.75            
SLP-S0           , 82.41            , 111462.54           
```

The above information means Platform Controller Hub (PCH or "Southbridge") is happy and confirms S0! Getting the PCH to do so is one of the hardest things to achieve as PCH will ***not*** do it until all components connected to it and cleared for "Connected Standby" are in some approved sleep state (D3, D3Cold, etc.). Good Luck :)

***Same goes for the CPU Package:***

```
Package C-State Summary: Residency (Percentage and Time)
C-State, CPU/Package_0 Residency (%), CPU/Package_0 Residency (msec)
-------, ---------------------------, ------------------------------
PC0    , 5.59                       , 7564.95                       
PC2    , 6.80                       , 9198.01                       
PC3    , 0.44                       , 590.81                        
PC6    , 0.17                       , 233.36                        
PC7    , 0.06                       , 76.72                         
PC8    , 0.90                       , 1212.08                       
PC9    , 3.64                       , 4922.83                       
PC10   , 82.40                      , 111452.62                     
```

Since this was a short session (total: 135s, out of which system was sleeping some ~111s), you see 82.4% time spent in the C10 state. We want this to be 99% or close to it if we are talking about long sleep intervals. On this system, after the patch, it is sure to happen.

It will probably take some time to get here. SoC Watch is indispensable when debugging issues; its logs contain details on which processes are "noisy", which devices failed to be power gated, etc. I recommend running it after installing your applications (next step) to ensure that one does not slip in crappy software, which will ruin the power efficiency.

While SoC Watch is very powerful, there is an even more powerful tool using the "NDA" version of Soc Watch. NDA requirement remained possibly because many more internal states of the PCH and CPU are logged, and some might reveal the CPU's inner workings and capabilities of the unreleased products. But the good news is that it is doubtful you need that level of detail, and SoC Watch is already excellent even in the "Public" version. For people interested, Microsoft is mentioning the NDA tool on page 32 of the presentation here: https://f.ch9.ms/public/WinHEC/06_WinHECDec2016-DesigningPowerEfficient_v02.pptx


## Post Patching (OS)

- After the patch is working, install `ThrottleStop`
- Before tweaking CPU voltages, ensure that no applications are taxing the CPU. You can use Soc Watch to determine which processes and drivers are waking up the CPU, blasting DPCs like there is no tomorrow, or devices just being rude and flooding the system with countless interrupts...
- I didn't mention possibly the worst offenders of all: processes that brazenly force Windows timer precision to 1 ms and completely ruining any power efficiency in the process (see: https://randomascii.wordpress.com/2013/07/08/windows-timer-resolution-megawatts-wasted/). Suppose you cannot live without those applications. In that case, you might want to consider a semi-radical solution: install a global hook to winmm.dll (like: https://github.com/rustyx/nobuzz), preventing these applications from succeeding in changing timer resolution. Then, check for obvious defects; you might be OK.
- Same goes for other things: trashing CPU, context switches, page faults, etc...

The simple rule is: avoid installing unnecessary software and regularly check for hogs, auto-staring bloat, etc. All of this will help the CPU reaching C7 (cores) and C10 (package) and the rest of the system power gate anything unused. It is hours of battery life we are talking about.

## Example Results:

This is the behavior of Dell 5750 system after applying the recipe. Now it passes all checkpoints for S0iX standby, including CPU >and< PCH. Most of the peripherals are in D-states, except the ones that cannot be (e.g. CPU). Furthermore, temps are considerably down, and #PROCHOT is very rarely seen (in this case, CPU core voltage is changed by: -0.125v)

**SoC Watch visualization of 130s trace with ~110s in S0 Standby**

The dead giveaway is PCH asserting SLP-S0 - Anybody who dealt with this knows the number of constraints that need to happen before PCH finally dozes off. We can see this (partially) on the screenshot: almost all devices must go into sleep before PCH can assert SLP-S0. Every violation translates into extra hundreds of mW, sometimes more, to the horror of your battery and you the following day.

![Alt text](/Demo/SocWatch_60sec_Timeline_Annotated.png?raw=true)

**ThrottleStop showing a nice picture**

While not in standby, the system is also drawing a meager amount of power. We can see that the CPU consumes down to 0.5 W of power, mainly thanks to aggressive C-state promotion to C7 (CPU cores) and C10 (CPU Package). If the system is not appropriately configured, the CPU is also often disrupted by other peripherals bombarding the CPU with interrupts or, sadly, crappy software being crappy software.

![Alt text](/Demo/ThrottleStop_CST_WhileIdle.png?raw=true)

**At the end of the day, battery sensors do not lie :-)**

Finally, getting everything in order also means reaching advertised battery life, or... exceeding it a bit:

![Alt text](/Demo/PoweDrain_Idle.jpg?raw=true)

And before you compare this with your latest and greatest thinner-than-razor Tiger Lake Ultrabook, please bear in mind that this is a mobile workstation we are talking about! This one, in particular, has an eight-core 5.1 GHz Intel Comet Lake CPU, NVIDIA RTX 3000 Quadro GPU, 64 GB of RAM, 2 SSDs, and a power-hungry 4K UHD display. Therefore, you must adjust expectations somewhat.

(*) Not Tested, but systems are very similar. 
