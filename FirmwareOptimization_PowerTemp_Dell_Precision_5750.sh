#!/bin/sh

############################################################################
#                                                                          #
#       "Make Dell Precision 5750 (and, possibly, 2020 XPS 17) Cool"       #
#               Firmware Power and Temperature Optimizations               #
#                          (TL:DR - POKE Fest)                             #
#                                                                          #
# WARNING: FOR EXPERTS IN THE ART ONLY, PROVIDED STRICTLY AS GUIDANCE ON   #
# ACHIEVING LOW POWER, LOW TEMPERATURES AND FULL (HW) S0iX STANDBY         #
#                                                                          #
# IT IS NOT TO BE USED 'AS IS' (*** PLEASE READ ALL NOTICES BELOW! ***)    #
#                                                                          #
# STEPS PERFORMED BELOW COULD "BRICK" THE SYSTEM AND RENDER IT INOPERABLE  #
# PROCEED AT YOUR OWN RISK! PROPER TOOLING+BACKUPS ARE HIGHLY RECOMMENDED  #
# (flash programmer for emergency, firmware backup, service manuals)       #
#                                                                          #
# All copyrights, trademarks and brands are a property of their respective #
# owners. All company, product and service names used are for              #
# identification purposes only. Use of these names and brands does not     #
# imply endorsement.                                                       #
#                                                                          #
# Licensed under MIT license (text below)                                  #
#--------------------------------------------------------------------------#
# Copyright (C) 2021 Ivan Dimkovic.                                        #
#                                                                          #
# Permission is hereby granted, free of charge, to any person obtaining a  #
# copy of this software and associated documentation files (the "Software")#
# , to deal in the Software without restriction, including without         #
# limitation the rights to use, copy, modify, merge, publish, distribute,  #
# sublicense, and/or sell copies of the Software, and to permit persons to #
# whom the Software is furnished to do so, subject to the following        #
# conditions:                                                              #
#                                                                          #
# The above copyright notice and this permission notice shall be included  #
# in all copies or substantial portions of the Software.                   #
#                                                                          #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,          #
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF       #
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.   #
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY     #
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,     #
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        #
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                   #
#                                                                          #
############################################################################

# You need modified GRUB2 EFI binary to use this script, e.g. like this:
# https://github.com/XDleader555/grub_setup_var
#

#
# *** THESE AREN'T UEFI VARIABLES YOU ARE LOOKING FOR! ***
#
# Every system is different. What you see below are UEFI variables for MY
# Dell Precision 5750, with Intel Core i7-10750h CPU, NVIDIA RTX 3000 GPU,
# two KIOXIA (Ex-Toshiba) KXG60ZNV1T02 drives, UEFI FW v1.7.2, etc.
#
# Your system might have slightly or very different variables, depending
# on many factors. They >might< be the same, but as the risk is bricking
# of the system, please take the time and review every single setting.
#
# Please extract the UEFI IFR from your firmware's Setup EFI binary and
# Convert it to readable form (if need be) and go through EVERY setting
# Also please do not forget to read the notes in the settings below.
#
# Both VarStores >and< Setting Values / Ranges MUST match. If your system
# has different location of a variable, this is not a problem as long as
# the variable name, meaning and range is the same (assuming we are talking
# about the same or similar >platform<). Here, you will just need to change
# the location of the variable, for example:
#
#         FROM:    setup_var PchSetup 0x123 0x45
#         TO:      setup_var PchSetup 0x678 0x9A
#
# If your system does not have the given setting, then it is likely that
# your firmware cannot deal with it at all. Experts can analyze the
# actual platform reference code and, at best, retrofit the change but
# this is well beyond the scope of this script.
#
# If the system has the given setting, but different ranges/values - STOP!
# Please review the relevant documentation from the platform vendor before
# deciding what to do (expert mode). Not an expert? Please DO NOT change
# the values without understanding the theory of operation and allowed
# ranges and implications for your platform! And, have the hardware flash
# programmer and good Firmware backup ready at all times.
#
# Happy hacking :-)

#
# Last Failsafe for non-experts and against accidental runs

echo "Please confirm that you have reviewed and approved every setting in this script."
echo "Programming incorrect firmware NVRAM variables can result in errors"
echo "in operation, unbootable OS or, at worst, whole computer not powering up"
echo "and requiring hardware repair or motherboard replacement."
echo "Proceed with caution and on your risk!!!"

while true; do
  read -p "Continue (Yes / No)?" yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) return;;
      * ) echo "Please answer yes or no.";;
  esac
