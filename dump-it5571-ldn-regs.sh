#!/bin/bash

# Dump the ITE IT5571 configuration register space by Logical Device Number (LDN)
# The dumped values are configuration data only. There is no real-time sensor
# data here. These are mostly registers containing bit fields of various EC chip
# settings and, in some cases, register and bus addresses needed to access other
# chip features that may be of interest. You may see some changes from one boot
# to another but once booted the values set generally do not change.
#
# Written specifically for the Intel NUC 12 Extreme (NUC12DCMi9) Compute
# Element motherboard with Intel 12th gen Alder Lake Core i9 12900 CPU and
# z960 PHC. It may work on other motherboards using the IT5571 EC with
# minimal tweaks.
#
# This script must be executed as root.
#
# Requires: iotools, isadump (from lm_sensors)
# dnf install iotools, lm_sensors
#
# If you have trouble reading/rwriting to any of these addresses you may need
# to set iomem=relaxed. Fastest way to run this command and reboot:
# grubby --args="iomem=relaxed" --update-kernel=ALL
#
# Copyright (C) 2026 Steve Rainwater
# Licesed under the Apache License 2.0
#

# LDN addresses and names from ITE IT5571 docs
declare -A ldn
ldn["0x01"]="UART 1 - Serial Port 1"
ldn["0x02"]="UART 2 - Serial Port 2"
ldn["0x04"]="SWUC - System Wake Up Control"
ldn["0x05"]="KBC/Mouse Interface"
ldn["0x06"]="KBC/Keyboard Interface"
ldn["0x0a"]="CIR - Customer IR"
ldn["0x0f"]="SMFI - Shared Memory Flash Interface"
ldn["0x10"]="RTCT - RTC-like Timer"
ldn["0x11"]="PMC1 - Power Management I/F Channel 1"
ldn["0x12"]="PMC2 - Power Management I/F Channel 2"
ldn["0x13"]="SSPI - Serial Peripheral Interface"
ldn["0x14"]="PECI - Platform Environment Control Interface"
ldn["0x17"]="PMC3 - Power Management I/F Channel 3"
ldn["0x18"]="PMC4 - Power Management I/F Channel 4"
ldn["0x19"]="PMC5 - Power Management I/F Channel 5"

readarray -t ldns < <(printf '%s\n' "${!ldn[@]}" | sort -n)

# WARNING: to access the LDN data, the IT5571 must be put into configuration
# mode. This should be harmless since this script only reads, it does not
# write to any config registers. But keep an eye on thermal data and if it
# looks like anything has gone wrong, a reboot will reset the IT5571.

# Put IT5571 into configuration mode (it will continue operating normally
# but will make the config register accessible).
echo "=== Setting IT5571 Configuration Mode"
iotools io_write8 0x4e 0x87
iotools io_write8 0x4e 0x01
iotools io_write8 0x4e 0x55
iotools io_write8 0x4e 0x55

# Loop through each logical device and dump its configuration map
for i in "${!ldns[@]}"; do
    addr=${ldns[$i]}
    name=${ldn[${ldns[$i]}]}
    echo ""
    echo "=========================================================="
    echo "  LDN $addr $name"
    echo "=========================================================="

    # Set the  LDN (register 0x07 is the selector)
    iotools io_write8 0x4e 0x07
    iotools io_write8 0x4f "$addr"

    # Dump the 256-byte configuration space for this LDN
    # -y suppresses the interactive confirmation prompt
    isadump -y 0x4e 0x4f
done

# Take IT5571 out of configuration mode
echo ""
echo "=== Setting IT5571 normal operation mode"
iotools io_write8 0x4e 0x02
iotools io_write8 0x4f 0x02
