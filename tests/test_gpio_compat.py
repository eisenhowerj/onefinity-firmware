#!/usr/bin/env python3
"""Test script for GPIO compatibility layer"""

import sys
import os

# Add the src/py directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'py'))

def test_import():
    """Test that the GPIO compatibility layer can be imported"""
    try:
        from bbctrl import gpio_compat
        print("✓ GPIO compatibility layer imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import GPIO compatibility layer: {e}")
        return False

def test_attributes():
    """Test that required attributes are available"""
    from bbctrl import gpio_compat
    
    required_attrs = ['BCM', 'OUT', 'IN', 'PUD_UP', 'setwarnings', 
                      'setmode', 'setup', 'output', 'input', 'cleanup']
    
    all_present = True
    for attr in required_attrs:
        if hasattr(gpio_compat, attr):
            print(f"✓ Attribute '{attr}' present")
        else:
            print(f"✗ Attribute '{attr}' missing")
            all_present = False
    
    return all_present

def test_backend():
    """Test which GPIO backend is being used"""
    from bbctrl import gpio_compat
    
    try:
        import lgpio
        print("✓ Using lgpio backend (Raspberry Pi 5 compatible)")
        return True
    except ImportError:
        pass
    
    try:
        import RPi.GPIO
        print("✓ Using RPi.GPIO backend (Raspberry Pi 3 compatible)")
        return True
    except ImportError:
        pass
    
    print("✗ No GPIO backend available")
    return False

if __name__ == '__main__':
    print("Testing GPIO Compatibility Layer")
    print("=" * 50)
    
    results = []
    results.append(("Import test", test_import()))
    
    if results[0][1]:  # Only run other tests if import succeeded
        results.append(("Attributes test", test_attributes()))
        results.append(("Backend detection", test_backend()))
    
    print("\n" + "=" * 50)
    print("Test Results:")
    for name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"  {name}: {status}")
    
    all_passed = all(result for _, result in results)
    sys.exit(0 if all_passed else 1)