done

###################################################################################
#                                                                                 #
#                         Device Configuration (STEP 1)                           #
#                                                                                 #
# Goal 1: Reduce idle power by enforcing aggressive power management policy       #
#                                                                                 #
#         - Everything that can, must go to sleep, lowest state if possible       #
#         - Ensure devices get powered down when unused                           #
#         - Ensure Firmware does not get Windows to disable ASPM                  #
#                                                                                 #
# Goal 2: Increase chance that system gets to "HW" (Dis)Connected Standby         #
#                                                                                 #
#         I say "Increase chance" because on top of tens of conditions for the    #
#         hardware and software itself, one must also wait for good aligment of   #
#         planets and avoid wrath of gods - any of these will ruin your chances   #
#         of seeing that everything went to sleep nicely in the SoC Watch trace   #
#         (including PCH SLP_S0 of course)                                        #
#                                                                                 #
#  ... but we can try! Some say it can be done, even!                             #
#                                                                                 #
###################################################################################


########
# ACPI #
########

setup_var Setup 0x14  0x00          # ACPI Debug: Disabled

setup_var Setup 0x0D  0x00          # ACPI Auto Configuration
                                    # Leave it like this for a clean FACP table
                                    # Otherwise, FACP will contain data which
                                    # will force Windows to disable ASPM

setup_var Setup 0x11  0x01          # Native PCIe: Enabled
setup_var Setup 0x12  0x02          # Native ASPM: Auto

setup_var Setup 0x20  0x01          # Low Power S0 Idle Capability: Enabled
setup_var Setup 0x38  0x01          # Enable Sensor Standby: Enabled
setup_var Setup 0x44  0x01          # Enable MSI

setup_var Setup 0x443 0x01          # Configure ACPI objects for wireless devices: Enabled
setup_var Setup 0x426 0x01          # ACPI D3Cold (RTD3) Support: Enabled

#
# Now, we will tell firmware that we are very happy with "Runtime D3" states
# (lowest power one can get while in idle, crappy hardware notwithstanding)

setup_var Setup 0x428 0x02          # USB Port 1 RTD3 Support: Super Speed
setup_var Setup 0x429 0x02          # USB Port 2 RTD3 Support: Super Speed

setup_var Setup 0x437 0x03          # Enable RTD3 Support for WWAN: Enabled
setup_var Setup 0x684 0x01          # Enable RTD3 Support for BT: Enabled
setup_var Setup 0x687 0x01          # Enable RTD3 Support for DG1: Enabled
setup_var Setup 0x438 0x01          # Enable RTD3 Support for Sata Port 0: Enabled
setup_var Setup 0x439 0x01          # Enable RTD3 Support for Sata Port 1: Enabled
setup_var Setup 0x43A 0x01          # Enable RTD3 Support for Sata Port 2: Enabled
setup_var Setup 0x43B 0x01          # Enable RTD3 Support for Sata Port 3: Enabled
setup_var Setup 0x43C 0x01          # Enable RTD3 Support for Sata Port 4: Enabled
setup_var Setup 0x43D 0x01          # Enable RTD3 Support for Sata Port 5: Enabled

#
# Misc

setup_var SaSetup 0x130  0x00      # ECC DRAM Support: Disabled
                                   # NOTE: Obviously you do not want this if you
                                   # ordered Inspirion 5750 with Xeon-W SKUs
                                   # and with ECC RAM.

setup_var SaSetup 0xFF   0x00      # Disable IED (Intel Enhanced Debug)
setup_var SaSetup 0x48   0x01      # iGFX PM Support: Enable
setup_var SaSetup 0x12D  0x02      # Keep iGFX enabled based on setup options: Auto

########################################
# Buses - Ensure ASPM and power gating #
########################################

#
# DMI

setup_var SaSetup 0x101   0x00      # DMI Max Link Speed: Auto
setup_var SaSetup 0x123   0x03      # DMI ASPM: L0sL1

######################
# PCIe Configuration #
######################

#
# PEG
# (coming out of the SoC)

#
# PEG0 Port

setup_var SaSetup 0x5D    0x02      # Enable: Auto
setup_var SaSetup 0x61    0x00      # Max Link Speed: Auto
setup_var SaSetup 0x69    0x01      # Power Down Unused Lanes: Auto

setup_var SaSetup 0x55    0x03      # ASPM: L0sL1
setup_var SaSetup 0x59    0x03      # Enable L0s: Booth Root and Endpoint Ports
setup_var SaSetup 0xD0    0x00      # PEG0 Hot Plug: Disable

