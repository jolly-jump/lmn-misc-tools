#!/bin/bash
# Copyright 2019,2020 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later
# ideas and pieces of this script from Max Führinger from the wiki

## no command line arguments: your cloudserver should be configured here:
cloudserver="jones"
## path to the occ command on the cloudserver
occ="/opt/nextcloud/occ"
## path to the data directory on the cloud server
data="/srv/nextcloud/data"
## list of directories on $data/ which should not be considered for deletion
excludelist="(appdata|files_external|rainloop|__groupfolders|updater-|vplan|plan)" 

## kopiere dieses Script auf den Cloudserver
if [ `hostname -s` = "server" ]; then
    echo "Kopiere dieses Script  $0 auf den Cloudserver: $cloudserver und führe es wieder aus"
    scp $0 $cloudserver:
    ssh -t $cloudserver $0
    exit 0
fi


##############################################################################################

homelist=`mktemp`
pv --version > /dev/null
if [ $? -ne 0 ] ; then
    apt install pv
fi

### Zeige, frage und lösche alle User, die nicht mehr im LDAP sind:
echo -n "Users nicht mehr im LDAP: "
sudo -u www-data php /opt/nextcloud/occ ldap:show-remnants  | awk '{print $2}' | sed "2d;/^\s*$/d" > /tmp/zuloeschendeuser
if [ -s /tmp/zuloeschendeuser ]; then
    cat /tmp/zuloeschendeuser | paste -s -d " "
    echo "Sollen diese User gelöscht werden? yes/NO"
    read
    if [ "x$REPLY" = "xyes" ] ; then
	for i in `cat /tmp/zuloeschendeuser`; do 
	    sudo -u www-data php /opt/nextcloud/occ user:delete "$i"; 
	done 
    fi
else
    echo "keine"
fi

### Erstelle eine Liste an Usern mit Dateien in der Cloud
echo -n "Erstelle Liste aller User mit Dateien in der Cloud: "
ls $data | grep -v "\." | grep -vE $excludelist > /tmp/userlist
echo `cat /tmp/userlist | wc -l` "user"

### Erstelle die Liste aller User mit Dateien, die nicht mehr im LDAP sind 
echo "Checke, ob User noch in LDAP sind:"
for i in `cat /tmp/userlist` ; do
    ## not an LDAP user?
    if  sudo -u www-data php $occ ldap:check-user "$i" | grep "not" 2>/dev/null >/dev/null ; then
	# not a local user?
	if ! sudo -u www-data php $occ user:info "$i" 2>/dev/null >/dev/null ; then
	    ## then add him to the list
	    echo "$i" >> $homelist
        fi
	## echo one byte 
	echo -n "x"
    else
	## echo one byte
	echo -n "."
    fi
done | pv -s `cat /tmp/userlist | wc -l` > /dev/null

### Zeige, frage und lösche alle User, die scheinbar noch Dateien in der Nextcloud haben
echo -n "Users in $homelist, deren Home gelöscht werden könnte $data: "
if [ -s $homelist ]; then
    cat $homelist | paste -s -d " "
    echo "Sollen diese User per rm -rf $data/<user> gelöscht werden? yes/NO"
    read
    if [ "x$REPLY" = "xyes" ] ; then
	for i in `cat $homelist`; do
	    echo rm -rf $data/$i
	done
    fi
else
    echo "keine"
fi
    



