# OneFinity Firmware Deployment Guide

## Overview

OneFinity firmware can be deployed in two ways:
1. **Debian Package (.deb)**: Install or upgrade firmware on an existing Raspberry Pi system
2. **SD Card Image (.img.xz)**: Flash a complete, ready-to-use system image for new installations

## Debian Package Deployment

### Prerequisites
- Raspberry Pi 5
- Raspberry Pi OS Bookworm (or compatible Debian-based system)
- Network connectivity (for downloading dependencies)

### Installation

1. **Download the Package**
   
   Download the latest `.deb` package from the [releases page](https://github.com/eisenhowerj/onefinity-firmware/releases):
   ```bash
   wget https://github.com/eisenhowerj/onefinity-firmware/releases/download/vX.X.X/onefinity-firmware_X.X.X_arm64.deb
   ```

2. **Install the Package**
   
   ```bash
   sudo apt update
   sudo apt install ./onefinity-firmware_X.X.X_arm64.deb
   ```
   
   This will:
   - Install all dependencies
   - Set up the OneFinity service
   - Configure system files
   - Enable (but not start) the service

3. **Configure the System**
   
   For first-time installations, run the setup script:
   ```bash
   sudo /opt/onefinity/bin/setup-rpi.sh
   ```
   
   This configures GPIO, I2C, boot settings, and other hardware-specific options.

4. **Start the Service**
   
   ```bash
   sudo systemctl start onefinity
   ```

5. **Verify Installation**
   
   Check service status:
   ```bash
   sudo systemctl status onefinity
   ```
   
   Check logs:
   ```bash
   sudo journalctl -u onefinity -f
   ```

6. **Access the Web Interface**
   
   Open a browser and navigate to:
   ```
   http://onefinity.local
   ```
   Or use the IP address of your Raspberry Pi.

### Upgrading

To upgrade an existing installation:

1. **Download the New Package**
   
   ```bash
   wget https://github.com/eisenhowerj/onefinity-firmware/releases/download/vX.X.X/onefinity-firmware_X.X.X_arm64.deb
   ```

2. **Stop the Service**
   
   ```bash
   sudo systemctl stop onefinity
   ```

3. **Install the Upgrade**
   
   ```bash
   sudo apt install ./onefinity-firmware_X.X.X_arm64.deb
   ```

4. **Restart the Service**
   
   ```bash
   sudo systemctl start onefinity
   ```

### Uninstallation

To remove OneFinity firmware:

```bash
sudo apt remove onefinity-firmware
```

To completely remove including configuration:

```bash
sudo apt purge onefinity-firmware
```

## SD Card Image Deployment

### Prerequisites
- Raspberry Pi 5
- MicroSD card (8GB minimum, 16GB+ recommended)
- SD card reader
- Computer for flashing the image

### Available Images

SD card image for Raspberry Pi 5:
- **Pi 5 (arm64)**: `onefinity-X.X.X-rpi5-arm64.img.xz` - For Raspberry Pi 5

### Flashing the Image

#### On Linux

1. **Download the Image**
   
   ```bash
   wget https://github.com/eisenhowerj/onefinity-firmware/releases/download/vX.X.X/onefinity-X.X.X-rpi5-arm64.img.xz
   ```

2. **Identify the SD Card Device**
   
   Insert the SD card and identify the device:
   ```bash
   lsblk
   ```
   
   Look for your SD card (e.g., `/dev/sdX` or `/dev/mmcblkX`).
   
   **⚠️ WARNING**: Make sure you identify the correct device. Writing to the wrong device will destroy data!

3. **Flash the Image**
   
   ```bash
   xz -d -c onefinity-X.X.X-rpi5-arm64.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   
   Replace `/dev/sdX` with your SD card device.

4. **Sync and Eject**
   
   ```bash
   sudo sync
   sudo eject /dev/sdX
   ```

#### On macOS

1. **Download the Image**
   
   Download from the releases page or use curl:
   ```bash
   curl -L -o onefinity.img.xz https://github.com/eisenhowerj/onefinity-firmware/releases/download/vX.X.X/onefinity-X.X.X-rpi5-arm64.img.xz
   ```

2. **Identify the SD Card**
   
   ```bash
   diskutil list
   ```
   
   Look for your SD card (e.g., `/dev/diskX`).

3. **Unmount the SD Card**
   
   ```bash
   diskutil unmountDisk /dev/diskX
   ```

4. **Flash the Image**
   
   ```bash
   xz -d -c onefinity.img.xz | sudo dd of=/dev/rdiskX bs=4m
   ```
   
   Note: Use `rdiskX` (raw disk) for faster writes.

5. **Eject**
   
   ```bash
   sudo diskutil eject /dev/diskX
   ```

#### On Windows

Use **Raspberry Pi Imager** (recommended) or **balenaEtcher**:

1. **Download and Install Raspberry Pi Imager**
   
   Download from: https://www.raspberrypi.com/software/

2. **Launch Raspberry Pi Imager**

3. **Choose Custom Image**
   
   - Click "CHOOSE OS"
   - Select "Use custom"
   - Browse to your downloaded `.img.xz` file

4. **Choose SD Card**
   
   - Click "CHOOSE STORAGE"
   - Select your SD card

5. **Write**
   
   - Click "WRITE"
   - Wait for completion

### First Boot

1. **Insert the SD Card**
   
   Insert the flashed SD card into your Raspberry Pi.

2. **Connect Network**
   
   Connect an Ethernet cable. (WiFi can be configured after first boot)

3. **Power On**
   
   Connect power to boot the Raspberry Pi.

4. **Wait for Boot**
   
   First boot may take 2-3 minutes while the system initializes.

5. **Access the Interface**
   
   Open a browser and navigate to:
   ```
   http://onefinity.local
   ```
   
   Or find the IP address using your router's admin interface.

### Default Credentials

**SSH Access:**
- Username: `pi` (or `bbmc` depending on base image)
- Password: `buildbotics` or `onefinity`

**Web Interface:**
- Default admin password: `onefinity`

**⚠️ IMPORTANT**: Change the default passwords immediately after first login!

## Post-Deployment Configuration

### Network Configuration

#### WiFi Setup

1. **Via SSH**
   
   ```bash
   sudo /opt/onefinity/bin/config-wifi
   ```
   
   Follow the prompts to configure WiFi.

2. **Via Configuration File**
   
   Edit `/etc/wpa_supplicant/wpa_supplicant.conf`:
   ```bash
   sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
   ```
   
   Add your network:
   ```
   network={
       ssid="YourNetworkName"
       psk="YourPassword"
   }
   ```

#### Static IP Address

Edit `/etc/dhcpcd.conf`:
```bash
sudo nano /etc/dhcpcd.conf
```

Add configuration for your interface:
```
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
```

Restart networking:
```bash
sudo systemctl restart dhcpcd
```

### Hostname Change

To change the hostname from `onefinity` to something else:

```bash
sudo hostnamectl set-hostname new-hostname
sudo nano /etc/hosts  # Update 127.0.1.1 line
sudo reboot
```

### Firewall Configuration

If you need to enable firewall:

```bash
sudo apt install ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw enable
```

## Monitoring and Maintenance

### Service Management

**Check status:**
```bash
sudo systemctl status onefinity
```

**Start/Stop/Restart:**
```bash
sudo systemctl start onefinity
sudo systemctl stop onefinity
sudo systemctl restart onefinity
```

**Enable/Disable auto-start:**
```bash
sudo systemctl enable onefinity
sudo systemctl disable onefinity
```

### Log Files

**System logs:**
```bash
sudo journalctl -u onefinity -f
```

**Application logs:**
```bash
sudo tail -f /var/log/onefinity/*.log
```

### Backup and Restore

**Backup configuration:**
```bash
sudo tar -czf onefinity-backup-$(date +%Y%m%d).tar.gz \
    /var/lib/onefinity \
    /etc/onefinity
```

**Restore configuration:**
```bash
sudo systemctl stop onefinity
sudo tar -xzf onefinity-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start onefinity
```

## Troubleshooting

### Service Won't Start

1. Check logs:
   ```bash
   sudo journalctl -u onefinity -n 50
   ```

2. Verify dependencies:
   ```bash
   sudo apt install -f
   ```

3. Check configuration:
   ```bash
   sudo /opt/onefinity/bin/edit-config
   ```

### Cannot Access Web Interface

1. Verify service is running:
   ```bash
   sudo systemctl status onefinity
   ```

2. Check network connectivity:
   ```bash
   ping onefinity.local
   ```

3. Check firewall:
   ```bash
   sudo ufw status
   ```

### AVR Firmware Issues

Reflash the AVR firmware:
```bash
sudo /opt/onefinity/bin/avr109-flash.py /opt/onefinity/firmware/bbctrl-avr-firmware.hex
```

### GPIO Issues

Ensure lgpio is installed:
```bash
sudo apt install python3-lgpio libgpiod-tools
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/eisenhowerj/onefinity-firmware/issues
- Documentation: https://github.com/eisenhowerj/onefinity-firmware/tree/main/docs

## Version Information

Check installed version:
```bash
dpkg -l | grep onefinity-firmware
```

Or via the web interface: Settings → About

## Security Considerations

1. **Change Default Passwords**: Immediately change all default passwords
2. **Network Security**: Consider running on an isolated network
3. **Regular Updates**: Keep the system and firmware updated
4. **SSH Key Authentication**: Disable password authentication for SSH
5. **Firewall**: Enable and configure UFW or iptables

## Advanced Configuration

### Custom Service Configuration

Edit the systemd service file:
```bash
sudo systemctl edit onefinity
```

### Environment Variables

Add environment variables in `/etc/systemd/system/onefinity.service.d/override.conf`:
```
[Service]
Environment="CUSTOM_VAR=value"
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart onefinity
```
