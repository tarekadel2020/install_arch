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
Desktop_GUI=""  ## (budgie - gnome - kde - xfce - mate - cinnamon - lxde - i3-wm - i3-gaps - dwm - openbox)
User_Name="tarek"

wifi_name=""
wifi_pass=""

## All Variable ##



Boot_partiton(){

	if [ ! -z $Boot_Partiton ]; then

		if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "uefi" ]; then
			mkfs.fat -n ESP -F32 $Boot_Partiton
		fi

		if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "bios" ]; then
			mkfs.ext4 -L boot $Boot_Partiton
		fi
	fi
}


Make_partitons(){
	mkfs.ext4 $Root_Partiton
	mkswap $Swap_Partiton
}


Home_partiton(){
	if [ ! -z $Home_Partiton ];then
	makdir /mnt/home
	mkfs.ext4 $Home_Partiton
	mount $Home_Partiton /mnt/home
	fi

}

Mount(){
	## sudo pacman -Syy
	## sudo pacman -S reflector
	## reflector --sort rate -l 5 --save /etc/pacman.d/mirrorlist
	## pacman -Syy
	## mkdir /mnt &>/dev/null                  # Hiding error message if any


	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	mount $Root_Partiton /mnt
	swapon $Swap_Partiton
	Home_partiton
}

Base(){
	pacstrap /mnt base base-devel linux linux-firmware vim nano net-tools
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt timedatectl set-timezone $Timezone
	arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	arch-chroot /mnt  locale-gen
	arch-chroot /mnt touch /etc/locale.conf
	echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
	arch-chroot /mnt touch /etc/hostname
	echo "arch" > /mnt/etc/hostname
	arch-chroot /mnt touch /etc/hosts
	echo -e "127.0.0.1	localhost\n::1	localhost\n127.0.1.1	arch.localdomain	arch" >> /mnt/etc/hosts
	arch-chroot /mnt ln -s /usr/share/zoneinfo/$Timezone /etc/localtime
	arch-chroot /mnt pacman -Syu --noconfirm --needed archlinux-keyring
}

Add_user(){
	clear
	echo "Enter Password For Root :"
	arch-chroot /mnt passwd
	arch-chroot /mnt useradd -m -G wheel,storage,optical,audio,video,root -s /bin/bash $User_Name
	echo "Enter Password For $User_Name : "
	arch-chroot /mnt passwd $User_Name
}

Wheel(){
	read -p "Are you want give all user sudo primmion ? [Y-N]" accept_base
	if [ $(echo "$accept_base" |tr [:upper:] [:lower:]) = "y" ]; then
		arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
	fi
}

App(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed sudo wget git dhcpcd networkmanager network-manager-applet wireless_tools wpa_supplicant ntfs-3g os-prober firefox
	arch-chroot /mnt systemctl enable NetworkManager
	arch-chroot /mnt pacman -Syu --noconfirm --needed ttf-font-awesome alsa-utils firefox ntfs-3g vlc man

}

Grub(){
	if [ $(echo "$Bios_Type" | tr [:upper:] [:lower:]) = "bios" ]; then

			arch-chroot /mnt pacman -Syu --noconfirm --needed  grub

			arch-chroot /mnt grub-install --target=i386-pc $hard
			
			arch-chroot /mnt sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
			
			## echo "GRUB_DISABLE_OS_PROBER=false" >> /mnt/etc/default/grub
			
			arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
		fi
		if [ $(echo "$Bios_Type" | tr [:upper:] [:lower:]) = "uefi" ]; then

			arch-chroot /mnt pacman -Syu --noconfirm --needed grub efibootmgr
			arch-chroot /mnt  mkdir /boot/efi
			arch-chroot /mnt  mount $Boot_Partiton /boot/efi
			arch-chroot /mnt  grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
			arch-chroot /mnt  grub-mkconfig -o /boot/grub/grub.cfg


		fi

}

Micorcode (){
echo -ne "
-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
	# determine processor type and install microcode
	proc_type=$(lscpu)
	if grep -E "GenuineIntel" <<< ${proc_type}; then
    		echo "Installing Intel microcode"
    		arch-chroot /mnt pacman -Syu --noconfirm intel-ucode
    		proc_ucode=intel-ucode.img
	elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    		echo "Installing AMD microcode"
    		arch-chroot /mnt pacman -Syu --noconfirm amd-ucode
    		proc_ucode=amd-ucode.img
    	else
    		echo "Your CPU Not Supported"
    		sleep 2
	fi

}

