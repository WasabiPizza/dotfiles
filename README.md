# My custom Arch Linux install 

```
loadkeys us

efibootmgr
efibootmgr -b 000X -B

iwctl

timedatectl

fdisk /dev/nvme0n1
cryptsetup --type luks2 --verify-passphrase --sector-size 4096 --verbose luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.xfs -s size=4096 /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
mkdir /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi

pacstrap -K /mnt base base-devel linux-lts linux-firmware man-db vim dosfstools xfsprogs intel-ucode iwd efibootmgr sbctl

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc

vim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo archlinux > /etc/hostname

(chroot) # exit
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
arch-chroot /mnt

cat <<EOF >> /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
EOF
systemctl enable iwd

vim /etc/mkinitcpio.conf
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
vim /etc/crypttab.initramfs
cryptroot  UUID=ROOT_UUID  -  password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard

echo 'root=/dev/mapper/cryptroot rw quiet modprobe.blacklist=pcspkr bgrt_disable' > /etc/kernel/cmdline

vim /etc/mkinitcpio.d/linux-lts.preset
# mkinitcpio preset file for the 'linux-lts' package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux-lts.img"
default_uki="/efi/EFI/Linux/arch-linux-lts.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-lts-fallback.img"
fallback_uki="/efi/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"

mkinitcpio -P
delete initramfs-*.img from /boot

sbctl create-keys
sbctl enroll-keys --microsoft
sbctl sign --save /efi/EFI/Linux/arch-linux-lts.efi 

efibootmgr --create --disk /dev/nvme0 --part 1 --label "Arch Linux" --loader "EFI\\Linux\\arch-linux-lts.efi"

efibootmgr --bootorder 0000

passwd 

exit
umount -R /mnt
```








