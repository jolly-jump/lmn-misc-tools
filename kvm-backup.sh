#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

declare -A lvs
declare -A defaultlvs
TIMEOUT=120
target=/srv/backup

function usage(){
    echo "usage: $0 "
    echo
    echo "Creates a full backup of VMs --- LVs "
    for vm in  "${!defaultlvs[@]}"; do
	echo $vm --- ${defaultlvs[$vm]};
    done
    echo "to $target"
    echo "by shutting them down, creating a snapshot in the offline state,"
    echo "starting the VMs again and converting the appliance disks to a qCOW2-image."
    echo ""
    echo "You need a kvm-config.sh in the same directory containing: the variable array defaultlvs"
}

source kvm-config.sh || usage

## List running domains.
function list_running_domains() {
    virsh domstate $1 | grep "shut off"
}

## try shutdown VM
function try_shutdown_vm() {
    local kvmclient=$1
    test -n "$(list_running_domains ${kvmclient} )"  && { echo -n "${kvmclient} already down. Ok." ; return 2 ; }
     virsh shutdown ${kvmclient} >/dev/null
    # Wait until all domains are shut down or timeout has reached.
    END_TIME=$(date -d "$TIMEOUT seconds" +%s)
    while [ $(date +%s) -lt $END_TIME ]; do
	# rBeak while loop when no domains are left.
	echo -n "."
	test -n "$(list_running_domains ${kvmclient} )" && return 0
	sleep 1
    done
    test -z "$(list_running_domains ${kvmclient} )" && { echo -n "${kvmclient} failed to shutdown. Exiting." ; exit 1; }
    return 1
}

function fullbackup() {
    echo "Backing up: "
    declare -p lvs
    for vm in "${!lvs[@]}"; do
	echo -n "Trying to shutdown $vm ... "
	 try_shutdown_vm $vm
	echo "RC: $?"
    done
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to create snapshot on $lv ... "
	     lvcreate -s $lv -l 20%ORIGIN -n $(basename ${lv})-backup
	    echo "RC: $?"
	done
    done
    for vm in "${!lvs[@]}"; do
	echo -n "Starting $vm ... "
	virsh start $vm
	echo "RC: $?"
    done
    export BDATE=$(date +%Y_%m_%d_%H_%M)
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to create fullbackup of $lv ... "
	    base=$(basename ${lv})
	    time qemu-img convert -O qcow2 ${lv}-backup $target/${base}_${BDATE}.qcow2
	    ln -sf $target/${base}_${BDATE}.qcow2 $target/${base}_latest.qcow2
	    lvremove ${lv}-backup -y
	    echo -n
	done
    done
}

if [ -z "$1" ]; then
    echo "Available defined VMs: "
    for vm in "${!defaultlvs[@]}"; do
	echo -n "$vm "
    done
    echo 
    echo "Which VM do you want to backup? Enter VMs seperated by space or 'all'"
    read -a inputvms
    if [ -z $inputvms ]; then
	exit 0
    fi
    if [ $inputvms == "all" ]; then
	for vm in "${!defaultlvs[@]}";  do
	    lvs[$vm]=${defaultlvs[$vm]}
	done
	fullbackup 
	exit 0
    fi
    for vm in ${inputvms[@]}; do
	if [ "${defaultlvs[$vm]}" == "" ]; then
	    echo "$vm is not defined."
	    usage
	    exit 1
	fi
    done
    for vm in ${inputvms[@]}; do
	lvs["$vm"]=${defaultlvs[$vm]}
    done
    fullbackup
    exit 0
else
    usage
    exit 1
fi


