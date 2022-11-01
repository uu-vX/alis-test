#!/usr/bin/env bash

issues+=( "Identify which xorg packages are needed." )
xorg_packages () {
pacman -S --noconfirm --needed xorg-server xorg-xinit xorg-xrandr xorg-xbacklight 
#pacstrap /mnt xorg xorg-apps xorg-server xorg-drivers xorg-xkill xorg-xinit xterm mesa
cp /etc/X11/xinit/xinitrc ~/.xinitrc
}

issues+=( "Identify which packages are needed for user." )
minimal_interface () {
pacman -S --noconfirm --needed bspwm sxhkd alacritty rofi dunst ranger pdftoppm ueberzug feh redshift firefox picom
#qutebrowser

#check to install bspwm, sxhkd for different path
install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
#install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc
install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/bspwm/sxhkdrc
}

graphical_user_interface () {
pacman -S --noconfirm --needed thunar
#	GTK style
#	QT style
}

game_packages () {
pacman -S --noconfirm --needed lutris steam 
}

#https://marketplace.visualstudio.com/items?itemName=vscodevim.vim
#auto connection bluetooth device
#anki
#bashrc

until xorg_packages; do : ; done
until minimal_interface; do : ; done
until graphical_user_interface; do : ; done
#until game_packages; do : ; done
