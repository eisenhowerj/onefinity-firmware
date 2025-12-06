#!/bin/bash -e
#
# Build gplan natively on ARM systems
# This script is used during debian package building to compile the gplan module
# without requiring qemu/chroot setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directories
WORK_DIR="${PROJECT_ROOT}/build/gplan-build"
CBANG_DIR="${WORK_DIR}/cbang"
CAMOTICS_DIR="${WORK_DIR}/camotics"
TARGET_DIR="${PROJECT_ROOT}/src/py/camotics"

# Git commits for dependencies (pinned to known working versions)
# These commits are the same as used in scripts/gplan-init-build.sh
CBANG_COMMIT="18f1e963107ef26abe750c023355a5c40dd07853"    # cbang base library
CAMOTICS_COMMIT="ec876c80d20fc19837133087cef0c447df5a939d"  # camotics gplan module

echo "Building gplan module natively..."
echo "Work directory: ${WORK_DIR}"

# Create work directory
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# Clone and build cbang if not already done
if [ ! -d "${CBANG_DIR}" ]; then
    echo "Cloning cbang..."
    git clone https://github.com/CauldronDevelopmentLLC/cbang "${CBANG_DIR}"
    cd "${CBANG_DIR}"
    git checkout "${CBANG_COMMIT}"
else
    echo "Using existing cbang directory"
    cd "${CBANG_DIR}"
fi

echo "Building cbang..."
scons -j$(nproc) disable_local="re2 libevent" || {
    echo "Warning: cbang build completed with warnings"
}

# Clone and build camotics if not already done
if [ ! -d "${CAMOTICS_DIR}" ]; then
    echo "Cloning camotics..."
    git clone https://github.com/CauldronDevelopmentLLC/camotics "${CAMOTICS_DIR}"
    cd "${CAMOTICS_DIR}"
    git checkout "${CAMOTICS_COMMIT}"
else
    echo "Using existing camotics directory"
    cd "${CAMOTICS_DIR}"
fi

# Set up environment for camotics build
export CBANG_HOME="${CBANG_DIR}"
export LC_ALL=C

# Create version file
CAMOTICS_ROOT="${CAMOTICS_DIR}"
CAMOTICS_PLAN="${CAMOTICS_ROOT}/src/gcode/plan"

mkdir -p "${CAMOTICS_ROOT}/build"
touch "${CAMOTICS_ROOT}/build/version.txt"

# Apply patches to prevent maxVel/maxJerk/maxAccel overflow issues
echo "Applying patches..."
if [ -f "${CAMOTICS_PLAN}/LineCommand.cpp" ]; then
    # Apply all three substitutions in a single perl command to reduce duplication
    perl -i -0pe '
        s/(fabs\((config\.maxVel\[axis\]) \/ unit\[axis\]\));/std::min(\2, \1);/gm;
        s/(fabs\((config\.maxJerk\[axis\]) \/ unit\[axis\]\));/std::min(\2, \1);/gm;
        s/(fabs\((config\.maxAccel\[axis\]) \/ unit\[axis\]\));/std::min(\2, \1);/gm;
    ' "${CAMOTICS_PLAN}/LineCommand.cpp" "${CAMOTICS_PLAN}/LinePlanner.cpp" 2>/dev/null || true
fi

# Build gplan module
echo "Building gplan module..."
cd "${CAMOTICS_DIR}"
scons -j$(nproc) gplan.so with_gui=0 with_tpl=0 || {
    echo "ERROR: Failed to build gplan.so"
    exit 1
}

# Copy gplan.so to target directory
if [ -f "${CAMOTICS_DIR}/gplan.so" ]; then
    echo "Installing gplan.so to ${TARGET_DIR}/"
    mkdir -p "${TARGET_DIR}"
    cp "${CAMOTICS_DIR}/gplan.so" "${TARGET_DIR}/"
    echo "Successfully built and installed gplan.so"
    ls -lh "${TARGET_DIR}/gplan.so"
else
    echo "ERROR: gplan.so was not built successfully"
    exit 1
fi

echo "gplan build complete!"
