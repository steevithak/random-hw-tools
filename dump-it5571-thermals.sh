#!/bin/bash

# dump-it5571-thermals.sh
#
# Compares the SMFI SRAM contents from an ITE IT5571 Embedded Controller chip
# before and after stressing CPUs to heat up the motherboard. Then it outputs
# a list of SRAM registers that changed. These are likely to be related to
# thermal controls - fan PWM, fan RPM sensors, or temperature sensors, etc.
#
# Written specifically for the Intel NUC 12 Extreme (NUC12DCMi9) Compute
# Element motherboard with Intel 12th gen Alder Lake Core i9 12900 CPU and
# z960 PHC. It may work on other motherboards using the IT5571 EC with
# minimal tweaks.
#
# This script must be executed as root.
#
# Requires: stress, iotools
# dnf install stress iotools
#
# If you have trouble reading/rwriting to any of these addresses you may need
# to set iomem=relaxed. Fastest way to run this command and reboot:
# grubby --args="iomem=relaxed" --update-kernel=ALL
#
# Copyright (C) 2026 Steve Rainwater
# Licesed under the Apache License 2.0
#

# ACPI Embedded Controller Channel 1 Data and Command Ports
readonly EC_DATA=0x62
readonly EC_CMD=0x66

# Command constant for reading
readonly EC_CMD_READ=0x80

# Wait for CMD Input port to be ready
wait_ibf_clear() {
    # Bit 1 (0x02) is Input Buffer Full
    while [ $(( $(iotools io_read8 $EC_CMD) & 2 )) -ne 0 ]; do
        sleep 0.001
    done
}

# Wait for Output data to be ready
wait_obf_set() {
    # Bit 0 (0x01) is Output Buffer Full
    while [ $(( $(iotools io_read8 $EC_CMD) & 1 )) -eq 0 ]; do
        sleep 0.001
    done
}

# Read one register
read_ec_register() {
    wait_ibf_clear

    # Send the Read command
    iotools io_write8 $EC_CMD $EC_CMD_READ

    wait_ibf_clear

    # Send the register address we want to read
    iotools io_write8 $EC_DATA $1

    wait_obf_set

    # Return decimal value of byte from the register
    printf "%d" "$(iotools io_read8 $EC_DATA)"
}

echo "======================================================="
echo " ITE IT5571 Thermal Test"
echo "======================================================="

# Snapshot registers between 0x10 and 0x80
echo "Taking baseline snapshot of full telemetry block (0x10 to 0x80)"
declare -A baseline
#for reg in {16..128}; do
for reg in {0..255}; do
    baseline[$reg]=$(read_ec_register $reg)
done

echo "Starting CPU core stress test (all cores)"
stress -c $(nproc) > /dev/null 2>&1 &
STRESS_PID=$!

echo "Waiting 10 seconds for thermal saturation"
sleep 10

echo "-------------------------------------------------------"
echo "Registers showing active positive thermal deltas"
echo "-------------------------------------------------------"

found_any=0
#for reg in {16..128}; do
for reg in {0..255}; do
    current_val=$(read_ec_register $reg)
    base_val=${baseline[$reg]}
    delta=$(( current_val - base_val ))

    # If a register value increases significantly, it may tracking CPU heat
    if (( delta >= 3 )) && (( current_val > 0 && current_val < 255 )); then
        hex=$(printf "0x%02X" $reg)
        printf "  Reg %s : Idle = %3d | Load = %3d | Delta = %+d\n" "$hex" "$base_val" "$current_val" "$delta"
        found_any=1
    fi
done

if [ $found_any -eq 0 ]; then
    echo "  No registers with positive deltas detected."
fi

kill $STRESS_PID
wait $STRESS_PID 2>/dev/null
echo "Stress test terminated. System returning to idle."
echo "-------------------------------------------------------"
