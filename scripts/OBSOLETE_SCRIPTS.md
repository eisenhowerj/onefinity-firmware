# Obsolete Build Scripts

The following scripts are deprecated and no longer used in the build process:

- **gplan-init-build.sh**: Used to set up QEMU/chroot environment for gplan builds
- **gplan-build.sh**: Used to build gplan inside QEMU/chroot
- **gplan-init-dev-img.sh**: Used to initialize development image for QEMU/chroot
- **rpi-chroot.sh**: Used to chroot into Raspberry Pi image with QEMU

These scripts were used when building gplan on x86_64 systems using QEMU emulation.
They have been replaced by **gplan-build-native.sh** which builds natively on ARM64 systems.

## Why were they deprecated?

The project now uses native ARM64 build runners (GitHub Actions self-hosted runners)
which make QEMU emulation unnecessary. Native builds are:

- Faster (no emulation overhead)
- More reliable (no emulation quirks)
- Simpler to maintain
- More representative of the target environment

## Current Build Process

For current build instructions, see:
- `docs/development.md` - Development and build instructions
- `scripts/gplan-build-native.sh` - Native ARM64 build script

## What if I need QEMU emulation?

If you need to build on x86_64 systems, the recommended approach is to:
1. Use CI/CD (GitHub Actions with ARM64 runners)
2. Use a native ARM64 development machine or cloud instance
3. Cross-compile (not currently supported but possible to add)

The old QEMU/chroot scripts are kept for historical reference but are not maintained.
