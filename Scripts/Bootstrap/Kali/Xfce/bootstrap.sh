#!/usr/bin/env bash

#Bootstrap the system
rm -rf arm64
mkdir arm64
debootstrap --arch=arm64 --variant=minbase --include=systemd,libsystemd0,wget,ca-certificates,busybox-static,gnupg kali-rolling arm64 http://kali.download/kali

#Reduce size
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot arm64 apt clean

#Fix permission on dev machine only for easy packing
chmod 777 -R arm64

#This step is only needed for Ubuntu to prevent Group error
touch arm64/root/.hushlogin

#Setup DNS
echo "127.0.0.1 localhost" > arm64/etc/hosts
echo "nameserver 8.8.8.8" > arm64/etc/resolv.conf
echo "nameserver 8.8.4.4" >> arm64/etc/resolv.conf

#sources.list setup
rm arm64/etc/apt/sources.list
rm arm64/etc/hostname
echo "LinuxBox-Kali-Xfce" > arm64/etc/hostname
echo "deb https://kali.download/kali kali-rolling main contrib non-free" >> arm64/etc/apt/sources.list
echo "deb-src https://kali.download/kali kali-rolling main contrib non-free" >> arm64/etc/apt/sources.list

#Import the gpg key, this is only required in Kali
chroot arm64 wget http://archive.kali.org/archive-key.asc -O /etc/apt/trusted.gpg.d/kali-archive-key.asc

mkdir -p arm64/root/.config/tigervnc/
cp xstartup arm64/root/.config/tigervnc/
cp linuxbox-start arm64/usr/local/bin/
cp vncserver-stop arm64/usr/local/bin/
chroot arm64 chmod +x /root/.config/tigervnc/xstartup
chroot arm64 chmod +x /usr/local/bin/linuxbox-start
chroot arm64 chmod +x /usr/local/bin/vncserver-stop

mount -t proc proc arm64/proc
mount --rbind /dev arm64/dev
mount --rbind /sys arm64/sys
mount --rbind /run arm64/run

#setup custom packages
chroot arm64 apt update
chroot arm64 apt upgrade -y
chroot arm64 apt dist-upgrade -y
chroot arm64 apt install kali-linux-core kali-tools-top10 kali-desktop-xfce xfce4-goodies xfce4-terminal firefox-esr xorg tigervnc-standalone-server dbus-x11 gvfs-daemons udisks2 -y

#Quality of life package
chroot arm64 apt install sudo nano vim-tiny wget curl git zip unzip p7zip-full xz-utils htop fastfetch file tree less -y

umount -R arm64/run
umount -R arm64/sys
umount -R arm64/dev
umount arm64/proc

#Necessary step to renable Firefox on Kali
chroot arm64 /bin/bash -c 'echo "export MOZ_DISABLE_CONTENT_SANDBOX=1" >> /etc/profile'

chroot arm64 apt clean
chroot arm64 apt autoremove -y
chroot arm64 /bin/bash -c 'echo "export DISPLAY=:1" >> /etc/profile'
rm -rf arm64/var/lib/apt/lists/*

#tar the rootfs
cd arm64
rm -rf ../kali-xfce-rootfs.tar.xz
rm -rf dev/*
XZ_OPT=-9 tar -cJvf ../kali-xfce-rootfs.tar.xz ./*
