#!/usr/bin/env python3

"""GPIO compatibility layer for Raspberry Pi
Primary target: Raspberry Pi 5 with lgpio
Maintains backward compatibility with RPi.GPIO as fallback
"""

import sys

# Try to import appropriate GPIO library
try:
    import lgpio
    USING_LGPIO = True
except ImportError:
    USING_LGPIO = False
    try:
        import RPi.GPIO as GPIO
        USING_RPI_GPIO = True
    except ImportError:
        USING_RPI_GPIO = False

if not USING_LGPIO and not USING_RPI_GPIO:
    raise ImportError("Neither lgpio nor RPi.GPIO is available")


class GPIOCompat:
    """Unified GPIO interface for Raspberry Pi
    Primarily targets Pi 5 with lgpio, falls back to RPi.GPIO if needed
    """
    
    BCM = 'BCM'
    OUT = 'OUT'
    IN = 'IN'
    PUD_UP = 'PUD_UP'
    
    def __init__(self):
        self._handle = None
        self._pin_modes = {}
        
        if USING_LGPIO:
            self._handle = lgpio.gpiochip_open(4)  # RPi 5 uses gpiochip4
        elif USING_RPI_GPIO:
            GPIO.setwarnings(False)
            GPIO.setmode(GPIO.BCM)
    
    def setwarnings(self, state):
        """Set GPIO warnings (RPi.GPIO only)"""
        if USING_RPI_GPIO:
            GPIO.setwarnings(state)
    
    def setmode(self, mode):
        """Set GPIO mode (RPi.GPIO only, no-op for lgpio)"""
        if USING_RPI_GPIO:
            GPIO.setmode(GPIO.BCM)
    
    def setup(self, pin, direction, pull_up_down=None):
        """Setup a GPIO pin"""
        if USING_LGPIO:
            if direction == self.OUT:
                lgpio.gpio_claim_output(self._handle, pin, 0)
                self._pin_modes[pin] = self.OUT
            else:
                flags = lgpio.SET_PULL_UP if pull_up_down == self.PUD_UP else 0
                lgpio.gpio_claim_input(self._handle, pin, flags)
                self._pin_modes[pin] = self.IN
        elif USING_RPI_GPIO:
            kwargs = {}
            if pull_up_down:
                kwargs['pull_up_down'] = GPIO.PUD_UP if pull_up_down == self.PUD_UP else GPIO.PUD_DOWN
            GPIO.setup(pin, GPIO.OUT if direction == self.OUT else GPIO.IN, **kwargs)
    
    def output(self, pin, value):
        """Set output value on a GPIO pin"""
        if USING_LGPIO:
            lgpio.gpio_write(self._handle, pin, value)
        elif USING_RPI_GPIO:
            GPIO.output(pin, value)
    
    def input(self, pin):
        """Read value from a GPIO pin"""
        if USING_LGPIO:
            return lgpio.gpio_read(self._handle, pin)
        elif USING_RPI_GPIO:
            return GPIO.input(pin)
    
    def cleanup(self):
        """Cleanup GPIO resources"""
        if USING_LGPIO:
            for pin in self._pin_modes.keys():
                lgpio.gpio_free(self._handle, pin)
            self._pin_modes.clear()
            if self._handle is not None:
                lgpio.gpiochip_close(self._handle)
        elif USING_RPI_GPIO:
            GPIO.cleanup()


# Create a global instance that mimics RPi.GPIO module interface
_gpio_instance = GPIOCompat()

# Export module-level functions
setwarnings = _gpio_instance.setwarnings
setmode = _gpio_instance.setmode
setup = _gpio_instance.setup
output = _gpio_instance.output
input = _gpio_instance.input
cleanup = _gpio_instance.cleanup

# Export constants
BCM = GPIOCompat.BCM
OUT = GPIOCompat.OUT
IN = GPIOCompat.IN
PUD_UP = GPIOCompat.PUD_UP
