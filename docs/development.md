# OneFinity CNC Controller Development Guide

This document describes how to setup your environment for OneFinity CNC
controller development on Debian Linux. Development on systems other than
Debian Linux may work but is not officially supported.

## Build System Overview

The project now uses two build approaches:

1. **Local Development**: Traditional Makefile for quick iteration
2. **Production Builds**: GitHub Actions workflows for CI/CD and releases

For production builds (Debian packages and SD images), we use GitHub Actions
workflows with self-hosted ARM64 runners instead of x86 emulation.

## Installing the Development Prerequisites

The project requires Node.js 22.22.2 or later (CI currently uses Node.js 24)
and Python 3.11 or later. The Svelte UI uses Svelte 5 and Vite 7; Vitest is
used for the JavaScript test suite.

### For Local Development (Any Debian-based System)

On a Debian/Ubuntu Linux system, install the required packages:

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    gcc-avr \
    avr-libc \
    avrdude \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    curl

# Install Python development dependencies in a virtual environment
python3 -m venv --system-site-packages .venv
. .venv/bin/activate
python -m pip install 'setuptools<81'
python -m pip install -r requirements-dev.txt
```

Install a Node.js version meeting the requirement above, then verify it:

```bash
node --version
npm --version
```

On Debian Bookworm, the distribution's Node.js package may not meet the project
minimum; use a Node.js installation that does.

### For Building Debian Packages (ARM64 System)

If you want to build Debian packages locally (requires ARM64 system):

```bash
sudo apt-get install -y \
    debhelper \
    devscripts \
    dh-python
```

### For Building SD Card Images (ARM64 System)

If you want to build complete SD card images:

```bash
sudo apt-get install -y \
    wget \
    xz-utils \
    parted \
    kpartx
```

### For Building GPlan Module (ARM64 System)

If you want to build the gplan module locally:

```bash
sudo apt-get install -y \
    scons \
    build-essential \
    libssl-dev \
    python3-dev \
    git
```

## Getting the Source Code

```bash
git clone https://github.com/eisenhowerj/onefinity-firmware.git
cd onefinity-firmware
```

## Local Development Workflow

### Build the Frontend and Components

```bash
# Install Node dependencies
npm ci

# Build all components
make all
```

The root `npm ci` also installs the Svelte component dependencies. `make all`
will:

- Build the web frontend (JavaScript, Svelte components, CSS)
- Build AVR firmware
- Build other subprojects (boot, pwr, jig)
- Generate the HTTP files in `build/http/`

### Build Individual Components

```bash
# Build only AVR firmware
make -C src/avr

# Build only frontend
(cd src/svelte-components && npm run build)

# Check Svelte components
(cd src/svelte-components && npm run check)

# Build Python package
python3 setup.py build
```

## Testing

Run the project tests from the repository root:

```bash
python -m pytest
```

The GPIO tests require an available GPIO backend. On Raspberry Pi 5, install
`python3-lgpio` (`sudo apt-get install python3-lgpio`) before running them.
They access GPIO chip 4, so run them on a Pi 5; the development virtual
environment shares system packages so it can import the OS-provided GPIO
module.

The `npm test` command runs Vitest, but there are currently no JavaScript test
files in the repository.

To check and build the Svelte 5 UI independently:

```bash
cd src/svelte-components
npm run check
npm run build
```

## Build GPlan Module

GPlan is a Python module written in C++. It must be compiled for ARM64 so that
it can be used on the Raspberry Pi 5.

### On ARM64 Systems (Native Build)

The recommended approach is to build natively on an ARM64 system (such as the
Raspberry Pi 5 or ARM64 development machine):

    make gplan

Or use the build script directly:

    ./scripts/gplan-build-native.sh

This will:

- Clone the required dependencies (cbang and camotics)
- Build the gplan.so module natively
- Install it to `src/py/camotics/gplan.so`

The first time this is run, it will take some time as it downloads and compiles
the dependencies. Subsequent builds will be faster as they reuse the cached builds.

### On x86_64 Systems (Cross-compilation)

For x86_64 systems, cross-compilation is not currently supported in the native
build script. The recommended approach is to use CI/CD (GitHub Actions) which
runs on ARM64 runners, or build directly on an ARM64 machine.

**Note**: The legacy QEMU/chroot emulation approach has been deprecated and
removed. See `docs/emu_chroot.md` for historical reference only.

## Build Packages

### Legacy tar.bz2 Package (for backward compatibility)

```bash
make pkg
```

The resulting package will be a `.tar.bz2` file in `dist/`.

### Debian Package (Production Build)

**Note**: Debian package builds require an ARM64 system or use CI/CD.

```bash
# Install packaging tools
sudo apt-get install -y debhelper devscripts dh-python

