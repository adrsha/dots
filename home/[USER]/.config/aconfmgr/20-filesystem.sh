# Sat Oct 10 08:22:21 +0545 2026 - New / changed files
CreateLink /.config /home/chilly/dots/.config
CreateLink /.gitignore /home/chilly/dots/.gitignore
CreateLink /.gitmodules /home/chilly/dots/.gitmodules
CreateLink /README.md /home/chilly/dots/README.md
CreateDir /boot/efi/System\ Volume\ Information
CopyFile /etc/adjtime
CreateDir /etc/audisp
CreateDir /etc/audit/plugins.d 750
CreateDir /etc/audit/rules.d
CopyFile /etc/brlapi.key 640 '' brlapi
CopyFile /etc/default/ufw
CopyFile /etc/fstab
CopyFile /etc/group
CopyFile /etc/group-
CopyFile /etc/hostname
CopyFile /etc/libvirt/nwfilter/allow-arp.xml
CopyFile /etc/libvirt/nwfilter/allow-dhcp-server.xml
CopyFile /etc/libvirt/nwfilter/allow-dhcp.xml
CopyFile /etc/libvirt/nwfilter/allow-dhcpv6-server.xml
CopyFile /etc/libvirt/nwfilter/allow-dhcpv6.xml
CopyFile /etc/libvirt/nwfilter/allow-incoming-ipv4.xml
CopyFile /etc/libvirt/nwfilter/allow-incoming-ipv6.xml
CopyFile /etc/libvirt/nwfilter/allow-ipv4.xml
CopyFile /etc/libvirt/nwfilter/allow-ipv6.xml
CopyFile /etc/libvirt/nwfilter/clean-traffic-gateway.xml
CopyFile /etc/libvirt/nwfilter/clean-traffic.xml
CopyFile /etc/libvirt/nwfilter/no-arp-ip-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-arp-mac-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-arp-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-ip-multicast.xml
CopyFile /etc/libvirt/nwfilter/no-ip-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-ipv6-multicast.xml
CopyFile /etc/libvirt/nwfilter/no-ipv6-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-mac-broadcast.xml
CopyFile /etc/libvirt/nwfilter/no-mac-spoofing.xml
CopyFile /etc/libvirt/nwfilter/no-other-l2-traffic.xml
CopyFile /etc/libvirt/nwfilter/no-other-rarp-traffic.xml
CopyFile /etc/libvirt/nwfilter/qemu-announce-self-rarp.xml
CopyFile /etc/libvirt/nwfilter/qemu-announce-self.xml
CreateLink /etc/libvirt/qemu/networks/autostart/default.xml /etc/libvirt/qemu/networks/default.xml
CreateLink /etc/libvirt/qemu/networks/autostart/virt-network.xml /etc/libvirt/qemu/networks/virt-network.xml
CopyFile /etc/libvirt/qemu/networks/default.xml
CopyFile /etc/libvirt/qemu/networks/virt-network.xml 600
CopyFile /etc/libvirt/storage/Downloads.xml 600
CreateLink /etc/libvirt/storage/autostart/Downloads.xml /etc/libvirt/storage/Downloads.xml
CreateLink /etc/libvirt/storage/autostart/default.xml /etc/libvirt/storage/default.xml
CreateLink /etc/libvirt/storage/autostart/isos.xml /etc/libvirt/storage/isos.xml
CopyFile /etc/libvirt/storage/default.xml 600
CopyFile /etc/libvirt/storage/isos.xml 600
CopyFile /etc/locale.conf
CopyFile /etc/locale.gen
CreateLink /etc/localtime /usr/share/zoneinfo/Asia/Kathmandu
CreateLink /etc/makepkg.conf /home/chilly/dots/etc/makepkg.conf
CopyFile /etc/mkinitcpio.conf
CopyFile /etc/mkinitcpio.d/linux.preset
CopyFile /etc/modprobe.d/blacklist-nouveau.conf
CreateLink /etc/os-release ../usr/lib/os-release
CopyFile /etc/pacman.conf
CopyFile /etc/pam.d/chfn
CopyFile /etc/pam.d/login
CopyFile /etc/pam.d/system-login
CopyFile /etc/passwd
CopyFile /etc/passwd-
CopyFile /etc/qemu/bridge.conf
CopyFile /etc/shells
CopyFile /etc/subgid
CreateFile /etc/subgid- > /dev/null
CopyFile /etc/subuid
CreateFile /etc/subuid- > /dev/null
CopyFile /etc/sudoers
CopyFile /etc/systemd/resolved.conf
CreateLink /etc/systemd/system/autovt@.service /usr/lib/systemd/system/getty@.service
CreateLink /etc/systemd/system/bluetooth.target.wants/bluetooth.service /usr/lib/systemd/system/bluetooth.service
CreateLink /etc/systemd/system/dbus-org.bluez.service /usr/lib/systemd/system/bluetooth.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.timesync1.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/system/getty.target.wants/getty@tty1.service /usr/lib/systemd/system/getty@.service
CreateLink /etc/systemd/system/multi-user.target.wants/NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
CreateLink /etc/systemd/system/multi-user.target.wants/libvirtd.service /usr/lib/systemd/system/libvirtd.service
CreateLink /etc/systemd/system/multi-user.target.wants/nessusd.service /usr/lib/systemd/system/nessusd.service
CreateLink /etc/systemd/system/multi-user.target.wants/playit.service /usr/lib/systemd/system/playit.service
CreateLink /etc/systemd/system/multi-user.target.wants/radarr.service /usr/lib/systemd/system/radarr.service
CreateLink /etc/systemd/system/multi-user.target.wants/remote-fs.target /usr/lib/systemd/system/remote-fs.target
CreateLink /etc/systemd/system/multi-user.target.wants/sshd.service /usr/lib/systemd/system/sshd.service
CreateLink /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service /usr/lib/systemd/system/NetworkManager-wait-online.service
CreateLink /etc/systemd/system/sockets.target.wants/libvirtd-admin.socket /usr/lib/systemd/system/libvirtd-admin.socket
CreateLink /etc/systemd/system/sockets.target.wants/libvirtd-ro.socket /usr/lib/systemd/system/libvirtd-ro.socket
CreateLink /etc/systemd/system/sockets.target.wants/libvirtd.socket /usr/lib/systemd/system/libvirtd.socket
CreateLink /etc/systemd/system/sockets.target.wants/qemu-pr-helper.socket /usr/lib/systemd/system/qemu-pr-helper.socket
CreateLink /etc/systemd/system/sockets.target.wants/systemd-userdbd.socket /usr/lib/systemd/system/systemd-userdbd.socket
CreateLink /etc/systemd/system/sockets.target.wants/virtlockd-admin.socket /usr/lib/systemd/system/virtlockd-admin.socket
CreateLink /etc/systemd/system/sockets.target.wants/virtlockd.socket /usr/lib/systemd/system/virtlockd.socket
CreateLink /etc/systemd/system/sockets.target.wants/virtlogd-admin.socket /usr/lib/systemd/system/virtlogd-admin.socket
CreateLink /etc/systemd/system/sockets.target.wants/virtlogd.socket /usr/lib/systemd/system/virtlogd.socket
CreateLink /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/system/timers.target.wants/reflector.timer /usr/lib/systemd/system/reflector.timer
CreateLink /etc/systemd/user/pipewire-session-manager.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/pipewire.service.wants/wireplumber.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/sockets.target.wants/p11-kit-server.socket /usr/lib/systemd/user/p11-kit-server.socket
CreateLink /etc/systemd/user/sockets.target.wants/pipewire.socket /usr/lib/systemd/user/pipewire.socket
CopyFile /etc/tpm2-tss/fapi-profiles/P_ECCP384SHA384.json
CopyFile /etc/tpm2-tss/fapi-profiles/P_RSA3072SHA384.json
CopyFile /etc/udev/rules.d/99-mt7922-bt-autosuspend.rules
CopyFile /etc/ufw/after.rules
CopyFile /etc/ufw/after6.rules
CopyFile /etc/ufw/before.rules
CopyFile /etc/ufw/before6.rules
CopyFile /etc/ufw/ufw.conf
CopyFile /etc/ufw/user.rules
CopyFile /etc/ufw/user6.rules
CopyFile /etc/vconsole.conf
CopyFile /etc/xdg/reflector/reflector.conf
CopyFile /etc/xdg/swaync/style.css
CopyFile /etc/xml/catalog
CreateDir /lost+found 700
CopyFile /opt/playit/share/init/selected-manager
CreateLink /setup.sh /home/chilly/dots/setup.sh
CreateLink /usr/bin/flutter /home/chilly/Codes/flutter/bin/flutter
CreateLink /usr/bin/playit /opt/playit/playit
CreateLink /usr/bin/playitd /opt/playit/playitd
CreateLink /usr/lib/jvm/default java-27-openjdk
CreateLink /usr/lib/jvm/default-runtime java-27-openjdk
CreateLink /usr/lib/libvsscript.so libvapoursynth-script.so.0
CopyFile /usr/local/bin/neo 755
CopyFile /usr/local/man/man6/neo.6
CopyFile /usr/share/applications/custom-kali.desktop
CopyFile /usr/share/applications/mimeinfo.cache
CreateDir /var/lib/BrlAPI 3777 brltty brltty
CreateDir /var/lib/brltty 2770 brltty brltty
CopyFile /var/lib/dkms/mok.pub
CreateDir /var/lib/geoclue '' geoclue geoclue
CreateDir /var/lib/libuuid 2775 uuidd uuidd
CreateDir /var/lib/machines 700
CreateFile /var/lib/pacman/db.lck 0 > /dev/null
CreateDir /var/lib/portables 700
CreateDir /var/lib/private 700
CreateDir /var/lib/rpcbind 700 rpc rpc
CreateDir /var/lib/systemd/ephemeral-trees
CreateDir /var/lib/systemd/linger
CreateDir /var/lib/systemd/network '' systemd-network systemd-network
CreateDir /var/lib/systemd/pstore
CreateDir /var/lib/tpm2-tss/system/keystore 2775 tss tss


# Sat Oct 10 08:22:21 +0545 2026 - New file properties


SetFileProperty / mode 555
SetFileProperty /etc/ssl/private mode 755
SetFileProperty /etc/systemd/network deleted y
SetFileProperty /etc/systemd/networkd.conf deleted y
SetFileProperty /var/lib/libvirt deleted y


# Sat Oct 10 08:22:59 +0545 2026 - Extra files


RemoveFile /var/lib/pacman/db.lck
RemoveFile /var/lib/pacman


# Sat Oct 10 08:22:59 +0545 2026 - Extra file properties


SetFileProperty /var/lib/pacman/db.lck mode ''