#
# PEG1 Port

setup_var SaSetup 0x5E    0x02       # Enable: Auto
setup_var SaSetup 0x62    0x00       # Max Link Speed: Auto
setup_var SaSetup 0x69    0x01       # Power Down Unused Lanes: Auto

setup_var SaSetup 0x55    0x03       # ASPM: L0sL1
setup_var SaSetup 0x5A    0x03       # Enable ASPM L0s: Booth Root and Endpoint Ports
setup_var SaSetup 0xD1    0x00       # PEG1 Hot Plug: Disable

#
# PEG2 Port

setup_var SaSetup 0x5F    0x02       # Enable: Auto
setup_var SaSetup 0x63    0x00       # Max Link Speed: Auto
setup_var SaSetup 0x6B    0x01       # Power Down Unused Lanes: Auto

setup_var SaSetup 0x57    0x03       # ASPM: L0sL1
setup_var SaSetup 0x5B    0x03       # Enable ASPM L0s: Booth Root and Endpoint Ports
setup_var SaSetup 0xD2    0x00       # PEG2 Hot Plug: Disable

#
# PEG3 Port

setup_var SaSetup 0x60    0x02       # Enable: Auto
setup_var SaSetup 0x64    0x00       # Max Link Speed: Auto
setup_var SaSetup 0x6C    0x01       # Power Down Unused Lanes: Auto

setup_var SaSetup 0x58    0x03       # ASPM: L0sL1
setup_var SaSetup 0x5C    0x03       # Enable ASPM L0s: Booth Root and Endpoint Ports
setup_var SaSetup 0xD3    0x00       # PEG3 Hot Plug: Disable


#
# PCH PCIe
# (Coming out of I/O Hub)

setup_var PchSetup 0xD0   0x00       # PCI Express Clock Gating Enable/Disable Per Port: Enabled (0)
setup_var PchSetup 0x4F6  0x03       # DMI Link ASPM Control: L0sL1
setup_var PchSetup 0x3C6  0x01       # PCIe Function Swap: Enable

# PCIe Port 1
setup_var PchSetup 0x10E  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x276  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x216  0x00       # Hot Plug: Disable
setup_var PchSetup 0x246  0x00       # Speed: Auto
setup_var PchSetup 0x25E  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 2
setup_var PchSetup 0x10F  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x277  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x217  0x00       # Hot Plug: Disable
setup_var PchSetup 0x247  0x00       # Speed: Auto
setup_var PchSetup 0x25F  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 3
setup_var PchSetup 0x110  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x278  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x218  0x00       # Hot Plug: Disable
setup_var PchSetup 0x248  0x00       # Speed: Auto
setup_var PchSetup 0x260  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 4
setup_var PchSetup 0x111  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x279  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x219  0x00       # Hot Plug: Disable
setup_var PchSetup 0x249  0x00       # Speed: Auto
setup_var PchSetup 0x261  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 5
setup_var PchSetup 0x112  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27A  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21A  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24A  0x00       # Speed: Auto
setup_var PchSetup 0x262  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 6
setup_var PchSetup 0x113  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27B  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21B  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24B  0x00       # Speed: Auto
setup_var PchSetup 0x263  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 7
setup_var PchSetup 0x114  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27C  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21C  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24C  0x00       # Speed: Auto
setup_var PchSetup 0x264  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 8
setup_var PchSetup 0x115  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27D  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21D  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24D  0x00       # Speed: Auto
setup_var PchSetup 0x265  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 9
setup_var PchSetup 0x116  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27E  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21E  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24E  0x00       # Speed: Auto
setup_var PchSetup 0x266  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 10
setup_var PchSetup 0x117  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x27F  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x21F  0x00       # Hot Plug: Disable
setup_var PchSetup 0x24F  0x00       # Speed: Auto
setup_var PchSetup 0x267  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 11
setup_var PchSetup 0x118  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x280  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x220  0x00       # Hot Plug: Disable
setup_var PchSetup 0x250  0x00       # Speed: Auto
setup_var PchSetup 0x268  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 12
setup_var PchSetup 0x119  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x281  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x221  0x00       # Hot Plug: Disable
setup_var PchSetup 0x251  0x00       # Speed: Auto
setup_var PchSetup 0x269  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 13
setup_var PchSetup 0x11A  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x282  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x222  0x00       # Hot Plug: Disable
setup_var PchSetup 0x252  0x00       # Speed: Auto
setup_var PchSetup 0x26A  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 14
setup_var PchSetup 0x11B  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x283  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x223  0x00       # Hot Plug: Disable
setup_var PchSetup 0x253  0x00       # Speed: Auto
setup_var PchSetup 0x26B  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 15
setup_var PchSetup 0x11C  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x284  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x224  0x00       # Hot Plug: Disable
setup_var PchSetup 0x254  0x00       # Speed: Auto
setup_var PchSetup 0x26C  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 16
setup_var PchSetup 0x11D  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x285  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x225  0x00       # Hot Plug: Disable
setup_var PchSetup 0x255  0x00       # Speed: Auto
setup_var PchSetup 0x26D  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 17
setup_var PchSetup 0x11E  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x286  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x226  0x00       # Hot Plug: Disable
setup_var PchSetup 0x256  0x00       # Speed: Auto
setup_var PchSetup 0x26E  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 18
setup_var PchSetup 0x11F  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x287  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x227  0x00       # Hot Plug: Disable
setup_var PchSetup 0x257  0x00       # Speed: Auto
setup_var PchSetup 0x26F  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 19
setup_var PchSetup 0x120  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x288  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x228  0x00       # Hot Plug: Disable
setup_var PchSetup 0x258  0x00       # Speed: Auto
setup_var PchSetup 0x270  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 20
setup_var PchSetup 0x121  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x289  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x229  0x00       # Hot Plug: Disable
setup_var PchSetup 0x259  0x00       # Speed: Auto
setup_var PchSetup 0x271  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 21
setup_var PchSetup 0x122  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x28A  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x22A  0x00       # Hot Plug: Disable
setup_var PchSetup 0x25A  0x00       # Speed: Auto
setup_var PchSetup 0x272  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 22
setup_var PchSetup 0x123  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x28B  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x22B  0x00       # Hot Plug: Disable
setup_var PchSetup 0x25B  0x00       # Speed: Auto
setup_var PchSetup 0x273  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 23
setup_var PchSetup 0x124  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x28C  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x22C  0x00       # Hot Plug: Disable
setup_var PchSetup 0x25C  0x00       # Speed: Auto
setup_var PchSetup 0x274  0x01       # Transmitter Half Swing: Enabled

