#!/bin/bash
set -e

# Build RPi SD card image with OneFinity firmware pre-installed
# Usage: build-rpi-image.sh <version> <deb-file> <rpi-model>

VERSION=${1:-"1.6.7"}
DEB_FILE=${2:-""}
RPI_MODEL=${3:-"pi3"}  # pi3 or pi5

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
    echo "Error: Debian package file not found: $DEB_FILE"
    exit 1
fi

echo "Building OneFinity RPi ${RPI_MODEL} image version ${VERSION}"
echo "Using Debian package: ${DEB_FILE}"

# Configuration
WORK_DIR="$(pwd)/rpi-image-build"
MOUNT_DIR="${WORK_DIR}/mnt"
OUTPUT_DIR="$(pwd)/dist"

# RPi OS image URLs
if [ "$RPI_MODEL" = "pi5" ]; then
    # Pi 5 requires 64-bit OS
    BASE_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-07-04/2024-07-04-raspios-bookworm-arm64-lite.img.xz"
    BASE_IMAGE_NAME="raspios-bookworm-arm64-lite.img"
    OUTPUT_IMAGE="onefinity-${VERSION}-rpi5-arm64.img"
else
    # Pi 3 uses 32-bit OS
    BASE_IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf-lite.img.xz"
    BASE_IMAGE_NAME="raspios-bookworm-armhf-lite.img"
    OUTPUT_IMAGE="onefinity-${VERSION}-rpi3-armhf.img"
fi

# Cleanup previous builds
echo "Cleaning up previous builds..."
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Download base image if not cached
cd "${WORK_DIR}"
if [ ! -f "${BASE_IMAGE_NAME}" ]; then
    echo "Downloading RPi OS base image..."
    wget -O base.img.xz "${BASE_IMAGE_URL}"
    echo "Extracting base image..."
    xz -d base.img.xz
    mv base.img "${BASE_IMAGE_NAME}"
else
    echo "Using cached base image: ${BASE_IMAGE_NAME}"
fi

# Create working copy
echo "Creating working copy of image..."
cp "${BASE_IMAGE_NAME}" "${OUTPUT_IMAGE}"

# Mount the image
echo "Mounting image partitions..."
LOOP_DEVICE=$(sudo losetup -f --show -P "${OUTPUT_IMAGE}")
echo "Using loop device: ${LOOP_DEVICE}"

# Wait for partition devices to be ready
sleep 2

# Mount partitions
mkdir -p "${MOUNT_DIR}/boot"
mkdir -p "${MOUNT_DIR}/root"

sudo mount "${LOOP_DEVICE}p1" "${MOUNT_DIR}/boot"
sudo mount "${LOOP_DEVICE}p2" "${MOUNT_DIR}/root"

# Copy Debian package into chroot
echo "Copying Debian package into image..."
sudo cp "${DEB_FILE}" "${MOUNT_DIR}/root/tmp/"
DEB_FILENAME=$(basename "${DEB_FILE}")

# Install the package in chroot
echo "Installing OneFinity firmware package..."
sudo chroot "${MOUNT_DIR}/root" /bin/bash -c "
    apt-get update
    apt-get install -y /tmp/${DEB_FILENAME}
    rm /tmp/${DEB_FILENAME}
"

# Configure system for OneFinity
echo "Configuring system for OneFinity..."
sudo chroot "${MOUNT_DIR}/root" /bin/bash -c "
    # Set hostname
    echo 'onefinity' > /etc/hostname
    sed -i 's/raspberrypi/onefinity/g' /etc/hosts
    
    # Enable I2C
    raspi-config nonint do_i2c 0
    
    # Enable SSH
    systemctl enable ssh
    touch /boot/ssh
"

# Configure boot settings
echo "Configuring boot settings..."
if [ "$RPI_MODEL" = "pi5" ]; then
    # Pi 5 boot config
    sudo bash -c "cat >> ${MOUNT_DIR}/boot/firmware/config.txt" << 'EOF'

# OneFinity CNC Controller Settings
dtparam=i2c_arm=on
dtparam=spi=on
max_usb_current=1
disable_splash=1

# Disable Bluetooth
dtoverlay=disable-bt
EOF
else
    # Pi 3 boot config
    sudo bash -c "cat >> ${MOUNT_DIR}/boot/config.txt" << 'EOF'

# OneFinity CNC Controller Settings
dtparam=i2c_arm=on
dtparam=spi=on
max_usb_current=1
config_hdmi_boost=8
disable_splash=1

# Disable Bluetooth
dtoverlay=pi3-disable-bt
EOF
fi

# Cleanup and unmount
echo "Cleaning up..."
sudo umount "${MOUNT_DIR}/boot"
sudo umount "${MOUNT_DIR}/root"
sudo losetup -d "${LOOP_DEVICE}"

# Move to output directory
echo "Moving image to output directory..."
mv "${OUTPUT_IMAGE}" "${OUTPUT_DIR}/"

# Compress image
echo "Compressing image..."
cd "${OUTPUT_DIR}"
xz -9 -T0 "${OUTPUT_IMAGE}"

echo "Build complete!"
echo "Output: ${OUTPUT_DIR}/${OUTPUT_IMAGE}.xz"
echo "Size: $(du -h ${OUTPUT_IMAGE}.xz | cut -f1)"

# Cleanup work directory
rm -rf "${WORK_DIR}"
