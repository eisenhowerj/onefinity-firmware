# OneFinity Firmware Modernization Plan

## Overview
This document outlines the plan to modernize the OneFinity CNC firmware project structure by splitting the monorepo into logical components with clear separation of concerns.

## Current Architecture

### Monorepo Components
The current repository contains three major components:

1. **HTTP Frontend** (Web UI)
   - Location: `src/js/`, `src/pug/`, `src/stylus/`, `src/svelte-components/`, `src/static/`, `src/resources/`
   - Technology: JavaScript, Pug templates, Stylus CSS, Svelte components
   - Build output: `build/http/`
   - Purpose: Web-based control interface

2. **Machine Controls** (Python Backend + AVR Firmware)
   - Location: `src/py/bbctrl/`, `src/avr/`, `src/bbserial/`, `src/pwr/`, `src/jig/`
   - Technology: Python (Tornado), C/C++ (AVR), Linux kernel modules
   - Purpose: CNC machine control logic, G-code processing, hardware communication
   - Dependencies: tornado, sockjs-tornado, pyserial, pyudev, smbus2, watchdog

3. **Raspberry Pi Integration** (Hardware Setup)
   - Location: `scripts/`, `src/boot/`, `src/splash/`
   - Key files: `scripts/setup_rpi.sh`, `scripts/install.sh`, boot configuration
   - Purpose: RPi-specific setup, GPIO configuration, system initialization
   - Output: Ready-to-flash SD card images

## Proposed Architecture

### Phase 1: In-Repo Restructuring (Current Work)
Maintain the monorepo but clearly separate concerns through:

#### 1.1 Debian Package Structure
Create a Debian package containing frontend + controls that can be installed on any compatible RPi system.

**Package Contents:**
- Frontend HTTP files → `/opt/onefinity/http/`
- Python backend → `/opt/onefinity/lib/python/`
- AVR firmware → `/opt/onefinity/firmware/`
- System scripts → `/opt/onefinity/bin/`
- Systemd service files → `/etc/systemd/system/`

**Build Process:**
- Add `debian/` directory with packaging metadata
- GitHub workflow builds components and creates `.deb` package
- No Makefile dependency - workflows handle all build steps
- Package version from `package.json`

**Benefits:**
- Easy upgrades via `apt` or manual `.deb` installation
- Standard Linux deployment model
- Separates application from OS image
- CI/CD-native approach without local Makefile complexity

#### 1.2 RPi SD Card Image Builder
Create infrastructure to build bootable SD card images with the Debian package pre-installed.

**Image Contents:**
- Base: Raspberry Pi OS Lite (Bookworm)
- Pre-installed: OneFinity Debian package
- Pre-configured: GPIO, I2C, boot settings, system services
- Ready-to-use: Flash and power on

**Build Process:**
- Download base RPi OS image
- Mount image partitions
- Chroot and install Debian package
- Configure system settings
- Create distributable image

**Benefits:**
- Turnkey solution for new installations
- Reproducible builds
- Maintains hardware-specific optimizations

### Phase 2: CI/CD Modernization (Current Work)

#### 2.1 Self-Hosted ARM64 Runners
Update all workflows to use self-hosted Debian arm64 runners instead of x86 with QEMU emulation.