# PCIe Port 24
setup_var PchSetup 0x125  0x03       # PCIe Port ASPM: Enable L0sL1 (WARNING: Dangerous! 0x04 - Auto, is safer!)
setup_var PchSetup 0x28D  0x02       # PCIe L1 Substrates settings: L1.1 & L1.2
setup_var PchSetup 0x22D  0x00       # Hot Plug: Disable
setup_var PchSetup 0x25D  0x00       # Speed: Auto
setup_var PchSetup 0x275  0x01       # Transmitter Half Swing: Enabled

##############################################
# Intel Smart Sound DSP: Wake on Voice (WoV) #
##############################################

#
# There is probably way more elegant solution for "OED" spam in Event Viewer
#
# And, I am not convinced it was the DSP that was responsible for the sleep drain
# but, indeed - it looks ugly in Windows Sleep Studies and Energy Reports so...
# I am simply going to disable "Wake on Voice" completely by old "axe" method
#
# Oh, and yes, you will have to part with your voice assistant while standby...

setup_var PchSetup 0x575    0x01      # Disable WoV (Wake on Voice)
setup_var PchSetup 0x57D    0x01      # Disable VAD (Voice Activity Detection)
setup_var PchSetup 0x586    0x00      # WoV DSP Firmware (Intel) - Disabled

# Oh noo!
# From now, there is no more "Hey (whatever)" while system is in S0iX! Sad. :)
#
# Alternative? Fix this properly, add adequate mitigation (if needed) for the DSP
# in PEP and also see why SST fills Windows Event log with infinite amounts of
# "OED - Event Id 19" messages. But, there are IHVs and OEMs for that.
#
# I am happy with "WoV-less Standby" (TM)

##################
# GT (Intel GPU) #
##################

setup_var CpuSetup 0x3E    0x01      # RC6 (Render Standby): Enabled

#################################
# PCH (Platform Controller Hub) #
#################################

setup_var PchSetup 0x04   0x04       # Deep Sx Power policy: S4-S5
                                     # "We'd like Deep Sx in both S4 and S5, thank you!"

