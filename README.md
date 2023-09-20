# PiKVM OS Images for BliKVM hardware (WIP)

Currently, only for the PCIe v2 board, as that's the only BliKVM product I have.

Build instructions are mostly as written [in the PiKVM documentation](https://docs.pikvm.org/building_os/) with the following changes:

1. The build repo URL (obviously) is different, and needs to be changed to: https://github.com/Kreeblah/blikvm_pikvm_build
2. The `PLATFORM` option is the only one that really matters here, with `BOARD` being used to decorate the filename for the resulting image.  The makefile uses `PLATFORM` to look up what the equivalent base settings are for PiKVM, builds that image, and then modifies it accordingly.

The `PLATFORM` value for the PCIe V2 is `v2-pcie`.