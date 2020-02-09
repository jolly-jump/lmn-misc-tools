# lmn-misc-tools
Miscellaneous tools for lmn v7

Clone the repository
```
git clone https://github.com/jolly-jump/lmn-misc-tools.git
cd lmn-misc-tools
```

## linuxmuster-client-fixpermissions.sh

Run like this
```
./linuxmuster-client-fixpermission.sh
```

whenever you tampered with the directory under
``/srv/linbo/linuxmuster-client/bionic`` to make sure the client can
download all the files and ``~``-Files are deleted.

## benchmark_webui.py

Run like this (e.g.) on the server:
```
for i in `seq 10` ; do time ./benchmark_webui.py -u schuelte -p 'geheim!' >/dev/null 2>&1 &  done
```

to simulate ten login processes in the WebUI.
- install ``pygments`` module to have pretty printed output
- usage: 
```
usage: benchmark_webui.py [-h] [-s SERVERURL] [-v] -u USER -p PASSWORD

Test the login process of the WebUI. Login, retrieve identity, retrieve quota,
measure time.

optional arguments:
  -h, --help            show this help message and exit
  -s SERVERURL, --serverurl SERVERURL
                        Server URL to use, defaults to "https://server"
  -v, --verbose         Show the output of Identity and Quota retrieval
  -u USER, --user USER  Username to use for login
  -p PASSWORD, --password PASSWORD
                        Password to use for login
```

## workaround_enable_studentlogin.sh

run like this
```
./workaround_enable_studentlogin.sh
```
whenever you upgraded linuxmuster-webui7 package, in order to allow
students to login to the Schulkonsole/WebUI.

## informatik-biber-create-list.py

Create a list for the german CS competition "Informatik Biber" from the sophomorix-export.

- install gender_guesser ``pip3 install gender_guesser``
- start ``sophomorix-print`` and copy the resulting file ``cp /var/lib/sophomorix/print-data/add-unknown_WebUntis-unix.csv  ./add.csv``

Run like this
```
./informatik-biber-create-list.py "prefix-"
```
and answer the questions
- which classname belongs to which grade:
```
...
biberklasse => None : ok? oder andere Stufe eingeben. (Enter, 0-13)
k2 => 13 : ok? oder andere Stufe eingeben. (Enter, 0-13)12
...
```
- which gender a user has that could not be guessed:
```
10a 10 Jascha Müller mostly_male
Give gender on commandline m or f: m
```

- upload the resulting file ``schueler.biber.csv`` to the competition

complete usage:
```
usage: informatik-biber-create-list.py [-h] [-d] prefix

Create logins for the Informatik Biber with usernames and passwords, using a
given prefix

positional arguments:
  prefix                Prefix for all usernames

optional arguments:
  -h, --help            show this help message and exit
  -d, --dont-ask-gender
                        Skip asking questions about the gender, results in
                        anonym for all unknown gender types
```

## linuxmuster-certs-update

See inside script how to configure it
Run like this on the server:
```
./linuxmuster-certs-update
```
or copy it to ``/etc/cron.daily`` for daily checkup

## patch_linbo_postsync_on_start_hack.sh

Patch LINBO to execute the postsync-script when using "Start" without
sync or new. Makes sense if you want to set time, sync Windows
activation or other things even when starting without sync.

Run like this on the server
```
./patch_linbo_postsync_on_start_hack.sh
```
to patch the command update-linbofs and linbo_cmd. After that you have to execute
```
update-linbofs
```
to regenerate the LINBO system. Clients will now respect the
PostOnStart=yes option when started via LINBO.


## kvm-backup.sh

Manage full backups and snapshots of all configured Servers with their logical volumes.

Run like this on the server
```
./kvm-backup --help
usage: ./kvm-backup.sh OPTIONS [all | name1 [name2] ... ]
Creates a full backup of logical volumes of virtual machines given by names or ask interactively
One of -s or -b is mandatory but exclude each other

Possible options:
-c, --config=filename  use the filename as configfile instead of kvm-config.sh in the current directory
[-v, --verbose          be verbose] not implemented
-s, --snapshot=cmd     cmd may be: make, remove, merge
                       make - create snapshots of the lvs used by the VM
                         remove - remove the snapshots of the LVS used by the VM
                         merge - merge the snapshots (go back to the state before the snapshots were made)
-b, --backup           create a fullbackup

after reading the config, the following VMs and LVs are defined
lmn7-opnsense --- /dev/vghost/lmn7-opnsense
lmn7-server --- /dev/vghost/lmn7-serverroot /dev/vghost/lmn7-serverdata
backup target: /srv/backup
```
the usage help is hopefully self-explanatory. The above output is generated if you put a configuration file in place like the kvm-config.sh file in the repo.

## update_clouddata.sh

Aktualisiert die Cloud-Userdatenbank in dem es User löscht, die es im LDAP/AD nicht mehr gibt.

Run like this on the server
```
./update_clouddata.sh
```
but make sure you configure the script to your needs, e.g.

```
## no command line arguments: your cloudserver should be configured here:
cloudserver="jones"
## path to the occ command on the cloudserver
occ="/opt/nextcloud/occ"
## path to the data directory on the cloud server
data="/srv/nextcloud/data"
## list of directories on $data/ which should not be considered for deletion
excludelist="(appdata|files_external|rainloop|__groupfolders|updater-|vplan|plan)" 
```
