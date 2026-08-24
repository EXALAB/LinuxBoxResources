#!/data/data/com.termux/files/usr/bin/bash

folder="ubuntu-kde-fs"
marker=".linuxbox-installed"
tarball="ubuntu-kde-rootfs.tar.xz"
download_tmp="${tarball}.tmp"

# Check installation status
if [ -f "$marker" ]; then
    echo "Ubuntu KDE is already installed."
    exit 0
fi

echo "Installing Ubuntu KDE..."

# Download rootfs if needed
if [ ! -f "$tarball" ]; then
    echo "Download Rootfs, this may take a while based on your internet speed."

    rm -f "$download_tmp"

    wget --show-progress \
    "https://github.com/NextAppsLab/LinuxBoxResources/releases/download/Test-Release/ubuntu-kde-rootfs.tar.xz" \
    -O "$download_tmp"

    if [ $? -ne 0 ]; then
        echo "Download failed."
        rm -f "$download_tmp"
        exit 1
    fi

    mv "$download_tmp" "$tarball"
fi

# Extract rootfs safely
echo "Decompressing Rootfs, please be patient."

temp_folder="${folder}.tmp"

rm -rf "$temp_folder"

mkdir -p "$temp_folder"

cur=$(pwd)

cd "$temp_folder" || exit 1

proot --link2symlink tar -xJf "${cur}/${tarball}"

if [ $? -ne 0 ]; then
    echo "Extraction failed."
    cd "$cur"
    rm -rf "$temp_folder"
    exit 1
fi

cd "$cur"

rm -rf "$folder"

mv "$temp_folder" "$folder"


# Create bind folder
mkdir -p ubuntu-binds


# Generate launcher
bin="start-ubuntu-kde.sh"

echo "Writing launch script"

cat > "$bin" << EOM
#!/bin/bash

cd \$(dirname \$0)

pulseaudio --start

## For rooted user:
## pulseaudio --start --system
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
command+=" -b $folder/root:/dev/shm"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"

com="\$@"

if [ -z "\$1" ]; then
    exec \$command
else
    exec \$command -c "\$com"
fi
EOM

echo "Setting up pulseaudio"

pkg install pulseaudio -y

pulse_config="$HOME/../usr/etc/pulse/default.pa"

if ! grep -q "module-native-protocol-tcp auth-ip-acl=127.0.0.1" "$pulse_config"; then
    echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> "$pulse_config"
fi

daemon_config="$HOME/../usr/etc/pulse/daemon.conf"

if ! grep -qx "exit-idle-time = -1" "$daemon_config"; then
    echo "exit-idle-time = -1" >> "$daemon_config"
fi

client_config="$HOME/../usr/etc/pulse/client.conf"

if ! grep -qx "autospawn = no" "$client_config"; then
    echo "autospawn = no" >> "$client_config"
fi

echo "export PULSE_SERVER=127.0.0.1" >> "$folder/etc/profile"

echo "Fixing shebang"
termux-fix-shebang "$bin"
chmod +x "$bin"

# Installation completed
touch "$marker"
rm -f $tarball

echo ""
echo "Ubuntu KDE installation completed."
echo "You can launch Ubuntu with:"
echo "./$bin"