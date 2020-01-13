#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

declare -A lvs
declare -A defaultlvs
TIMEOUT=120
target=/srv/backup

## print all preconfigured VMs and LVs
function print_configured() {
    echo "Available defined VMs and their LVs: "
    for vm in "${!defaultlvs[@]}"; do
	echo $vm --- ${defaultlvs[$vm]};
    done
}    
## print the todo list
function print_todo_list(){
    echo "These VMs plus their LVs are configured to be managed:"
    for vm in "${!lvs[@]}"; do
	echo -n "$vm: "
	for lv in ${lvs[$vm]}; do
	    echo -n "$lv "
	done
	echo 
    done
}
## zero every partition on every LV on every VM, if the partition can be mounted
function zero_lvs() {
    #declare -p lvs
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo "Cracking open $lv: "
	    kpartx -av "$lv"
	    mapperlink=""
	    for i in /dev/mapper/*; do
		if [ $(readlink -f $i) = $(readlink -f "$lv") ]; then
		    ## first correct link found will be used:
		    mapperlink=$i;
		    break
		fi
	    done
	    [ -z $mapperlink ] && { echo "No partitions found. Skipping $lv"; kpartx -dv "$lv" ; continue ; }
	    for part in ${mapperlink}*; do
		## not ${mapperlink} itself
		[ "$part" = "${mapperlink}" ] && continue
		local tmpd=$(mktemp -d)
		mount $part ${tmpd}
		if [ $? -eq 0 ]; then
		    if [ -n "$(ls -A $tmpd 2>/dev/null)" ]; then ## non-empty partition
			c=0 RC=0
			echo -n "Filling $part by GBs: "
			while [ $RC -eq 0 ] ; do
			    c=$((c+1))
			    echo -n "."
			    dd if=/dev/zero of=$tmpd/zero.$c bs=512 count=2000000 >/dev/null 2>/dev/null
			    RC=$?
			done
			echo "full. Removing zerofiles."
			rm -f $tmpd/zero.*
		    else ## empty partition
			echo "Partition seems empty. Refusing to fill it."
		    fi
		    umount $tmpd 2>/dev/null || { echo "Error: $part failed to umount. You need to fix this now. Exiting."; exit 2; }
		else
		    echo "Partition $part could not be mounted, skipping."
		fi
		rmdir $tmpd
	    done
	    echo "Reassembling $part"
	    kpartx -dv "$lv" || { echo "Error: $lv failed to reassemble. You need to fix this now. Exiting."; exit 2; }
	done
    done
}
## List running domains.
function list_running_domains() {
    virsh domstate $1 | grep "shut off"
}
## try shutdown VM
function try_shutdown_vms() {
    # returns 0 on success
    # returns 2 if vm was already down
    # exits with 1 on timeout
    # returns -1 on other error
    #declare -p lvs
    for vm in "${!lvs[@]}"; do
	echo -n "Trying to shutdown $vm ... "
	test -n "$(list_running_domains ${vm} )"  && { echo -n "${vm} already down. Ok." ; echo "RC: 2" ; continue; }
	virsh shutdown ${vm} >/dev/null
	# Wait until all domains are shut down or timeout has reached.
	END_TIME=$(date -d "$TIMEOUT seconds" +%s)
	while [ $(date +%s) -lt $END_TIME ]; do
	    # rBeak while loop when no domains are left.
	    echo -n "."
	    test -n "$(list_running_domains ${vm} )" && { echo "RC: 0"; break ; }
	    sleep 1
	done
	test -z "$(list_running_domains ${vm} )" && { echo -n "Error: ${vm} failed to shutdown. Exiting." ; exit 1; }
    done
}
## start VMs
function start_vms() {
    #declare -p lvs
    for vm in "${!lvs[@]}"; do
	echo -n "Starting $vm ... "
	virsh start $vm
	echo "RC: $?"
    done
}    
## start a fullbackup 
function fullbackup() {
    echo "Backing up: "
    #declare -p lvs
    try_shutdown_vms
    zero_lvs
    make_snapshot
    start_vms
    export BDATE=$(date +%Y_%m_%d_%H_%M)
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to create fullbackup of $lv ... "
	    base=$(basename ${lv})
	    time qemu-img convert -c -O qcow2 ${lv}-backup $target/${base}_${BDATE}.qcow2
	    ln -sf $target/${base}_${BDATE}.qcow2 $target/${base}_latest.qcow2
	    lvremove ${lv}-backup -y
	    echo -n
	done
    done
}
## make a snapshot of all LVs of all VMs
function make_snapshot() {
    #declare -p lvs
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to create snapshot on $lv ... "
	     lvcreate -s $lv -l 20%ORIGIN -n $(basename ${lv})-backup
	    echo "RC: $?"
	done
    done
}
## remove the snapshots
function remove_snapshot() {
    #declare -p lvs
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to create snapshot on $lv ... "
	    lvremove ${lv}-backup -y
	    echo "RC: $?"
	done
    done
}
## merge the snapshots, i.e. go back to the state before the snapshot was taken
function merge_snapshot() {
    #declare -p lvs
    try_shutdown_vms
    for vm in "${!lvs[@]}"; do
	for lv in ${lvs[$vm]}; do
	    echo -n "Trying to merge snapshot on $lv ... "
	    lvconvert --mergesnapshot ${lv}-backup
	    echo "RC: $?"
	done
    done
    start_vms
}

## +++ USAGE +++
function usage(){
    echo "usage: $0 OPTIONS [all | name1 [name2] ... ]"
    echo "Creates a full backup of logical volumes of virtual machines given by names or ask interactively"
    echo "One of -s or -b is mandatory but exclude each other"
    echo
    echo "Possible options:"
    echo "-c, --config=filename  use the filename as configfile instead of kvm-config.sh in the current directory"
    echo "[-v, --verbose          be verbose] not implemented"
    echo "-s, --snapshot=cmd     cmd may be: make, remove, merge"
    echo "                       make - create snapshots of the lvs used by the VM"
    echo "                       remove - remove the snapshots of the LVS used by the VM"
    echo "                       merge - merge the snapshots (go back to the state before the snapshots were made)"
    echo "-b, --backup           create a fullbackup"
    echo
    echo "after reading the config, the following VMs and LVs are defined"
    for vm in  "${!defaultlvs[@]}"; do
	echo $vm --- ${defaultlvs[$vm]};
    done
    echo "backup target: $target"
    echo ""
}


### +++ COMMAND LINE parameter parsing and logic +++
# https://stackoverflow.com/a/29754866
set -o errexit -o pipefail -o noclobber -o nounset
OPTIONS=c:bs:v
LONGOPTS=config:,backup,snapshot:,verbose
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    usage
    exit 2
fi
eval set -- "$PARSED"
set +e
b=n s=- v=n c=kvm-config.sh
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
	-c|--config)
	    c="$2"; shift 2
	    ;;
	-b|--backup)
	    b="y"; shift
	    ;;
	-v|--verbose)
	    v="y"; shift
	    ;;
	-s|--snapshot)
	    s="$2"; shift 2
	    ;;
	--)
	    shift; break
	    ;;
	*)
	    echo "Programming error"; exit 3
	    ;;
    esac
done

if [ "$b" = "n" -a "$s" = "-" -o "$b" = "y" -a "$s" != "-" ]; then
    echo "Error: neither -s nor -b or both was/were entered."
    usage
    exit 1
fi

## +++ Assemble the todo list +++
## get default values from configuration
source $c
## ask or read which VMs to use, save in inputvms array
declare -a inputvms
if [ $# -eq 0 ]; then  ## no VMs on the command line, ask interactively
    print_configured
    echo -e "\nWhich VM do you want to backup? Enter VMs seperated by space or only the word 'all' for all configured VMs."
    read -a inputvms
    if [ -z ${inputvms[@]} ]; then
	echo "No VM entered, exiting."
	exit 0
    fi
else  ## VMs seem to be given on the command line
    while [[ $# -ne 0 ]]; do
	inputvms+=($1)
	shift
    done
fi
## check the given VMs if they are defined
for vm in ${inputvms[@]}; do
    if [ "$vm" != "all" ]; then
	if [[ ! " ${!defaultlvs[@]} " =~ " ${vm} " ]]; then
	    echo "Error: $vm is not defined. Only VMs and their LVs defined by $c are allowed."
	    exit 1
	fi
    fi
done
## define the VMs and their LVs in variable "lvs"
for vm in ${inputvms[@]}; do
    if [ "$vm" = "all" ]; then
	for vm in "${!defaultlvs[@]}";  do
	    lvs[$vm]=${defaultlvs[$vm]}
	done
    else
	lvs["$vm"]=${defaultlvs[$vm]}
    fi
done
    
### +++ BACKUP
if [ "$b" = "y" ]; then
    echo "+++ Managing Backups +++"
    echo 
    print_configured
    print_todo_list
    fullbackup 
    exit 0
fi

### +++ SNAPSHOT
if [ "$s" != "-" ]; then
    echo "+++ Managing snapshots +++ "
    print_todo_list
    if [ "$s" = "make" ]; then
	make_snapshot
    elif [ "$s" = "remove" ]; then
	remove_snapshot
    elif [ "$s" = "merge" ]; then
	merge_snapshot
    else
	echo "$s" no valid snapshot command.
	exit 1
    fi
    exit 0
fi

### +++ never reach this
echo "Programming error"
exit 3
