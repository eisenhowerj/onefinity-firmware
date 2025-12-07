#!/usr/bin/env python3
"""
Minimal setup.py wrapper for backward compatibility.

Modern Python packaging is now defined in pyproject.toml.
This file exists only for additional configuration not supported in pyproject.toml,
specifically the scripts that need to be installed.

For new installations, use:
    pip install .
or:
    python -m build
"""

from setuptools import setup

# All configuration is in pyproject.toml except for scripts
# Scripts are listed here because setuptools doesn't support them in pyproject.toml
setup(
    scripts=[
        'scripts/update-bbctrl',
        'scripts/upgrade-bbctrl',
        'scripts/sethostname',
        'scripts/reset-video',
        'scripts/config-wifi',
        'scripts/config-screen',
        'scripts/edit-config',
        'scripts/edit-boot-config',
        'scripts/browser',
    ],
)