Ask_install_base(){
	read -p "Are you install base ? [Y-N]" accept_base
	if [ $(echo "$accept_base" |tr [:upper:] [:lower:]) = "y" ]; then
		Boot_partiton
		Make_partitons
		Mount
		Base
		Add_user
		Wheel
		App
		Micorcode
		Grub
	fi
}

GNOME(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg xorg-server
	arch-chroot /mnt pacman -Syu --noconfirm --needed gnome gdm
	sleep 3
	arch-chroot /mnt systemctl start gdm.service
	sleep 3
	arch-chroot /mnt systemctl enable gdm.service
	sleep 3
	arch-chroot /mnt systemctl enable NetworkManager.service				
}

KDE(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg plasma plasma-meta plasma-wayland-session kde-applications-meta sddm
	arch-chroot /mnt systemctl enable sddm.service
	arch-chroot /mnt systemctl enable NetworkManager.service
				
}

XFCE(){
	arch-chroot /mnt pacman -Syu --noconfirm --neede xfce4
	arch-chroot /mnt pacman -Syu --noconfirm --neede xfwm4 xfce4-panel xfdesktop thunar xfce4-session xfce4-settings xfce4-appfinder xfce-utils xfconf
	arch-chroot /mnt pacman -Syu --noconfirm --neede xfce4-goodies
	arch-chroot /mnt pacman -Syu --noconfirm --neede gstreamer0.10-base-plugins
	arch-chroot /mnt pacman -Syu --noconfirm --neede dbus
	arch-chroot /mnt pacman -Syu --noconfirm --neede lightdm lightdm-gtk-greeter
	arch-chroot /mnt systemctl enable lightdm.service
	
	
	## OLD ##
	
	#arch-chroot /mnt pacman -Syu --noconfirm --needed xfce4 xfce4-goodies lightdm lightdm-gtk-greeter xorg-server
	#arch-chroot /mnt systemctl enable lightdm.service
	#arch-chroot /mnt systemctl enable NetworkManager.service
	## APP
        #arch-chroot /mnt pacman -Syu --noconfirm --needed mousepad xfce4-screensaver xfce4-taskmanager xfce4-whiskermenu-plugin network-manager-applet epdfview alsa-utils pulseaudio
	## parole ristretto thunar-archive-plugin thunar-media-tags-plugin xfce4-battery-plugin xfce4-datetime-plugin xfce4-mount-plugin xfce4-netload-plugin xfce4-notifyd xfce4-pulseaudio-plugin xfce4-screensaver xfce4-taskmanager xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin file-roller network-manager-applet leafpad epdfview galculator lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings capitaine-cursors arc-gtk-theme xdg-user-dirs-gtk ##

}

MATE(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed mate mate-extra lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt systemctl enable NetworkManager.service
}

CINNAMON(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed cinnamon lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt systemctl enable NetworkManager.service				
}

LXDE(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed lxde lxdm
	arch-chroot /mnt systemctl enable lxdm.service			
}

I3-WM(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-wm i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service
}

I3-GAPS(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter xorg-server
	arch-chroot /mnt systemctl enable lightdm.service			
}

