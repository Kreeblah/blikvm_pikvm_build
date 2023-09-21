# PiKVM OS Images for BliKVM hardware

**Although this tooling uses the official PiKVM and BliKVM sources, the images produced should be considered unofficial and not endorsed by either the PiKVM or BliKVM teams.**

This repo is a modification of the official PiKVM packaging system to generate builds for use with supported [BliKVM hardware](https://www.blicube.com).  It creates file layouts for the images and then applies the [BliKVM modifications](https://wiki.blicube.com/blikvm/en/modify_pikvm_image/) to the produced files, including the fan modifications, EDID modification, and `dtoverlay` option for 1080p support before generating the final image.  Everything not mentioned here that the BliKVM modification page discusses (such as HDMI audio) is currently offered in the base PiKVM repository by default.

Currently, this only builds images for the PCIe v2 board, as that's the only BliKVM product I have.

Build instructions are mostly as written [in the PiKVM documentation](https://docs.pikvm.org/building_os/) with the following changes:

1. The build repo URL for the Git checkout in step 2 is (obviously) different, and needs to be changed to: https://github.com/Kreeblah/blikvm_pikvm_build
2. The `PLATFORM`, `BOARD`, and `SUFFIX` variables are determined by the Makefile based on the new, required `BLIKVM_PLATFORM` variable, which can either be specified in `config.mk` or passed as a key-value pair to the `make` command (e.g. `make os BLIKVM_PLATFORM=v2-pcie`).
3. Depending on where you live, you may want to modify the Makefile to point to a closer Arch Linux mirror.  Available mirrors are listed at https://archlinuxarm.org/about/mirrors

The `BLIKVM_PLATFORM` value for the PCIe V2 is `v2-pcie`.