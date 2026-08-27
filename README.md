This repo content installer, uninstaller and bootstrap scripts used in LinuxBox. If you are looking for the LinuxBox application, please visit [here](https://github.com/NextAppsLab/LinuxBox)

To open an issue, please visit [here](https://github.com/NextAppsLab/LinuxBox/issues)



## Bootstraping System

Note: Only [Ubuntu](https://www.ubuntu.com/), [Debian](https://www.debian.org/), [Kali](https://www.kali.org/) are supported currently, they are located at [Scripts/Bootstrap](https://github.com/NextAppsLab/LinuxBoxResources/tree/main/Scripts/Bootstrap).

You will need to install some package first:

> sudo apt-get install git ubuntu-keyring debian-archive-keyring qemu-user-static

Also you may want to install [kali-archive-keyring](https://http.kali.org/pool/main/k/kali-archive-keyring/) debian package manually to bootstrap Kali distro.

Then go to [Bootstrap](https://github.com/EXALAB/Anlinux-Resources/tree/master/Scripts/Bootstrap) and download the bootstrap.sh script. (It is important to follow instructions before running bootstrap.sh if there any.)

To bootstrap a system, simply run:

> sudo ./bootstrap.sh