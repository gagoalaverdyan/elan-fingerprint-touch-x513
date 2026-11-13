# ELAN fingerprint driver (press mode) for ASUS VivoBook X513EQ

This is a patched libfprint for the ELAN SPI fingerprint reader in the ASUS VivoBook X513EQ / X513EQN (ACPI `ELAN7001`, HID `04f3:3104`, sensor eFSA80SC, 80x80).

**It is touch-based, not swipe-based.** The widely shared Linux drivers for this reader treat it as a swipe sensor, so you have to drag your finger across it. The hardware is actually a small square touch sensor. With this driver you place your finger and hold it still for about a second, as on a phone or a MacBook.

It has been tested on Fedora 45 with fprintd 1.94.5.

## Install

```
git clone https://github.com/gagoalaverdyan/elan-fingerprint-touch-x513.git
cd elan-fingerprint-touch-x513
sudo ./install.sh
sudo reboot
```

After rebooting, enroll a finger. Enrollment asks for 15 touches, which is more than usual. The sensor is only about 4x4 mm, so each touch records a small patch of your fingertip. Fifteen patches cover more of the finger, which makes later touches more likely to be recognised on the first try. Place your finger naturally each time; you don't need to move it around on purpose.

```
fprintd-enroll -f right-index-finger
```

If you also want to log in with your fingerprint:

```
sudo authselect enable-feature with-fingerprint
```

## Uninstall

```
sudo rm -r /opt/libfprint-elan /etc/systemd/system/fprintd.service.d/elan.conf /etc/modprobe.d/spidev-elan.conf
sudo systemctl daemon-reload
sudo systemctl restart fprintd
```

## Building from source

`lib/` contains a prebuilt library. If `install.sh` reports missing dependencies on your system, build it yourself:

```
git clone https://github.com/goodix-fp-linux-dev/libfprint.git && cd libfprint
git checkout $(cat ../source/UPSTREAM_COMMIT)
git apply ../source/elanspi-press-mode.patch
sudo dnf builddep libfprint && sudo dnf install opencv-devel doctest-devel
meson setup build --prefix=/opt/libfprint-elan --libdir=lib64 && ninja -C build
cp build/libfprint/libfprint-2.so.2.0.0 ../lib/
```

## License

LGPL-2.1-or-later, the same license as libfprint (see `LICENSE`). The source changes are in `source/elanspi-press-mode.patch`, which applies to the upstream commit listed in `source/UPSTREAM_COMMIT`.

This is unofficial and comes with no warranty. Keep a password login available.