# Build the package
dpkg-buildpackage -us -uc -b

# Package will be in parent directory
ls ../*.deb
```

### Using GitHub Actions (Recommended)

For production builds, use GitHub Actions workflows which run on self-hosted ARM64 runners:

```bash
# Push to trigger CI builds
git push origin main

# Or manually trigger workflows via GitHub web interface
```

Workflows available:

- `build-debian-package.yml` - Builds .deb package
- `build-rpi-image.yml` - Builds SD card images for Raspberry Pi 5
- `release.yml` - Creates releases with all artifacts

## Upload the Firmware Package to a Buildbotics CNC Controller

If you have a Buildbotics CNC controller at `bbctrl.local`, the default
address, you can upgrade it with the new package like this:

    make update HOST=bbctrl.local PASSWORD=<pass>

Where `<pass>` is the controller's admin password.

## Updating the Pwr Firmware

The Pwr firmware must be uploaded manually using an ISP programmer. With the
programmer attached to the pwr chip ISP port on the Builbotics controller's
main board run the following:

    make -C src/pwr program

## Initializing the main AVR firmware

The main AVR must also be programmed manually the first time. Later it will be
automatically programmed by the RPi as part of the firmware install. To perform
the initial AVR programming connec the ISP programmer to the main AVR's ISP port
on the Buildbotics controller's main board and run the following:

    make -C src/avr init

This will set the fuses, install the bootloader and program the firmware.

## Raspberry Pi 5 Base System

The image build script pins the Raspberry Pi OS Bookworm ARM64 base image URL
and produces the versioned Pi 5 image. Use the generated image or a release
image as described in [DEPLOYMENT.md](../DEPLOYMENT.md), rather than writing an
unmodified base image to the controller's SD card.

## Testing on Hardware

### SSH Access to OneFinity Controller

You can SSH into the OneFinity Controller. The hostname depends on the installation method:

- **SD Card Image**: `onefinity.local` (hostname set during image build)
- **Manual Setup**: The hostname configured on the Pi 5

```bash
ssh <configured-user>@onefinity.local
```

Configure SSH credentials when preparing the operating system, and change any
initial password after first login.

### Testing Debian Package Installation

1. Build the package (on ARM64 system or via CI)
2. Copy to the Raspberry Pi 5:
   ```bash
   scp ../onefinity-firmware_*.deb <configured-user>@onefinity.local:~
   ```
3. Install on the Pi:
   ```bash
   ssh <configured-user>@onefinity.local
   sudo apt update
   sudo apt install ./onefinity-firmware_*.deb
   sudo systemctl start onefinity
   ```

### Testing SD Card Images

1. Build image using the workflow script
2. Flash to SD card
3. Boot Raspberry Pi
4. Verify functionality

## Development Tips

### Quick Frontend Iteration

For rapid frontend development:

```bash
# Watch mode for Svelte components
cd src/svelte-components
npm run dev
```

### Python Backend Development

The Python backend can be run directly for testing:

```bash
cd src/py
python3 -m bbctrl
```

### AVR Firmware Development

```bash
cd src/avr
make clean
make
# Flash to AVR (requires ISP programmer)
make program
```

## Project Structure for Developers

```
src/
├── js/                 # Frontend JavaScript (legacy)
├── pug/                # HTML templates
├── stylus/             # CSS styles
├── svelte-components/  # Modern Svelte UI components
│   ├── src/           # Svelte source files
│   └── dist/          # Built components
├── py/
│   └── bbctrl/        # Python backend (machine control logic)
├── avr/               # AVR firmware (C/C++)
├── bbserial/          # Serial communication kernel module
├── boot/              # Boot loader
├── pwr/               # Power management AVR
└── jig/               # Testing jig firmware

debian/                # Debian packaging metadata
├── control            # Package dependencies
├── rules              # Build rules
├── changelog          # Version history
└── ...

.github/workflows/     # CI/CD workflows
├── build-debian-package.yml
├── build-rpi-image.yml
├── release.yml
└── scripts/
    └── build-rpi-image.sh

scripts/               # System scripts
├── install.sh        # Installation script
├── setup_rpi.sh      # Raspberry Pi setup
├── avr109-flash.py   # AVR firmware flashing
└── ...
```

## CI/CD Workflows

### Self-Hosted ARM64 Runners

The project uses self-hosted GitHub Actions runners running on ARM64 hardware.
This provides:

- **Native ARM builds** (no QEMU emulation)
- **Faster build times**
- **Direct hardware access** for testing

### Workflow Files

- **build-test.yml**: Runs on every push/PR, builds and tests
- **build-debian-package.yml**: Builds Debian package
- **build-rpi-image.yml**: Builds SD card images for Raspberry Pi 5
- **release.yml**: Creates GitHub releases with all artifacts
- **tag.yml**: Creates version tags

### Triggering Builds

```bash
# Regular push triggers build-test.yml
git push origin main

# Creating a tag triggers release.yml
git tag v1.6.8
git push origin v1.6.8

# Manual workflow dispatch via GitHub UI
# Go to Actions → Choose workflow → Run workflow
```

## Debugging

### Check Service Logs

```bash
# On the Raspberry Pi
sudo journalctl -u onefinity -f
```

### Python Debugging

Add debugging to Python code:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### AVR Debugging

Use AVR simulator or hardware debugger (requires external tools).

## Common Development Tasks

### Update Frontend

1. Edit files in `src/js/`, `src/pug/`, or `src/svelte-components/`
2. Run `make all`
3. Test in browser at `http://onefinity.local`

### Update Python Backend

1. Edit files in `src/py/bbctrl/`
2. Copy to Pi: `rsync -av src/py/ bbmc@onefinity.local:/tmp/bbctrl/`
3. On Pi: `sudo systemctl restart onefinity`

### Update AVR Firmware

1. Edit files in `src/avr/`
2. Run `make -C src/avr`
3. Flash: `./scripts/avr109-flash.py src/avr/bbctrl-avr-firmware.hex`

### Create a New Release

1. Update version in `package.json`
2. Update `debian/changelog`
3. Commit changes
4. Create and push tag:
   ```bash
   git tag v1.6.8
   git push origin v1.6.8
   ```
5. GitHub Actions will build and create release automatically

## Troubleshooting Development Issues

### Build Failures

- Ensure all dependencies are installed
- Check Node and Python versions
- Clear build artifacts: `make clean`

### AVR Build Issues

- Install `gcc-avr` and `avr-libc`
- Check AVR toolchain version

### Package Build Issues

- Ensure on ARM64 system or use CI/CD
- Check `debian/control` dependencies
- Review build logs

### Runtime Issues on Raspberry Pi 5

- Check service status: `systemctl status onefinity`
- Review logs: `journalctl -u onefinity`
- Verify GPIO library installed: `python3-lgpio`

## Contributing

When contributing:

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test locally
5. Push and create pull request
6. CI will run automated tests
7. Address review feedback

See [MODERNIZATION_PLAN.md](../MODERNIZATION_PLAN.md) for architecture details.
