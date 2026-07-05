#!/bin/bash

# dump-it5571-smfi.sh
#
# Dumps the SMFI (Shared Memory Flash Interface) SRAM contents from an
# ITE IT5571 Embedded Controller chip. Written specifically for the Intel
# NUC 12 Extreme (NUC12DCMi9) Compute Element motherboard with Intel 12th
# gen Alder Lake Core i9 12900 CPU and z960 PCH. It may work on other
# motherboards using the IT5571 EC with minimal tweaks.
#
# This script must be executed as root.
# Each register is dumped in hex, decimal, and ASCII.
#
# Requires: iotools
# dnf install iotools
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
    local target_reg=$1
    wait_ibf_clear

    # Send the Read command
    iotools io_write8 $EC_CMD $EC_CMD_READ

    wait_ibf_clear

    # Send the register address we want to read
    iotools io_write8 $EC_DATA $target_reg

    wait_obf_set

    # Read a byte from the register
    iotools io_read8 $EC_DATA
}


# Print a table header
echo "Dumping full EC space (0x00 to 0xFF)..."
echo "----------------------------------------------------------------------------------"
printf "%-18s | %-18s | %-18s | %-18s\n" "Col 0" "Col 1" "Col 2" "Col 3"
echo "----------------------------------------------------------------------------------"

# Dump the entire 0x00 - 0xff (0-255) SRAM block
for reg in {0..255}; do
    # Read the live register value (e.g., returns "0x4E")
    hex_val=$(read_ec_register $reg)
    hex_reg=$(printf "0x%02X" $reg)

    # Convert to based 10 for formatting and loop count
    val=$(printf "%d" "$hex_val")

    # Convert to ASCII character if in printable range
    if (( val >= 32 && val <= 126 )); then
        ascii_val=$(printf "\\$(printf '%03o' $val)")
    else
        ascii_val="."
    fi

    # Print a register string: Reg (hex) Value (hex dec ascii)
    cell_str=$(printf "%s: %s %3d, %s" "$hex_reg" "$hex_val" "$val" "$ascii_val")

    # Print the cell with uniform padding
    printf "%-18s " "$cell_str"

    # Line break every 4 registers
    if [ $(( (reg + 1) % 4 )) -eq 0 ]; then
        echo ""
    else
        printf "| "
    fi
done
echo "----------------------------------------------------------------------------------"

