# PiKVM OS Images for BliKVM hardware

This repo is a modification of the official PiKVM packaging system to generate builds for use with supported [BliKVM hardware](https://www.blicube.com).  It creates file layouts for the images and then applies the [BliKVM modifications](https://wiki.blicube.com/blikvm/en/modify_pikvm_image/) to the produced files, including the fan modifications, EDID modification, and `dtoverlay` option for 1080p support before generating the final image.  Everything not mentioned here that the BliKVM modification page discusses (such as HDMI audio) is currently offered in the base PiKVM repository by default.

Currently, this only builds images for the PCIe v2 board, as that's the only BliKVM product I have.

Build instructions are mostly as written [in the PiKVM documentation](https://docs.pikvm.org/building_os/) with the following changes:

1. The build repo URL for the Git checkout in step 2 is (obviously) different, and needs to be changed to: https://github.com/Kreeblah/blikvm_pikvm_build
2. The `PLATFORM` option is the only one that really matters here, with `BOARD` being used to decorate the filename for the resulting image.  The makefile uses `PLATFORM` to look up what the equivalent base settings are for PiKVM, builds that image, and then modifies it accordingly.

The `PLATFORM` value for the PCIe V2 is `v2-pcie`.