DWM(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed base-devel libx11 libxft xorg-server xorg-xinit xorg-xrandr xorg-xsetroot
	arch-chroot /mnt mkdir /home/$User_Name/.config
	chown 1000:1000 /mnt/home/$User_Name/.config
	arch-chroot /mnt mkdir /home/$User_Name/.config/dwm
	chown 1000:1000 /mnt/home/$User_Name/.config/dwm
	arch-chroot /mnt mkdir /home/$User_Name/.config/st
	chown 1000:1000 /mnt/home/$User_Name/.config/st
	arch-chroot /mnt mkdir /home/$User_Name/.config/dmenu
	chown 1000:1000 /mnt/home/$User_Name/.config/dmenu

	arch-chroot /mnt git clone git://git.suckless.org/dwm /home/$User_Name/.config/dwm
	arch-chroot /mnt git clone git://git.suckless.org/st /home/$User_Name/.config/st
	arch-chroot /mnt git clone git://git.suckless.org/dmenu /home/$User_Name/.config/dmenu
				
				
	#arch-chroot /mnt cd /home/$User_Name/.config/dwm && make clean install
	#sleep 2
	#arch-chroot /mnt cd /home/$User_Name/.config/st && make clean install
	#sleep 2
	#arch-chroot /mnt cd /home/$User_Name/.config/dmenu && make clean install
	#sleep 2



	arch-chroot /mnt pacman -Syu --noconfirm --needed lightdm lightdm-gtk-greeter  ## lightdm-gtk-greeter-settings
	sleep 3
	arch-chroot /mnt systemctl start lightdm.service
	sleep 3
	arch-chroot /mnt systemctl enable lightdm.service




	arch-chroot /mnt mkdir /usr/share/xsessions
	sleep 1
	arch-chroot /mnt touch /usr/share/xsessions/dwm.desktop
	sleep 2
	echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Dwm\nComment=Dynamic window manager\nExec=dwm\nIcon=dwm\nType=XSession" > /mnt/usr/share/xsessions/dwm.desktop
	sleep 2
	touch /mnt/home/$User_Name/.dmrc
	chown 1000:1000 /mnt/home/$User_Name/.dmrc
	echo -e "[Desktop]\nSession=dwm" > /mnt/home/$User_Name/.dmrc
				
				
	mkdir /mnt/home/$User_Name/.config/sxhkd
	chown 1000:1000 /mnt/home/$User_Name/.config/sxhkd
	touch /mnt/home/$User_Name/.config/sxhkd/sxhkdrc
	chown 1000:1000 /mnt/home/$User_Name/.config/sxhkd/sxhkdrc
	touch /mnt/home/$User_Name/.profile
	chown 1000:1000 /mnt/home/$User_Name/.profile
	echo -e "nitrogen --restore &\nsxhkd &" > /mnt/home/$User_Name/.profile
	## echo -e "dwm &\nnitrogen --restore &\nsxhkd" > /mnt/home/$User_Name/.profile
				
				

	## APPS ##
	arch-chroot /mnt pacman -Syu --noconfirm --needed ttf-font-awesome alsa-utils firefox nitrogen htop ntfs-3g vlc sxhkd thunar zathura zathura-pdf-poppler feh mypaint man

}
DEEPIN(){
	echo deepin
}

OPENBOX(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg-server lightdm lightdm-gtk-greeter
	arch-chroot /mnt pacman -Syu --noconfirm --needed openbox obconf  thunar firefox xfce4-terminal tint2 gmrun geany vlc qmmp nitrogen man 
	arch-chroot /mnt mkdir /home/$User_Name/.config/openbox
	chown 1000:1000 /mnt/home/$User_Name/.config/openbox
	arch-chroot /mnt systemctl start lightdm.service
	arch-chroot /mnt systemctl enable lightdm.service


	
	#touch /mnt/home/$User_Name/.dmrc
	#chown 1000:1000 /mnt/home/$User_Name/.dmrc
	#echo -e "[Desktop]\nSession=dwm" > /mnt/home/$User_Name/.dmrc
}

Budgie(){
	arch-chroot /mnt pacman -Syu --noconfirm --needed xorg-server xorg-apps xorg-xinit xterm lightdm lightdm-gtk-greeter
	arch-chroot /mnt systemctl start lightdm.service
	arch-chroot /mnt systemctl enable lightdm.service
	arch-chroot /mnt pacman -Syu --noconfirm --needed budgie-desktop budgie-desktop-viwe budgie-screensave nautilus gnome-control-center budgie-extras xfce4-terminal alsa-utils gedit dconf-editor
	clear
	read -p "Are you Want Budgi like windows 11 ? [Y-N]" accept_window
	if [ $accept_window == "y" ] || [ $accept_window == "Y" ] ; then
		Windows_11
	fi
}

Ask_install_Gui(){
	read -p "Are you install gui ? [Y-N]" accept_gui
	if [ $accept_gui == "y" ] || [ $accept_gui == "Y" ] ; then
		case $(echo "$Desktop_GUI" |tr [:upper:] [:lower:]) in
			"gnome")
				GNOME
			;;
			"kde" )
				KDE
			;;
			"xfce" )
				XFCE
			;;
			"mate" )
				MATE
			;;
			"cinnamon" )
				CINNAMON
			;;
			"lxde" )
				LXDE
			;;
			"i3-wm" )
				I3-WM
			;;
			"i3-gaps" )
				I3-GAPS
			;;
			"dwm")	
				DWM
			;;
			"deepin" )
				DEEPIN
			;;
			"openbox" )
				OPENBOX
			;;
			"budgie" )
				Budgie
			;;
		esac				
	
	
	else
		echo "your not install base Arch Gui"
		sleep 3
fi
}


Main(){

Ask_install_base
Ask_install_Gui

clear
echo "install Arch linux is successfully"
sleep 5
}

Main
