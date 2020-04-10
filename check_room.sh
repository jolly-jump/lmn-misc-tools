#!/bin/bash
# Copyright 2019,2020 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

room=$1
## LINBO
#parallel-ssh -h /etc/hosts.$room -O "Port 2222" -O "UserKnownHostsFile ~/.ssh/linbo_hosts" -O "PubkeyAcceptedKeyTypes=+ssh-dss" -o asdf.out -e asdf.err -P uptime >/dev/null
#echo "Linux?"
#parallel-ssh -h /etc/hosts.$room -o asdf.out -e asdf.err -P uptime >/dev/null


while read host; 
do
    ping -c 1 -t 2 $host 2>/dev/null >/dev/null
    if [ $? -eq 0 ]; then
	# LINBO?
	echo -n -e "\033[2K\033[100D"
	echo -n "$host: "
	RETlinbo=$(linbo-ssh -T -n -o "ConnectTimeout=1" $host uptime 2>/dev/null)
	if [ $? -eq 255 ]; then
	    # Linux?
    	    RETlinux=$(ssh -T -n -o "ConnectTimeout=1" $host cat /.linbo 2>/dev/null )
	    if [ $? -eq 255 ]; then
		echo "neither LINBO nor Linux, not a PC?"
	    else
		echo -n "$RETlinux, status: "
		resp=$(ssh -T -n -o "ConnectTimeout=1" $host who)
		if [ -z "$resp" ]; then
		    echo "idle: " `ssh -T -n -o "ConnectTimeout=1" $host ps aux | sort -nrk 3,3 | head -n 1 | cut -c 1-50`
		else
		    echo $resp
		fi   
		
	    fi
	else
	    echo -n "$RETlinbo, LINBO status: "
	    resp=$(linbo-ssh -T -n -o "ConnectTimeout=1" $host 'ps aux | grep linbo_cmd | grep -v grep')
	    if [ -z "$resp" ]; then
		echo "idle"
	    fi
	    if  echo $resp | grep initcache > /dev/null; then
		echo "initcache"
	    fi
	    if  echo $resp | grep sync > /dev/null; then
		echo "syncing"
	    fi

	fi
    else
	if [ -n "$2" -a "$2" = "--showoffline" ];  then
	   echo "$host: offline, maybe?"
	else
	    echo -n "."
	fi
    fi
    
done </etc/hosts.$room

echo
