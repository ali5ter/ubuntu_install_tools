#!/usr/bin/env sh
# @file create_esxi_vm.sh
# Create a virtual machine on an ESXi host
# Credited work: Tamas Piros (tamaspiros)
# @see https://github.com/tamaspiros/auto-create

set -e

vCPU=1
MEMORY=1024
STORAGE=16
ISO_PATH=""

help() {
    echo "Create a virtual machine on an ESXi host"
    echo
    echo "Usage:"
    echo "  create_esxi_vm.sh -n <name> [-c <number_of_vcpus>] [-m <memory_in_mb>] [-s <storage_in_gb>] [-i <iso_filepath>]"
    echo "  create_esxi_vm.sh -h"
    echo
    echo "Options:"
    echo "  -n  Name of the virtual machine."
    echo "  -c  Number of virtual CPUs from 1 to 32 [default: 1]."
    echo "  -m  Memory capacity in MB [default: 1024]."
    echo "  -s  Storage capacity in GB, thin provisioned [default: 16]."
    echo "  -i  Filepath of an ISO file used to install the operating system."
}

# ============================================================================
# Parse and validate options

while getopts n:c:m:s:i: opt; do
    case $opt in
        n)
            NAME=${OPTARG};
            if [ -z "$NAME" ]; then
                echo "No name was specified for the virtual machine"
                exit 1
            fi
            ;;
        c)
            vCPU=${OPTARG}
            if [ $(echo "$vCPU" | egrep "^-?[0-9]+$") ]; then
                if [ "$vCPU" -lt "1" ] || [ "$vCPU" -gt "32" ]; then
                    echo "Virtual CPUs must be between 1 and 32"
                    exit 1
                fi
            else
                echo "Virtual CPUs must be an integer value"
                exit 1
            fi
            ;;
        m)
            MEMORY=${OPTARG}
            if [ $(echo "$MEMORY" | egrep "^-?[0-9]+$") ]; then
                if [ "$MEMORY" -lt "1" ]; then
                    echo "Assigned memory must be 1MB or more"
                    exit 1
                fi
            else
                echo "Memory capacity must be an integer value"
                exit 1
            fi
            ;;
        s)
            STORAGE=${OPTARG}
            if [ $(echo "$STORAGE" | egrep "^-?[0-9]+$") ]; then
                if [ "$STORAGE" -lt "1" ]; then
                    echo "Assigned storage must be 1GB or more"
                    exit 1
                fi
            else
                echo "Storage capacity must be an integer value"
                exit 1
            fi
            ;;
        i)
            ISO_PATH=${OPTARG}
            if [ ! $(echo "$ISO_PATH" | egrep "^.*\.(iso)$") ]; then
                echo "The ISO filepath extension must be .iso"
            fi
            ;;
        \?) echo "Unknown option: -$OPTARG" >&2; help; exit 1;;
        :)  echo "Missing option argument for -$OPTARG" >&2; help; exit 1;;
        *)  echo "Unimplimented option: -$OPTARG" >&2; help; exit 1;;
    esac
done

if [ -d "$NAME" ]; then
    echo "A virtual machine of name, $NAME, exists already."
    exit
fi

# ============================================================================
# Virtual machine build environment

VM_DIR="/vmfs/volumes/datastore1/$NAME"
VMDK="$VM_DIR/$NAME.vmdk"
DEFAULT_VMX="default.vmx"
VMX="$VM_DIR/$NAME.vmx"

mkdir -p "$VM_DIR"

# ============================================================================
# Construct the vmdk and vmx files

vmkfstools -c "$STORAGE"G -a lsilogic "$VMDK"

cp "$DEFAULT_VMX" "$VMX"
sed -i "s%{{name}}%$NAME%g" "$VMX"
sed -i "s%{{vcpu}}%$vCPU%g" "$VMX"
sed -i "s%{{memory}}%$MEMORY%g" "$VMX"
sed -i "s%{{storage}}%$STORAGE%g" "$VMX"
sed -i "s%{{iso_path}}%$ISO_PATH%g" "$VMX"

# ============================================================================
# Register the virtual machine and power it on

CMD="$(vim-cmd solo/registervm $VMX)"
vim-cmd vmsvc/power.on "$CMD"

# ============================================================================
# Clean up

echo "The Virtual Machine is created with the spec:"
echo "  Name:     ${NAME}"
echo "  vCPUs:    ${vCPU}"
echo "  Memory:   ${MEMORY}MB"
echo "  Storage:  ${STORAGE}GB"
if [ -n "$ISO_PATH" ]; then
    echo "  ISO file: ${ISO_PATH}"
fi
