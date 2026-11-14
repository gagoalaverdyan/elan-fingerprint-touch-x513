#!/usr/bin/env bash
# Restore the ELAN press-mode fingerprint driver on a fresh Fedora install.
# ASUS VivoBook X513EQ (ELAN7001 / 04f3:3104, sensor eFSA80SC).
# Run with: sudo ./install.sh
set -eu
if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo." >&2
  exit 1
fi
kit="$(cd "$(dirname "$0")" && pwd)"
dest=/opt/libfprint-elan/lib64

# fprintd + the OpenCV runtime libraries the driver links against (SIGFM matcher)
dnf -y install fprintd fprintd-pam opencv-core opencv-imgproc opencv-features2d opencv-flann

# 1. driver library, loaded only by fprintd (Fedora's libfprint stays untouched)
mkdir -p "$dest"
install -o root -g root -m 755 "$kit/lib/libfprint-2.so.2.0.0" "$dest/"
ln -sf libfprint-2.so.2.0.0 "$dest/libfprint-2.so.2"
ln -sf libfprint-2.so.2 "$dest/libfprint-2.so"

# 2. make fprintd use it
mkdir -p /etc/systemd/system/fprintd.service.d
install -o root -g root -m 644 "$kit/config/fprintd-elan.conf" /etc/systemd/system/fprintd.service.d/elan.conf

# 3. larger SPI buffer for the sensor frames
install -o root -g root -m 644 "$kit/config/spidev-elan.conf" /etc/modprobe.d/spidev-elan.conf

# SELinux labels (a wrong label makes fprintd silently fall back to Fedora's libfprint)
restorecon -Rv /opt/libfprint-elan /etc/systemd/system/fprintd.service.d /etc/modprobe.d/spidev-elan.conf

systemctl daemon-reload
systemctl restart fprintd

# missing system libraries mean this prebuilt copy does not fit this Fedora release
if LD_LIBRARY_PATH="$dest" ldd /usr/libexec/fprintd | grep -q 'not found'; then
  echo
  echo "WARNING: the prebuilt library is missing dependencies on this system."
  echo "Rebuild it from source/ (see README.md)."
  LD_LIBRARY_PATH="$dest" ldd /usr/libexec/fprintd | grep 'not found'
  exit 1
fi

echo
echo "Installed. REBOOT once so the SPI buffer setting takes effect, then check:"
echo "  cat /sys/module/spidev/parameters/bufsiz     (should be 32768)"
echo "  fprintd-list \$USER                           (should say '(press)')"
echo "Then enroll:  fprintd-enroll -f right-index-finger   (15 natural touches)"
echo "Optional login: sudo authselect enable-feature with-fingerprint"
