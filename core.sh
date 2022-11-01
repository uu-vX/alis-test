#!/usr/bin/env bash

preparation ()  {
#	Enable paralel downloads 
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
#	Enable multilib
sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /etc/pacman.conf
pacman -Syy
}

kernel="linux-lts"
kernel_headers="linux-lts-headers"

#issues+=( "...         ISSUES           ..." )
#issues+=( "The filesystem must be selectable." )
#issues+=( "The kernel type must be selectable." )
essential () { # 
pacstrap /mnt base base-devel linux-firmware "$kernel" "$kernel_headers" intel-ucode vim
echo -e "\n"
echo "Pacstrap base system complete..."
genfstab -U /mnt >> /mnt/etc/fstab
}

requirements () {
pacman -S --noconfirm --needed git reflector rsync
pacman -S --noconfirm --needed gvfs ntfs-3g
}

#issues+=( "How to find timezone automatically or Zoneinfo must be manually enterable." )
sys_zone () {
arch-chroot /mnt hwclock --systohc --utc
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt rm -rf /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime
}

#issues+=( "Keyboard layout must be selectable." )
sys_locale () {
LCLST="en_US" #Locale
KEYMP="us"
arch-chroot /mnt localectl set-locale LANG="${LCLST}".UTF-8
arch-chroot /mnt localectl set-keymap "${KEYMP}"
sed -i 's/#"${LCLST}".UTF-8 UTF-8/"${LCLST}".UTF-8 UTF-8/g' /etc/locale.gen
arch-chroot /mnt locale-gen
}

#issues+=( "Hostname must be manually enterable." )
sys_host () {
HSTNAME="arch"
echo ""${HSTNAME}"" > /mnt/etc/hostname
echo "127.0.0.1          localhost" >> /mnt/etc/hosts
echo "::1          localhost" >> /mnt/etc/hosts
echo "127.0.1.1          "${HSTNAME}".localdomain "${HSTNAME}"" >> /mnt/etc/hosts
clear
}


#issues+=( "Bootloader directory path must be from filesystem boot partition." )
bootloader () {
pacman -S --noconfirm --needed grub efibootmgr os-prober
boot_directory="/boot/efi"
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="${boot_directory}" --bootloader-id=GRUB --recheck 
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

#issues+=( "Search for the most suitable available network packages." )
network ()  {
pacman -S --noconfirm --needed networkmanager
services="NetworkManager.service"
systemctl enable ${services} && systemctl start ${services}
}

#issues+=( "Set nvidia modules depend on the linux kernel package." )
gpu () {
pacman -S --noconfirm --needed xf86-video-intel lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader
mkinitcpioModules+=" i915 "
pacman -S --noconfirm --needed nvidia-lts nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
	#MODULES=(btrfs i915 nvidia)
mkinitcpioModules+=" nvidia-lts nvidia-modeset nvidia-uvm nvidia-drm"
    # nvidia modules linked to nvidia linux kernel
sed -i "s/^MODULES=()/MODULES=(${mkinitcpioModules})/" /etc/mkinitcpio.conf
}

#issues+=( "-------------------------------------------------------!Read user input for username, userpassword, rootpassword." )
sys_user () {
    read -r USRNAME
    read -r -s USRPWD
    #read -r -s RTPWD
USRNAME # read from user
USRPWD  # read from user
#RTPWD   # Ask to use the same user password as the root password
        ${USRPWD}=RTPWD
USRMD="" # usermod
pacman -S --noconfirm sudo
arch-chroot /mnt useradd -mU -s /bin/bash -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm "${USRNAME}"
arch-chroot /mnt chpasswd <<< ""${USRNAME}":"${USRPWD}""
arch-chroot /mnt chpasswd <<< "root:"${RTPWD}""
usermod -c ‘${USRMD}’ "${USRNAME}" #You can see your name in login prompt
}

#issues+=( "Set to mkinitcpio related kernel." )
chroot () {
arch-chroot /mnt mkinitcpio -p "$kernel"
}

#	Audio packages
audio () {
pacman -S --noconfirm --needed alsa-utils pulseaudio-alsa pulseaudio pulseaudio-lirc pulseaudio-jack pamixer
#services="  .service" 
#systemctl enable ${services} && systemctl start ${services}
}

#   Bluetooth
bluetooth () {
pacman -S --noconfirm --needed pulseaudio-bluetooth bluez bluez-utils 
services="bluetooth.service"
systemctl enable ${services} && systemctl start ${services}
}

until preparation; do : ; done
until essential; do : ; done
until requirements; do : ; done

until sys_zone; do : ; done
until sys_locale; do : ; done
until sys_user; do : ; done
until sys_host; do : ; done

until bootloader; do : ; done

until gpu; do : ; done
until chroot; do : ; done

until network; do : ; done

until audio; do : ; done
until bluetooth; do : ; done

#acpi_call
