# Raspberry Pi 5 Support

## Overview

This firmware now supports both Raspberry Pi 3 Model B and Raspberry Pi 5. The main difference between these models is the GPIO handling.

## GPIO Changes

### Raspberry Pi 3
- Uses `RPi.GPIO` Python library
- Package: `python3-rpi.gpio`
- Traditional GPIO interface

### Raspberry Pi 5
- Uses `lgpio` Python library
- Package: `python3-lgpio`
- New GPIO chip interface (gpiochip4)

## GPIO Compatibility Layer

A compatibility layer has been implemented in `src/py/bbctrl/gpio_compat.py` that automatically detects which GPIO library is available and provides a unified interface. This allows the same code to work on both Pi 3 and Pi 5.

### Usage

Scripts can import the compatibility layer instead of RPi.GPIO directly:

```python
from bbctrl import gpio_compat as gpio

gpio.setwarnings(False)
gpio.setmode(gpio.BCM)
gpio.setup(27, gpio.OUT)
gpio.output(27, 1)
```

The compatibility layer will automatically use:
- `lgpio` on Raspberry Pi 5 (if available)
- `RPi.GPIO` on Raspberry Pi 3 (fallback)

## Setup Script

The `scripts/setup_rpi.sh` script now detects the Raspberry Pi model and installs the appropriate GPIO library:

- **Pi 5**: Installs `python3-lgpio` (wiringpi is not needed as it doesn't support Pi 5)
- **Pi 3**: Installs `python3-rpi.gpio` and `wiringpi`

## Building Firmware

No changes are needed to the build process. The firmware package will work on both Pi 3 and Pi 5:

```bash
make pkg
```

## Installing on Raspberry Pi 5

When running `setup_rpi.sh` on a Raspberry Pi 5, the script will automatically:
1. Detect the Pi 5 model
2. Install `python3-lgpio` instead of `python3-rpi.gpio`
3. Skip installing `wiringpi` (not compatible with Pi 5)

## Modified Files

- `src/py/bbctrl/gpio_compat.py` - New GPIO compatibility layer
- `scripts/avr109-flash.py` - Updated to use compatibility layer
- `scripts/setup_rpi.sh` - Updated to detect Pi model and install appropriate packages
- `docs/raspberry_pi_5_support.md` - This documentation

## Testing

To test on Raspberry Pi 5:
1. Build the firmware package
2. Copy to Pi 5
3. Run setup script
4. Verify GPIO operations work correctly

## Limitations

- The firmware has been updated to work with both models, but thorough testing on Pi 5 hardware is recommended
- Some hardware-specific features may behave differently on Pi 5 due to architectural changes