setup_var PchSetup 0x0E   0x00       # PCIe Wireless BT or WLAN Wake: Disabled
setup_var PchSetup 0x0F   0x00       # PCIe Wireless BT or WLAN Wake in DeepSx: Disabled
                                     # NOTE: if you are using wake feature, you should change the value t0 0x01

setup_var PchSetup 0x10   0x01       # Allow CLKRUN# logic to stop the PCI clocks: Enabled
setup_var PchSetup 0x11   0x01       # PCH Energy Reporting: Enabled

setup_var PchSetup 0x14   0x01       # TCO Timer: Disable
setup_var PchSetup 0x23   0x00       # USB Port Disable Override: Disabled
setup_var PchSetup 0x6E5  0x01       # USB2 PHY Sus Well Power Gating: Enabled
setup_var PchSetup 0x6E6  0x01       # 8254CGE Clock Cate In Early Phase: Enabled

######################
# SATA Configuration #
######################

#
# NOTE: It appears one cannot disable SATA controller completely
# Doing so also "hides" the NVMe Drives. Now, this might be caused by the
# fact that I have two NVMe SSDs ni RAID0 configuration, requiring Intel RST
# And >maybe< RST does not work if it detects no SATA controllers, I do not know.
#
# So, I have re-enabled the SATA controller. You can try to disable it if
# your configuration is different than mine. Physically, there are no SATA drives.
# Please make sure you have ready bootable USB device to get back your NVMe drives
#
# Nevertheless, I will configure Aggresive LPM, DEVSLP, etc. for all ports
# just so it is visible how is it done.
#
# NOTE ON DEVSLP AND LPM:
#
# Not all SSDs are happy with very aggressive power management. Some might just
# refuse to go wake from low-power state, making your drive dissapear until next
# reboot (considered harmful). If you have such issues, then you might want to
# check out what can be done. Worst case you can always make PM less aggressive.

setup_var PchSetup 0x43  0x01        # SATA Controller: Enabled (see notice above)
setup_var PchSetup 0x8E  0x01        # Aggressive LPM Support: Enabled

#
# Per-Port Config

# PCH SATA Port 0
setup_var PchSetup 0x46  0x00        # Port State: Disabled
setup_var PchSetup 0x4E  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x66  0x00        # Port is External: No
setup_var PchSetup 0x90  0x01        # DevSlp: Enabled

# PCH SATA Port 1
setup_var PchSetup 0x47  0x00        # Port State: Disabled
setup_var PchSetup 0x4F  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x67  0x00        # Port is External: No
setup_var PchSetup 0x91  0x01        # DevSlp: Enabled

# PCH SATA Port 2
setup_var PchSetup 0x48  0x00        # Port State: Disabled
setup_var PchSetup 0x50  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x68  0x00        # Port is External: No
setup_var PchSetup 0x92  0x01        # DevSlp: Enabled

# PCH SATA Port 3
setup_var PchSetup 0x49  0x00        # Port State: Disabled
setup_var PchSetup 0x51  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x69  0x00        # Port is External: No
setup_var PchSetup 0x93  0x01        # DevSlp: Enabled

# PCH SATA Port 4
setup_var PchSetup 0x4A  0x00        # Port State: Disabled
setup_var PchSetup 0x52  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x6A  0x00        # Port is External: No
setup_var PchSetup 0x94  0x01        # DevSlp: Enabled

# PCH SATA Port 5
setup_var PchSetup 0x4B  0x00        # Port State: Disabled
setup_var PchSetup 0x53  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x6B  0x00        # Port is External: No
setup_var PchSetup 0x95  0x01        # DevSlp: Enabled

# PCH SATA Port 6
setup_var PchSetup 0x4C  0x00        # Port State: Disabled
setup_var PchSetup 0x54  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x6C  0x00        # Port is External: No
setup_var PchSetup 0x96  0x01        # DevSlp: Enabled

# PCH SATA Port 7
setup_var PchSetup 0x4D  0x00        # Port State: Disabled
setup_var PchSetup 0x55  0x00        # Hot Plug: Disabled
setup_var PchSetup 0x6D  0x00        # Port is External: No
setup_var PchSetup 0x97  0x01        # DevSlp: Enabled

# CPU Attached Storage (i.e. - PCIe)
setup_var PchSetup 0x8C  0x01        # Enabled


