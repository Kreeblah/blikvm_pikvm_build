# PiKVM OS Images for BliKVM hardware

**Although this tooling uses the official PiKVM and BliKVM sources, the images produced should be considered unofficial and not endorsed by either the PiKVM or BliKVM teams.**

This repo is a modification of the official PiKVM packaging system to generate builds for use with supported [BliKVM hardware](https://www.blicube.com).  It creates file layouts for the images and then applies the [BliKVM modifications](https://wiki.blicube.com/blikvm/en/modify_pikvm_image/) to the produced files, including the fan modifications, EDID modification, and `dtoverlay` option for 1080p support before generating the final image.  Everything not mentioned here that the BliKVM modification page discusses (such as HDMI audio) is currently offered in the base PiKVM repository by default.

**Currently, the only tested images are for the PCIe v2 board, as that's the only BliKVM product I have.**  From what I've been able to assess from the CM4 v1 and HAT v3 products, I think these images should work, but I don't know for sure.  I'm also not entirely certain what the differences are between them, as the BliKVM-provided images seem to be based on the same PiKVM image for all three systems.

Also, note that the Allwinner v4 is not currently compatible with PiKVM.  For that product, you need to use the [BliKVM software](https://github.com/ThomasVon2021/blikvm), as it uses a different SOC which doesn't have a PiKVM build available.

Build instructions are mostly as written [in the PiKVM documentation](https://docs.pikvm.org/building_os/) with the following changes:

1. The build repo URL for the Git checkout in step 2 is (obviously) different, and needs to be changed to: https://github.com/Kreeblah/blikvm_pikvm_build
2. The `PLATFORM`, `BOARD`, and `SUFFIX` variables are determined by the Makefile based on the new, required `BLIKVM_PLATFORM` variable, which can either be specified in `config.mk` or passed as a key-value pair to the `make` command (e.g. `make os BLIKVM_PLATFORM=v2-pcie && make image BLIKVM_PLATFORM=v2-pcie` will generate a `.xz` file with a compressed image for a PCIe v2 board, assuming all goeas correctly).
3. Depending on where you live, you may want to modify the Makefile to point to a closer Arch Linux mirror.  Available mirrors are listed at https://archlinuxarm.org/about/mirrors

The `BLIKVM_PLATFORM` values for the various products are as follows:

| Product | `BLIKVM_PLATFORM` value |
| ------- | ----------------------- |
| CM4 v1  | `v1-cm4`                |
| PCIe v2 | `v2-pcie`               |
| HAT v3  | `v3-hat`                |