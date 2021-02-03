#!/usr/bin/env bash
set -e


## All Variable ##

hard="/dev/sda"
Bios_Type="bios"         ## (uefi - bios) 
Boot_Partiton=""     ## For uefi ##
Root_Partiton="/dev/sda1"
## Home_Partiton=""
Swap_Partiton="/dev/sda2"
Timezone="Africa/Cairo"
Desktop_GUI="gnome"  ## (gnome - kde - xfce - mate - cinnamon - lxde - i3-wm - i3-gaps - dwm)
User_Name="tarek"


## All Variable ##


if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "uefi" ]; then
       [-z $Boot_Partiton ] || mkfs.fat -n ESP -F32 $Boot_Partiton
fi
if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "bios" ]; then
        [-z $Boot_Partiton ] || mkfs.ext4 -L boot $Boot_Partiton
fi

mkfs.ext4 $Root_Partiton

mkswap $Swap_Partiton

# pacman -S reflector

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

mount $Root_Partiton /mnt

swapon $Swap_Partiton

pacstrap /mnt base base-devel linux linux-firmware vim nano net-tools


## pacstrap /mnt base base-devel linux linux-firmware vim nano

genfstab -U /mnt >> /mnt/etc/fstab



arch-chroot /mnt timedatectl set-timezone $Timezone


arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

arch-chroot /mnt  locale-gen

arch-chroot /mnt  echo LANG=en_US.UTF-8 > /etc/locale.conf

#arch-chroot /mnt  export LANG=en_US.UTF-8



arch-chroot /mnt passwd

arch-chroot /mnt useradd -m -G wheel,storage,optical,audio,video,root -s /bin/bash $User_Name

arch-chroot /mnt passwd $User_Name



arch-chroot /mnt pacman -Syu --noconfirm --needed sudo wget git dhcpcd

arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers






## MY install Grub ##

if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "bios" ]; then

	arch-chroot /mnt pacman -Syu --noconfirm --needed  grub

	arch-chroot /mnt grub-install $hard

	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi
if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "uefi" ]; then

	arch-chroot /mnt pacman -Syu --noconfirm --needed grub efibootmgr
	arch-chroot /mnt  mkdir /boot/efi
	arch-chroot /mnt  mount $Boot_Partiton /boot/efi
	arch-chroot /mnt  grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
	arch-chroot /mnt  grub-mkconfig -o /boot/grub/grub.cfg


fi


## MY install Grub ##


##  Desktop Environment ##

## (gnome - kde - xfce - mate - cinnamon - lxde - i3-wm - i3-gaps - dwm - deepin)

#case $(echo "$Desktop_GUI" |tr [:upper:] [:lower:]) in
#	"gnome" )
#	
#	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg xorg-server
#	arch-chroot /mnt pacman -Syu --noconfirm --needed gnome
#	arch-chroot /mnt systemctl start gdm.service
#	arch-chroot /mnt systemctl enable gdm.service
#	arch-chroot /mnt systemctl enable NetworkManager.service
#	
#	;;
#	"kde" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed plasma-meta plasma-wayland-session kde-applications-meta
#	arch-chroot /mnt systemctl enable sddm.service
#
#	;;
#	"xfce" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xorg-server
#	arch-chroot /mnt systemctl enable lightdm.service
#	
#	;;
#	"mate" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed mate mate-extra lightdm lightdm-gtk-greeter xorg-server
#	arch-chroot /mnt systemctl enable lightdm.service
#
#	;;
#	"cinnamon" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed cinnamon lightdm lightdm-gtk-greeter xorg-server
#	arch-chroot /mnt systemctl enable lightdm.service
#
#	;;
#	"lxde" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed lxde lxdm
#	arch-chroot /mnt systemctl enable lxdm.service
#
#	;;
#	"i3-wm" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-wm i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
#	arch-chroot /mnt systemctl enable lightdm.service
#
#	;;
#	"i3-gaps" )
#	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
#	arch-chroot /mnt systemctl enable lightdm.service
#
#	;;
#	"dwm" )
#
#
#
#	;;
#	"deepin" )
#
#
#
#	;;
#	*)
#

#	;;
#	esac

#arch-chroot /mnt systemctl set-default graphical.target


clear

echo "install Arch linux is successfully"
sleep 5

exit
