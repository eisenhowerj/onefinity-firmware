# OneFinity CNC Controller Firmware

## Overview

OneFinity CNC Controller Firmware is a complete software solution for controlling CNC machines using Raspberry Pi hardware. It includes a web-based control interface, Python-based machine control backend, and AVR firmware for hardware communication.

## Supported Hardware

- **Raspberry Pi 3 Model B** (32-bit armhf)
- **Raspberry Pi 5** (64-bit arm64)

For detailed information about Raspberry Pi 5 support, see [docs/raspberry_pi_5_support.md](docs/raspberry_pi_5_support.md).

## Installation

### Quick Start: SD Card Images

The easiest way to get started is to flash a pre-built SD card image:

1. Download the appropriate image for your hardware:
   - [Pi 3 Image](https://github.com/eisenhowerj/onefinity-firmware/releases) - `onefinity-*-rpi3-armhf.img.xz`
   - [Pi 5 Image](https://github.com/eisenhowerj/onefinity-firmware/releases) - `onefinity-*-rpi5-arm64.img.xz`

2. Flash to SD card using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

3. Insert SD card, power on, and access at `http://onefinity.local`

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed flashing instructions.

### Advanced: Debian Package

For existing Raspberry Pi systems, install via Debian package:

```bash
# Download the latest package
wget https://github.com/eisenhowerj/onefinity-firmware/releases/download/vX.X.X/onefinity-firmware_X.X.X_arm64.deb

# Install
sudo apt update
sudo apt install ./onefinity-firmware_X.X.X_arm64.deb

# Start the service
sudo systemctl start onefinity
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment documentation.

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Installation and deployment guide
- **[MODERNIZATION_PLAN.md](MODERNIZATION_PLAN.md)** - Project structure and architecture
- **[docs/development.md](docs/development.md)** - Development setup and build instructions
- **[docs/raspberry_pi_5_support.md](docs/raspberry_pi_5_support.md)** - Raspberry Pi 5 specific information

## Development

See [docs/development.md](docs/development.md) for development setup and build instructions.

Quick start for developers:
```bash
# Clone repository
git clone https://github.com/eisenhowerj/onefinity-firmware.git
cd onefinity-firmware

# Install dependencies
npm install
pip3 install tornado sockjs-tornado pyserial pyudev smbus2 watchdog

# Build
make all
```

## Project Structure

```
onefinity-firmware/
├── src/
│   ├── js/              # Frontend JavaScript
│   ├── pug/             # HTML templates
│   ├── stylus/          # CSS styles
│   ├── svelte-components/  # Svelte UI components
│   ├── py/bbctrl/       # Python backend (machine control)
│   ├── avr/             # AVR firmware (hardware communication)
│   ├── boot/            # Boot configuration
│   └── resources/       # Static assets
├── scripts/             # System scripts and utilities
├── debian/              # Debian packaging metadata
├── .github/workflows/   # CI/CD workflows
└── docs/                # Documentation
```

## Building from Source

### Debian Package
```bash
# Install build dependencies
sudo apt-get install -y build-essential gcc-avr avr-libc \
    python3 python3-setuptools debhelper devscripts nodejs npm

# Build package
dpkg-buildpackage -us -uc -b

# Package will be in parent directory
ls ../*.deb
```

### RPi SD Card Image
```bash
# Build Debian package first (see above)

# Build image
.github/workflows/scripts/build-rpi-image.sh <version> <path-to-deb> <pi3|pi5>
```

## CI/CD

This project uses GitHub Actions with self-hosted ARM64 runners for native builds:

- **Build & Test**: Runs on every push and PR
- **Debian Package**: Built automatically
- **RPi Images**: Built for both Pi 3 and Pi 5
- **Releases**: Automated releases on version tags

See [MODERNIZATION_PLAN.md](MODERNIZATION_PLAN.md) for CI/CD architecture details.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the GPL-3.0+ License. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/eisenhowerj/onefinity-firmware/issues)
- **Documentation**: [docs/](docs/)
- **Website**: [OneFinity CNC](https://onefinitycnc.com/)

## Credits

Based on the Buildbotics CNC Controller project. Modified and maintained by the OneFinity team.
