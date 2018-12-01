#!/bin/bash
sudo dnf install \
                xorg-x11-drv-amdgpu \
                nano                \
                plasma-desktop      \
                sddm                \
                sddm-breeze         \
                ark                 \
                dolphin             \
                konsole             \
                kwrite              \
                fcitx               \
                fcitx-qt5           \
                fcitx-kkc           \
                kcm-fcitx           \
                httpd               \
                ufw                 \
                firefox             \
                gcc-c++             \
                texinfo             \
                patch               \
                m4                  \
                bison               \
                byacc               \
                tar                 \
                make                \
                kde-partitionmanager \
                wget
sudo dnf remove plasma-browser-integration
echo "settings"
sudo ufw enable
sudo ufw deny SSH
sudo ufw allow 80
sudo systemctl enable ufw.service
sudo systemctl enable httpd.service
sudo systemctl enable sddm.service
sudo systemctl set-default graphical.target
sudo setenforce Permissive
