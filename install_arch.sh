#!/bin/bash -x
set -e


## All Variable ##

hard="/dev/sda"
Bios_Type="bios"         ## (uefi - bios) 
Boot_Partiton=""     ## For uefi ##
Root_Partiton="/dev/sda1"
Home_Partiton=""
Swap_Partiton="/dev/sda2"
Timezone="Africa/Cairo"
Desktop_GUI="dwm"  ## (gnome - kde - xfce - mate - cinnamon - lxde - i3-wm - i3-gaps - dwm)
User_Name="tarek"

wifi_name=""
wifi_pass=""

## All Variable ##
## wifi ##

if [ ! -z $wifi_name ] && [ ! -z $wifi_pass] ;then
    wpa_passphrase $wifi_name $wifi_pass > ./my-wifi.conf
    wpa_supplicant -B -i wlan0 -c ./my-wifi.conf
    
    # wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)
    dhcp
fi


## wifi ##

if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "uefi" ]; then
       [ ! -z $Boot_Partiton ] && mkfs.fat -n ESP -F32 $Boot_Partiton
fi
if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "bios" ]; then
        [ ! -z $Boot_Partiton ] && mkfs.ext4 -L boot $Boot_Partiton
fi

## [ -z $Home_Partiton ] && mkdir /mnt/home

mkfs.ext4 $Root_Partiton

## [ -z $Home_Partiton ] && mkfs.ext4 $Home_Partiton

mkswap $Swap_Partiton

# pacman -S reflector

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak


mount $Root_Partiton /mnt


if [ ! -z $Home_Partiton ];then
	makdir /mnt/home
	mkfs.ext4 $Home_Partiton
	mount $Home_Partiton /mnt/home
fi


## [ -z $Home_Partiton ] && mount $Home_Partiton /mnt/home

swapon $Swap_Partiton

pacstrap /mnt base base-devel linux linux-firmware vim nano net-tools


## pacstrap /mnt base base-devel linux linux-firmware vim nano

genfstab -U /mnt >> /mnt/etc/fstab


arch-chroot /mnt timedatectl set-timezone $Timezone


arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

arch-chroot /mnt  locale-gen

arch-chroot /mnt  echo LANG=en_US.UTF-8 > /etc/locale.conf

#arch-chroot /mnt  export LANG=en_US.UTF-8


arch-chroot /mnt ln -s /usr/share/zoneinfo/$Timezone /etc/localtime


clear

echo "Enter Password For Root :"

arch-chroot /mnt passwd

arch-chroot /mnt useradd -m -G wheel,storage,optical,audio,video,root -s /bin/bash $User_Name

echo "Enter Password For $User_Name : "

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

case $(echo "$Desktop_GUI" |tr [:upper:] [:lower:]) in
	"gnome" )
	
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg xorg-server
	arch-chroot /mnt pacman -Syu --noconfirm --needed gnome gdm
	sleep 3
	arch-chroot /mnt systemctl start gdm.service
	sleep 3
	arch-chroot /mnt systemctl enable gdm.service
	sleep 3
	arch-chroot /mnt systemctl enable NetworkManager.service
	
	;;
	"kde" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg plasma plasma-meta plasma-wayland-session kde-applications-meta sddm
	arch-chroot /mnt systemctl enable sddm.service
	arch-chroot /mnt systemctl enable NetworkManager.service

	;;
	"xfce" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt systemctl enable NetworkManager.service
	
	## xfce4 mousepad parole ristretto thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-datetime-plugin xfce4-mount-plugin xfce4-netload-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-taskmanager xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin file-roller network-manager-applet leafpad epdfview galculator lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings capitaine-cursors arc-gtk-theme xdg-user-dirs-gtk ##
	
	
	;;
	"mate" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed mate mate-extra lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt systemctl enable NetworkManager.service

	;;
	"cinnamon" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed cinnamon lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt systemctl enable NetworkManager.service

	;;
	"lxde" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed lxde lxdm
	arch-chroot /mnt systemctl enable lxdm.service

	;;
	"i3-wm" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-wm i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service

	;;
	"i3-gaps" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service

	;;
	"dwm" )
	arch-chroot /mnt pacman -Syu --noconfirm --needed base-devel libx11 libxft xorg-server xorg-xinit xorg-xrandr xorg-xsetroot
	arch-chroot /mnt mkdir /home/$User_Name/.config
	arch-chroot /mnt mkdir /home/$User_Name/.config/dwm
	arch-chroot /mnt mkdir /home/$User_Name/.config/st
	arch-chroot /mnt mkdir /home/$User_Name/.config/dmenu
	
	arch-chroot /mnt git clone git://git.suckless.org/dwm /home/$User_Name/.config/dwm
	arch-chroot /mnt git clone git://git.suckless.org/st /home/$User_Name/.config/st
	arch-chroot /mnt git clone git://git.suckless.org/dmenu /home/$User_Name/.config/dmenu
	arch-chroot /mnt cd /home/$User_Name/.config/dwm && make clean install
	sleep 2
	arch-chroot /mnt cd /home/$User_Name/.config/st && make clean install
	sleep 2
	arch-chroot /mnt cd /home/$User_Name/.config/dmenu && make clean install
	sleep 2
	
	arch-chroot /mnt pacman -Syu --noconfirm --needed lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
	sleep 3
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt mkdir /usr/share/xsessions
	arch-chroot /mnt echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Dwm\nComment=Dynamic window manager\nExec=dwm\nIcon=dwm\nType=XSession" > /usr/share/xsessions/dwm.desktop
	arch-chroot /mnt echo -e "[Desktop]\nSession=dwm > /home/$User_Name/.dmrc
	
	
	## APPS ##
	# arch-chroot /mnt pacman -Syu --noconfirm --needed ttf-font-awesome alsa-utils firefox nitrogen htop ntfs-3g vlc sxhkd 

	;;
	"deepin" )



	;;
	*)


	;;
	esac




clear

echo "install Arch linux is successfully"
sleep 5

exit






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
