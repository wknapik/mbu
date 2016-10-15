#!/usr/bin/env bash

set -eo pipefail

##############################################################################

prog="$(basename "$0")"

help() {
    echo -e "USAGE: $prog <options> <partition>
Manage a multiboot usb stick.
  -c | --config\t\tgrub menuentry [file path]
  -h | --help\t\tprint this help and exit
  -i | --install\t(re)install an ISO [file path]
  -l | --list\t\tlist installed ISOs and exit
  -u | --uninstall\tuninstall an ISO [file name]"
  exit 2
}

options=$(getopt -u -o c:hi:lu: -l config:,help,install:,list,uninstall: -n "$prog" -- "$@")
set -- $options
while true; do
    case "$1" in
        -c|--config) config="$2"; shift 2;;
        -h|--help) help;;
        -i|--install) readonly action="+"; iso="$2"; shift 2;;
        -l|--list) readonly action="?"; shift;;
        -u|--uninstall) readonly action="-"; iso="$2"; shift 2;;
        --) shift; break;;
        *) break;;
    esac
done

partition="$*"
mount_point="$(mktemp -d)"
boot_dir="$mount_point/boot"
iso_dir="$boot_dir/iso"
grub_dir="$boot_dir/grub"

##############################################################################

setup() {
    mount "$partition" "$mount_point"
}

cleanup() {
    if mountpoint -q "$mount_point"; then
        umount "$mount_point"
        rmdir "$mount_point"
    fi
}

trap cleanup ERR EXIT INT TERM

install_iso() {
    if [[ -z "$config" ]]; then
        echo "$prog: please specify a grub config file using -c" >&2
        exit 3
    fi
    rsync --size-only "$iso" "$iso_dir/"
    rsync -c "$config" "$iso_dir/$(basename "$iso").cfg"
}

uninstall_iso() {
    rm "$iso_dir/$iso"{,.cfg}
}

list_installed_isos() {
    [[ ! -d "$iso_dir" ]] || basename -a "$iso_dir/"*.iso
}

manage_iso() {
    mkdir -p "$iso_dir" "$grub_dir"
    case "$action" in
        -) uninstall_iso;;
        +) install_iso;;
    esac
    cat "$iso_dir/"*.cfg >"$grub_dir/grub.cfg"
    disk="/dev/$(lsblk -no PKNAME "$partition")"
    if ! head -c 512 "$disk"|strings|grep -q GRUB; then
        grub-install --target=i386-pc --recheck --boot-directory="$boot_dir" "$disk"
    fi
}

main() {
    setup
    case "$action" in
        '?') list_installed_isos;;
        +|-) manage_iso;;
    esac
    cleanup
}

##############################################################################

if ! shift || [[ -n "$*" || -z "$action" ]]; then
    help
else 
    main
fi