###################################################################################
#                                                                                 #
#           Power and Temperature Optimization Configuration (STEP 2)             #
#                                                                                 #
# Goal 1:  Properly unlock and configure firmware so that it can be managed       #
#          by e.g. ThrottleStop or equivalent Linux tool for overclocking and     #
#          undervolting.                                                          #
#                                                                                 #
#          NOTE: Undervolting was locked due to 0-Day vulnerability of SGX        #
#          if you do happen to rely on SGX, please asses your risks and gains of  #
#          re-enabling undervolting.                                              #
#                                                                                 #
# Goal 2:  (NOT DONE) Configure the voltages and clocks of the CPU and GPU        #
#          for the most efficient and cool operation. This can be done, and       #
#          all one has to do is extra lines to program adaptive ratios, voltages  #
#          etc. But doing so is much more dangerous than doing it in tools like   #
#          ThrottleStop, because it might make the system unbootable. The big     #
#          advantage of this approach is that one can re-lock the BIOS, avoiding  #
#          it being open for modification during runtime. Also, settings are      #
#          applied at system boot, and need no 3rd party software for control     #
#                                                                                 #
###################################################################################


#####################################
# Overheating and Performance Fixes #
#####################################

#
# Remove firmware locks necessary for optimizing CPU power and temperature
# NOTE: this leaves your system CPU configuration registers opened so any process
# with right privileges and access could modify them. Consider locking

setup_var PchSetup 0x17 0x00        # BIOS Lock: Disabled
setup_var CpuSetup 0x3E 0x00        # CFG Lock: Disabled
setup_var CpuSetup 0xDA 0x00        # Overclocking Lock: Disabled
#setup_var CpuSetup 0xDE 0x00       # CPU Run Control Lock: Disabled

setup_var CpuSetup 0x138 0x00       # SA VR TDC Lock: Disabled
setup_var CpuSetup 0x183 0x00       # Core/IA TDC Lock: Disabled
setup_var CpuSetup 0x186 0x00       # GT VR TDC Lock: Disabled

setup_var CpuSetup 0x2B 0x00        # Package Power MSR Lock: Disabled
setup_var CpuSetup 0x2A 0x00        # Power Limit 4 MSR 601h Lock: Disabled

#
# Configure CPU and PCH features we need

setup_var CpuSetup 0x1B7 0x01       # OverClocking Feature: Enabled
setup_var CpuSetup 0x1B8 0x01       # Enable XTU Interface: Enabled

setup_var CpuSetup 0x11  0x01       # Turbo Mode: Enabled (usually this is already enabled in FW)

setup_var CpuSetup 0x0E  0x02       # Boot Performance Mode: Max Turbo Performance
                                    # NOTE: you might want to drop to 1 = non-turbo, if you are spending too much time in firmware setup

setup_var CpuSetup 0x0A  0x01       # Race To Halt (RTH): Enabled
setup_var CpuSetup 0x0B  0x01       # Intel SpeedShift: Enabled

setup_var CpuSetup 0x1AF 0x01       # Energy Efficiency Turbo: Enabled
setup_var CpuSetup 0x1DA 0x01       # Voltage Optimization: Enabled


setup_var CpuSetup 0x24D 0x00       # Dual Tau Boost: Disabled
                                    # NOTE: If enabled, CPU will boost more in PL1, but less in PL2
                                    # If your CPU workloads bring the thermals to the limit, you might want to do a benchmark
                                    # with Dual Tau Boost enabled. In fact, for a very warm notebook this might make it faster.

setup_var CpuSetup 0x0C  0x00       # Intel Turbo Boost Max 3.0: Disabled
                                    # NOTE: TBM3.0 is mutually exclusive with other optimizations so it is disabled

setup_var CpuSetup 0x45  0x01       # HDC: Enable

setup_var CpuSetup 0x0F  0x01       # C-States: Enabled (usually this is already enabled in FW)
setup_var CpuSetup 0x10  0x01       # C1E: Enabled

setup_var CpuSetup 0x39  0x03       # Configure C-State Auto Demotion: C1 and C3
setup_var CpuSetup 0x3A  0x03       # Configure C-State Un-Demotion: C1 and C3

setup_var CpuSetup 0x46  0x08       # Package C State Limit: C10

setup_var CpuSetup 0x3B  0x01       # Configure Package C-State Demotion: Disable (this is not a typo)
setup_var CpuSetup 0x3C  0x01       # Configure Package C-State Un-Demotion: Disable (this is not a typo)

setup_var Setup 0x4D6    0x01       # ICC Watchdog: Enabled
setup_var PchSetup 0x20  0x01       # WDT Enable: Enabled
                                    # (in case system freezes up because of voltage / freq mod, it reboots)

