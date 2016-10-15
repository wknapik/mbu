mbu.sh - manage a multiboot usb stick
=====================================

This script allows you to create a usb stick with multiple live systems to
choose from at boot time.

You can list, install and uninstall ISO images. All you need is a partition on
a usb stick, the ISOs and the grub config fragments for your chosen systems
(you can copy-paste those from the [Arch wiki](https://wiki.archlinux.org/index.php/Multiboot_USB_drive#Boot_entries)).


Example usage:

\# Prepare (clears the usb stick).  
parted -s /dev/sdx mklabel msdos mkpart primary fat32 0% 100%  
mkfs.vfat /dev/sdx1

\# Install.  
mbu.sh -i tails.iso -c tails.cfg /dev/sdx1

\# List.  
mbu.sh -l /dev/sdx1

\# Uninstall.  
mbu.sh -u tails.iso /dev/sdx1


There are plenty tools out there, that do this and more, but they all seemed
bloated to me, with GUIs, thousands of lines of code, bundled binaries and also
hardcoded menus. This does what I needed in a 100 lines of bash, that should be
easy to understand and hack to your liking.

Dependencies: bash, coreutils, grep, grub, rsync, util-linux.  