**Workflow Changes:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, arm64]
```

**Benefits:**
- Native ARM builds (faster, no emulation overhead)
- Direct hardware access for testing
- Consistent build environment

#### 2.2 Automated Build Workflows

**Debian Package Build** (`.github/workflows/build-debian-package.yml`)
- Trigger: Push to main/develop, pull requests
- Steps: Install deps → Build all → Create .deb → Upload artifact
- Output: `onefinity-firmware_<version>_arm64.deb`

**RPi Image Build** (`.github/workflows/build-rpi-image.yml`)
- Trigger: Tag creation, manual dispatch
- Steps: Download base image → Install package → Configure → Create image
- Output: `onefinity-<version>-rpi.img.xz`

**Release Workflow** (Update existing `release.yml`)
- Trigger: Version tags (v*)
- Steps: Build both package and image → Create GitHub release
- Artifacts: .deb package + .img.xz image

### Phase 3: Future Repository Split (Future Work)
*Note: This phase is documented for future planning but NOT implemented in current work*

When the project scales further, consider splitting into:

1. **onefinity-firmware** (Frontend + Controls Debian Package)
   - Current: Frontend, Python backend, AVR firmware
   - Distribution: Debian package only

2. **onefinity-rpi-builder** (Image Builder)
   - Current: RPi setup scripts, image building tools
   - Distribution: SD card images
   - Dependency: Consumes firmware Debian package

## Implementation Details

### Debian Package Structure

```
debian/
├── control                 # Package metadata, dependencies
├── rules                   # Build rules (debhelper)
├── changelog              # Version history
├── compat                 # Debhelper compatibility
├── install                # File installation mappings
├── postinst               # Post-installation script
├── prerm                  # Pre-removal script
├── onefinity.service      # Systemd service file
└── copyright              # License information
```

### Directory Layout After Installation

```
/opt/onefinity/
├── bin/                   # System scripts
│   ├── update-onefinity
│   ├── config-wifi
│   └── ...
├── http/                  # Frontend files
│   ├── index.html
│   ├── js/
│   └── css/
├── lib/
│   └── python/           # Python backend
│       └── bbctrl/
├── firmware/
│   └── avr/              # AVR firmware
└── share/
    └── resources/        # Static resources

/etc/systemd/system/
└── onefinity.service     # Systemd service

/var/log/onefinity/       # Log files
/var/lib/onefinity/       # State and config
```

### Build Script Updates

**GitHub Workflow Approach:**
Instead of extending the Makefile, all build logic is moved to GitHub workflows:
- Workflows orchestrate the entire build process
- Existing Makefile remains for local development only
- Production builds use workflow scripts in `.github/workflows/scripts/`
- Build steps are explicitly defined in workflow YAML files

### RPi Image Build Process

1. **Download Base Image**
   - Raspberry Pi OS Lite (Bookworm)
   - Both armhf (Pi 3) and arm64 (Pi 5) variants

2. **Mount and Prepare**
   - Mount boot and root partitions
   - Setup qemu-user-static for chroot (if building on x86)

3. **Install Package**
   - Copy .deb into chroot
   - `apt install ./onefinity-firmware_*.deb`

4. **Configure System**
   - Run `setup_rpi.sh` equivalent in chroot
   - Configure boot settings, GPIO, services
   - Set default credentials and hostname

5. **Finalize**
   - Unmount partitions
   - Compress image: `xz -9 -T0 onefinity-*.img`

## Workflow Transition Plan

### Current Workflows
- `build-test.yml`: Uses self-hosted EC2 runner, builds package
- `release.yml`: Uses Ubuntu latest (x86), builds and releases
- `tag.yml`: Creates version tags

### Updated Workflows

#### build-debian-package.yml (NEW)
```yaml
name: Build Debian Package
on: [push, pull_request, workflow_dispatch]
jobs:
  build:
    runs-on: [self-hosted, linux, arm64]
    steps:
      - Checkout code
      - Install dependencies
      - Build all components
      - Create .deb package
      - Upload artifact
```

#### build-rpi-image.yml (NEW)
```yaml
name: Build RPi SD Image
on:
  workflow_dispatch:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: [self-hosted, linux, arm64]
    steps:
      - Build or download .deb
      - Download base RPi OS
      - Build SD card image
      - Upload artifact
```

#### release.yml (UPDATED)
```yaml
name: Release
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: [self-hosted, linux, arm64]
    steps:
      - Build .deb package
      - Build RPi image
      - Create GitHub release
      - Upload both artifacts
