

# Random Hardware Tools

These are small scripts I've written to dump hardware data for projects I'm
working. They are only written for my own use but maybe you'll find them
useful for something too.

## Dump ITE IT5571 EC SMFI Data

Dumps the SMFI (Shared Memory Flash Interface) SRAM contents from an
ITE IT5571 Embedded Controller chip. Written specifically for the Intel
NUC 12 Extreme (NUC12DCMi9) Compute Element motherboard with Intel 12th
gen Alder Lake Core i9 12900 CPU and z960 PCH. It may work on other
motherboards using the IT5571 EC with minimal tweaks.

## Dump ITE IT5571 Suspected Thermal Data

Compares the SMFI SRAM contents from an ITE IT5571 Embedded Controller chip
before and after stressing CPUs to heat up the motherboard. Then it outputs
a list of SRAM registers that changed. These are likely to be related to
thermal controls - fan PWM, fan RPM sensors, or temperature sensors, etc.

## Dump ITE IT5571 Configuration Registers by LDN

Dump the ITE IT5571 configuration register space by Logical Device Number (LDN)
The dumped values are configuration data only. There is no real-time sensor
data here. These are mostly registers containing bit fields of various EC chip
settings and, in some cases, register and bus addresses needed to access other
chip features that may be of interest. You may see some changes from one boot
to another but once booted the values set generally do not change.

