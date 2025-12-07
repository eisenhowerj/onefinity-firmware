#!/bin/bash -e

export LC_ALL=C
cd /mnt/host

# Update the system
apt-get update
apt-get dist-upgrade -y

# Detect Raspberry Pi model
RPI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
if ! echo "$RPI_MODEL" | grep -q "Raspberry Pi 5"; then
  echo "Error: This firmware requires Raspberry Pi 5. Detected: $RPI_MODEL"
  exit 1
fi

# Configure paths for Pi 5
BOOT_CONFIG="/boot/firmware/config.txt"
BOOT_CMDLINE="/boot/firmware/cmdline.txt"

# Install packages for Pi 5
apt-get install -y avahi-daemon avrdude minicom python3-pip python3-smbus \
  i2c-tools python3-lgpio libgpiod-tools libjpeg8 dnsmasq hostapd \
  iptables-persistent chromium-browser xorg rpd-plym-splash samba
pip3 install --upgrade tornado sockjs-tornado pyserial

# Clean
apt-get autoclean

# Enable avahi
update-rc.d avahi-daemon defaults

# Change hostname
sed -i "s/raspberrypi/bbctrl/" /etc/hosts /etc/hostname

# Create bbmc user
useradd -m -p $(openssl passwd -1 buildbotics) -s /bin/bash bbmc
sed -i 's/pi$/pi,bbmc/g' /etc/group
passwd -l pi

# Disable console on serial port
sed -i 's/console=[a-zA-Z0-9]*,115200 \?//' $BOOT_CMDLINE

# Enable I2C
sed -i 's/#dtparam=i2c/dtparam=i2c/' $BOOT_CONFIG
echo i2c-dev >> /etc/modules

# Install bbctrl w/ init.d script
cp bbctrl.init.d /etc/init.d/bbctrl
chmod +x /etc/init.d/bbctrl
update-rc.d bbctrl defaults

# Disable USART BlueTooth swap
echo -e "\ndtoverlay=disable-bt" >> $BOOT_CONFIG
rm -f /etc/systemd/system/multi-user.target.wants/hciuart.service

# Install hawkeye
dpkg -i hawkeye_0.6_armhf.deb
sed -i 's/localhost/0.0.0.0/' /etc/hawkeye/hawkeye.conf
echo 'ACTION=="add", KERNEL=="video0", RUN+="/usr/sbin/service hawkeye restart"' > /etc/udev/rules.d/50-hawkeye.rules
adduser hawkeye video

# Disable HDMI to save power and remount /boot read-only
sed -i 's/^exit 0$//' /etc/rc.local
echo "mount -o remount,ro /boot/firmware" >> /etc/rc.local
# On Pi 5, use gpioset from libgpiod-tools for serial CTS
echo "gpioset gpiochip4 27=alt3 2>/dev/null || true" >> /etc/rc.local

# Dynamic clock to save power
echo -e "\n# Dynamic clock\nnohz=on" >> $BOOT_CONFIG

# Enable ssh
touch /boot/ssh

# Fix boot
sed -i 's/ root=[^ ]* / root=\/dev\/mmcblk0p2/' /boot/cmdline.txt
sed -i 's/^PARTUUID=.*\/boot/\/dev\/mmcblk0p1 \/boot/' /etc/fstab
sed -i 's/^PARTUUID=.*\//\/dev\/mmcblk0p2 \//' /etc/fstab

# Enable browser in xorg
sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
echo "sudo -u pi startx" >> /etc/rc.local
cp /mnt/host/xinitrc /home/pi/.xinitrc
cp /mnt/host/ratpoisonrc /home/pi/.ratpoisonrc
cp /mnt/host/xorg.conf /etc/X11/

# Configure the screen to not do overscan (only necessary for TVs)
sed -i 's/^#disable_overscan/disable_overscan/' $BOOT_CONFIG

# Boot splash
mkdir -p /usr/share/plymouth/themes/buildbotics/
cp -av /mnt/host/splash/* /usr/share/plymouth/themes/buildbotics/
echo -n " quiet splash logo.nologo plymouth.ignore-serial-consoles" >> $BOOT_CMDLINE
plymouth-set-default-theme -R buildbotics

# Samba
# TODO install custom smb.conf
smbpasswd -a bbmc

# Install bbctrl
tar xf /mnt/host/bbctrl-*.tar.bz2
cd $(basename bbctrl-*.tar.bz2 .tar.bz2)
./setup.py install
cd ..
rm -rf $(basename bbctrl-*.tar.bz2 .tar.bz2)


# Allow any user to shutdown
chmod +s /sbin/{halt,reboot,shutdown,poweroff}

# Clean up
apt-get autoremove -y
apt-get autoclean -y
