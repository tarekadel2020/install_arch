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



boot_partiton(){
	if [ ! -z $Boot_Partiton ]; then

		if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "uefi" ]; then
			mkfs.fat -n ESP -F32 $Boot_Partiton
		fi

		if [ $(echo "$Bios_Type" |tr [:upper:] [:lower:]) = "bios" ]; then
			mkfs.ext4 -L boot $Boot_Partiton
		fi
	fi
}


make_partitons(){
	mkfs.ext4 $Root_Partiton
	mkswap $Swap_Partiton
}


home_partiton(){
	if [ ! -z $Home_Partiton ];then
	makdir /mnt/home
	mkfs.ext4 $Home_Partiton
	mount $Home_Partiton /mnt/home
	fi

}

mount(){
	  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	# mount $Root_Partiton /mnt
	  swapon $Swap_Partiton
	  home_partiton
}

base(){
	pacstrap /mnt base base-devel linux linux-firmware vim nano net-tools
}

ask_install_base(){
read -p "Are you install base ? [Y-N]" accept_base
if [ $accept_base == "y" ] || [ $accept_base == "Y"] ; then
	boot_partiton
	make_partitons
	mount
	base
fi
}


main(){

ask_install_base

}

main
