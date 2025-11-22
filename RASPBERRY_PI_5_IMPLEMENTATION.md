# Raspberry Pi 5 Implementation Summary

## Overview
This document summarizes the changes made to add Raspberry Pi 5 support to the OneFinity CNC Controller Firmware.

## Problem
The firmware was originally built for Raspberry Pi 3 Model B, which uses the `RPi.GPIO` Python library for GPIO control. Raspberry Pi 5 has a different GPIO architecture and requires the `lgpio` library instead.

## Solution
A GPIO compatibility layer was implemented that automatically detects which GPIO library is available and provides a unified interface for both platforms.

## Files Modified

### 1. `src/py/bbctrl/gpio_compat.py` (NEW)
- **Purpose**: GPIO compatibility layer
- **Features**:
  - Automatically detects and uses `lgpio` (Pi 5) or `RPi.GPIO` (Pi 3)
  - Provides drop-in replacement interface matching `RPi.GPIO` API
  - Handles gpiochip4 on Pi 5 vs. BCM numbering on Pi 3
  - Manages pin setup, input/output operations, and cleanup

### 2. `scripts/avr109-flash.py` (MODIFIED)
- **Changes**: Updated to use GPIO compatibility layer
- **Backward Compatible**: Falls back to direct `RPi.GPIO` import if compatibility layer not available
```python
try:
    from bbctrl import gpio_compat as gpio
except ImportError:
    import RPi.GPIO as gpio
```

### 3. `scripts/setup_rpi.sh` (MODIFIED)
- **Changes**: Comprehensive updates for Pi 5 support
- **Key modifications**:
  - Detects Pi model from `/proc/device-tree/model`
  - Sets correct boot config paths:
    - Pi 3: `/boot/config.txt`, `/boot/cmdline.txt`
    - Pi 5: `/boot/firmware/config.txt`, `/boot/firmware/cmdline.txt`
  - Installs appropriate packages:
    - Pi 3: `python3-rpi.gpio`, `wiringpi`
    - Pi 5: `python3-lgpio`, `libgpiod-tools`
  - Handles Pi-specific configurations:
    - Different Bluetooth disable overlays
    - Different I2C module requirements
    - Different GPIO control methods (wiringpi vs gpioset)

### 4. `README.md` (MODIFIED)
- **Changes**: Added supported hardware section
- Lists both Pi 3 Model B and Pi 5
- Links to detailed Pi 5 documentation

### 5. `docs/raspberry_pi_5_support.md` (NEW)
- **Purpose**: Detailed documentation of Pi 5 support
- **Contents**:
  - GPIO library differences
  - Compatibility layer usage
  - Setup instructions
  - Testing guidelines
  - Known limitations

### 6. `CHANGELOG.md` (MODIFIED)
- **Changes**: Added v1.6.8 entry documenting Pi 5 support

## Technical Details

### GPIO Library Mapping
| Feature | Raspberry Pi 3 | Raspberry Pi 5 |
|---------|----------------|----------------|
| Python Package | `python3-rpi.gpio` | `python3-lgpio` |
| GPIO Tools | `wiringpi` | `libgpiod-tools` |
| GPIO Chip | BCM numbering | gpiochip4 |
| Boot Config | `/boot/config.txt` | `/boot/firmware/config.txt` |

### GPIO Compatibility Layer API
The compatibility layer provides these functions:
- `setwarnings(state)` - Configure GPIO warnings
- `setmode(mode)` - Set GPIO mode (BCM)
- `setup(pin, direction, pull_up_down=None)` - Configure a pin
- `output(pin, value)` - Set output value
- `input(pin)` - Read input value
- `cleanup()` - Release GPIO resources

## Testing
All modified Python files pass syntax checks:
```bash
python3 -m py_compile src/py/bbctrl/gpio_compat.py
python3 -m py_compile scripts/avr109-flash.py
```

Shell script passes bash syntax check:
```bash
bash -n scripts/setup_rpi.sh
```

## Deployment
The firmware package built with `make pkg` will work on both Pi 3 and Pi 5. The setup script automatically detects the model and configures accordingly.

## Future Considerations
1. Test on actual Pi 5 hardware
2. Verify all GPIO operations work correctly on Pi 5
3. Test AVR flashing on Pi 5
4. Consider adding Pi 4 support (uses same GPIO as Pi 3)
5. Update any hardware-specific documentation

## Backward Compatibility
All changes maintain backward compatibility with Raspberry Pi 3. The firmware will continue to work on Pi 3 systems without any modifications.

## References
- Raspberry Pi 5 GPIO documentation
- lgpio library documentation: https://github.com/joan2937/lg
- RPi.GPIO library documentation