```

## Migration Path

### Step 1: Add Debian Packaging (In Progress)
- Create `debian/` directory structure
- Add packaging metadata and build rules
- Test local .deb builds
- Update documentation

### Step 2: Update CI/CD (In Progress)
- Create new workflow files
- Update existing workflows for arm64
- Test builds on self-hosted runner
- Document runner setup requirements

### Step 3: Add RPi Image Builder (In Progress)
- Create image build scripts
- Test image generation
- Automate in CI/CD
- Document flashing process

### Step 4: Documentation (In Progress)
- Update README.md
- Create DEPLOYMENT.md
- Update development.md
- Add troubleshooting guides

### Step 5: Validation (Final)
- Test .deb installation on clean RPi
- Test RPi image flashing and boot
- Verify all workflows execute successfully
- Get stakeholder approval

## Benefits of This Approach

### For Users
- **Easier Updates**: Install .deb packages via apt or manual download
- **Faster Setup**: Flash pre-built images for new installations
- **Better Support**: Clearer separation of concerns

### For Developers
- **Faster Builds**: Native ARM compilation without emulation
- **Clearer Structure**: Defined boundaries between components
- **Standard Tools**: Use Debian packaging and standard CI/CD

### For Maintenance
- **Reproducible**: Standard Debian packaging practices
- **Testable**: Separate testing of package vs image
- **Scalable**: Ready for future repository split if needed

## Dependencies and Interfaces

### Debian Package Dependencies (debian/control)
```
Depends: python3 (>= 3.9),
         python3-tornado,
         python3-sockjs-tornado,
         python3-serial,
         python3-pyudev,
         python3-smbus2,
         python3-watchdog,
         systemd,
         avrdude
Recommends: python3-lgpio | python3-rpi.gpio
```

### Build Dependencies
```
Build-Depends: debhelper (>= 12),
               nodejs (>= 18),
               npm,
               python3,
               python3-setuptools,
               gcc-avr,
               avr-libc,
               make
```

## Testing Strategy

### Package Testing
1. Install .deb on clean RPi 3 → Verify operation
2. Install .deb on clean RPi 5 → Verify operation
3. Upgrade existing installation → Verify no breakage
4. Uninstall package → Verify clean removal

### Image Testing
1. Flash image to SD card
2. Boot Raspberry Pi 3 → Verify operation
3. Boot Raspberry Pi 5 → Verify operation
4. Test network configuration
5. Test web interface access

### CI/CD Testing
1. Verify builds on self-hosted runner
2. Test artifact uploads
3. Test release creation
4. Verify reproducible builds

## Rollout Plan

1. **Week 1**: Debian packaging infrastructure
2. **Week 2**: CI/CD workflow updates
3. **Week 3**: RPi image builder
4. **Week 4**: Documentation and testing
5. **Week 5**: Validation and release

## Success Criteria

- [ ] Debian package builds successfully on arm64
- [ ] Package installs cleanly on RPi 3 and 5
- [ ] RPi images boot and run firmware correctly
- [ ] All CI/CD workflows execute on self-hosted runner
- [ ] Documentation is complete and accurate
- [ ] Existing functionality remains intact
- [ ] Team approves new structure

## Future Enhancements

1. **Multi-architecture support**: Build arm64 and armhf packages
2. **APT repository**: Host packages for apt installation
3. **Automated testing**: Integration tests in CI/CD
4. **Repository split**: Separate firmware and image builder repos
5. **Version management**: Automated changelog generation

## Questions and Decisions

### Resolved
- **Q**: Keep monorepo or split now?
  - **A**: Keep monorepo, add clear separation, document future split

- **Q**: Support both Pi 3 and Pi 5?
  - **A**: Yes, maintain existing multi-platform support

### Open
- Package name: `onefinity-firmware` or `bbctrl`?
- Version scheme: Match package.json or independent?
- Image distribution: GitHub releases or separate hosting?

## References

- [Debian Packaging Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [RPi OS Image Customization](https://www.raspberrypi.com/documentation/computers/os.html)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- Existing project: `docs/development.md`, `scripts/setup_rpi.sh`
