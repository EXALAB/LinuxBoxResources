#!/usr/bin/env bash

#Bootstrap the system
rm -rf arm64
mkdir arm64
debootstrap --arch=arm64 --variant=minbase --include=systemd,libsystemd0,wget,ca-certificates,busybox-static trixie arm64 http://deb.debian.org/debian

#Reduce size
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot arm64 apt clean

#Fix permission on dev machine only for easy packing
chmod 777 -R arm64

#Setup DNS
echo "127.0.0.1 localhost" > arm64/etc/hosts
echo "nameserver 8.8.8.8" > arm64/etc/resolv.conf
echo "nameserver 8.8.4.4" >> arm64/etc/resolv.conf

#sources.list setup
rm arm64/etc/apt/sources.list
rm arm64/etc/hostname
echo "LinuxBox-Debian-Xfce" > arm64/etc/hostname
echo "deb https://deb.debian.org/debian trixie main contrib non-free" >> arm64/etc/apt/sources.list
echo "deb https://security.debian.org/debian-security trixie-security main contrib non-free" >> arm64/etc/apt/sources.list
echo "deb https://deb.debian.org/debian trixie-updates main contrib non-free" >> arm64/etc/apt/sources.list
echo "deb https://deb.debian.org/debian trixie-backports main contrib non-free" >> arm64/etc/apt/sources.list
echo "deb-src https://deb.debian.org/debian trixie main contrib non-free" >> arm64/etc/apt/sources.list

mkdir -p arm64/root/.vnc/
mkdir -p arm64/root/.config/tigervnc/
cp xstartup arm64/root/.vnc/
cp xstartup arm64/root/.config/tigervnc/
cp linuxbox-start arm64/usr/local/bin/
cp vncserver-stop arm64/usr/local/bin/
chroot arm64 chmod +x /root/.vnc/xstartup
chroot arm64 chmod +x /root/.config/tigervnc/xstartup
chroot arm64 chmod +x /usr/local/bin/linuxbox-start
chroot arm64 chmod +x /usr/local/bin/vncserver-stop

#Mount /proc to prevent package installation failure
mount -t proc proc arm64/proc

#setup custom packages
chroot arm64 apt update
chroot arm64 apt upgrade -y
chroot arm64 apt dist-upgrade -y
chroot arm64 apt install xorg xfce4 xfce4-terminal xfce4-goodies firefox-esr tigervnc-standalone-server dbus-x11 gvfs-daemons udisks2 -y

#Quality of life package
chroot arm64 apt install sudo nano vim-tiny wget curl git zip unzip p7zip-full xz-utils htop neofetch file tree less -y

#Package installation done, unmount /proc
umount arm64/proc

#Necessary step to renable Firefox on Debian
chroot arm64 /bin/bash -c 'echo "export MOZ_DISABLE_CONTENT_SANDBOX=1" >> /etc/profile'

chroot arm64 apt clean
chroot arm64 apt autoremove -y
chroot arm64 /bin/bash -c 'echo "export DISPLAY=:1" >> /etc/profile'
rm -rf arm64/var/lib/apt/lists/*

#tar the rootfs
cd arm64
rm -rf ../debian-xfce-rootfs.tar.xz
rm -rf dev/*
XZ_OPT=-9 tar -cJvf ../debian-xfce-rootfs.tar.xz ./*
