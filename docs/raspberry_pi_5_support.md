# Raspberry Pi 5 Support

## Overview

This firmware supports Raspberry Pi 5 exclusively. Raspberry Pi 3 support has been removed to simplify the codebase and focus on the more capable Pi 5 hardware.

## GPIO Implementation

### Raspberry Pi 5
- Uses `lgpio` Python library
- Package: `python3-lgpio`
- New GPIO chip interface (gpiochip4)

## GPIO Compatibility Layer

A compatibility layer is implemented in `src/py/bbctrl/gpio_compat.py` that provides a unified GPIO interface. While it still supports fallback to RPi.GPIO for backward compatibility with existing code, the primary target is now lgpio for Raspberry Pi 5.

### Usage

Scripts import the compatibility layer for GPIO operations:

```python
from bbctrl import gpio_compat as gpio

gpio.setwarnings(False)
gpio.setmode(gpio.BCM)
gpio.setup(27, gpio.OUT)
gpio.output(27, 1)
```

The compatibility layer uses `lgpio` on Raspberry Pi 5.

## Building Firmware

Build the firmware package for ARM64:

```bash
make pkg
```

## Installing on Raspberry Pi 5

The setup script installs the required GPIO library:
1. Installs `python3-lgpio` for Pi 5 GPIO support
2. Configures GPIO settings for optimal CNC controller operation

## Key Implementation Files

- `src/py/bbctrl/gpio_compat.py` - GPIO compatibility layer
- `scripts/avr109-flash.py` - AVR flashing utility using GPIO
- `scripts/setup_rpi.sh` - System setup script
- `debian/control` - Package dependencies including python3-lgpio

## Testing

To test on Raspberry Pi 5:
1. Build the firmware package
2. Copy to Pi 5
3. Run setup script
4. Verify GPIO operations work correctly

## Hardware Requirements

- **Required**: Raspberry Pi 5 (ARM64)
- **OS**: Raspberry Pi OS Bookworm (Debian 12) or later
- **Python**: 3.11+
- **GPIO Library**: python3-lgpio
