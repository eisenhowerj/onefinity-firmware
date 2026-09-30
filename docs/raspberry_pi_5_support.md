# Raspberry Pi 5 Support

## Supported platform

OneFinity firmware supports Raspberry Pi 5 systems running a 64-bit Raspberry
Pi OS Bookworm installation or later. The firmware package targets ARM64 and
requires Python 3.11 or later. Raspberry Pi 5 is the only supported Raspberry
Pi model.

## GPIO

The Pi 5 GPIO implementation uses the `lgpio` Python library from the
`python3-lgpio` package and GPIO chip 4. The package setup installs this
dependency. `libgpiod-tools` provides command-line diagnostics such as
`gpiodetect` and `gpioinfo`.

The compatibility module at `src/py/bbctrl/gpio_compat.py` preserves the
existing GPIO call interface and prefers `lgpio`. Its optional `RPi.GPIO`
fallback does not make other Raspberry Pi models supported and is not a package
dependency.

```python
from bbctrl import gpio_compat as gpio

gpio.setup(27, gpio.OUT)
gpio.output(27, 1)
```

On the Pi 5, the module opens `gpiochip4` and uses `lgpio` for these operations.

## Build and test

Build the Debian package on an ARM64 system or use the project build workflow.
Build tools require Node.js 22.22.2 or later and Python 3.11 or later.

```bash
npm ci
dpkg-buildpackage -us -uc -b
```

For development checks, see [docs/development.md](development.md). Deployment
and SD card flashing instructions are in [DEPLOYMENT.md](../DEPLOYMENT.md).

## Pi 5 hardware features

- 64-bit ARM64 package and Raspberry Pi OS image
- `lgpio` access through GPIO chip 4
- Bookworm boot configuration under `/boot/firmware`
- I2C and SPI configuration performed by the Pi setup/image process
