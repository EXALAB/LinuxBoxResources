#!/data/data/com.termux/files/usr/bin/bash
folder=ubuntu-kde-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="ubuntu-kde-rootfs.tar.xz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "Download Rootfs, this may take a while base on your internet speed."
		wget --show-progress "https://github.com/NextAppsLab/LinuxBoxResources/releases/download/Test-Release/ubuntu-kde-rootfs.tar.xz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs, please be patient."
	proot --link2symlink tar -xJf ${cur}/${tarball}||:
	cd "$cur"
fi
mkdir -p ubuntu-binds
bin=start-ubuntu-kde.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
pulseaudio --start
## For rooted user: pulseaudio --start --system
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A ubuntu-binds)" ]; then
    for f in ubuntu-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b ubuntu-kde-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login -c /usr/local/bin/vncserver-start &"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "Setting up pulseaudio so you can have music in distro."

pkg install pulseaudio -y

if grep -q "anonymous" ~/../usr/etc/pulse/default.pa;then
    echo "module already present"
else
    echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> ~/../usr/etc/pulse/default.pa
fi

echo "exit-idle-time = -1" >> ~/../usr/etc/pulse/daemon.conf
echo "Modified pulseaudio timeout to infinite"
echo "autospawn = no" >> ~/../usr/etc/pulse/client.conf
echo "Disabled pulseaudio autospawn"
echo "export PULSE_SERVER=127.0.0.1" >> ubuntu-kde-fs/etc/profile
echo "Setting Pulseaudio server to 127.0.0.1"

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball
echo "You can now launch Ubuntu with the ./${bin} script"
