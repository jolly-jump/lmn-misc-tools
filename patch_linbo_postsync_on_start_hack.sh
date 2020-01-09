#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

cp /var/cache/linuxmuster/linbo/linbofs64/usr/bin/linbo_cmd /srv/linbo/my_linbo_cmd

cat <<'EOF' | patch -u /srv/linbo/my_linbo_cmd -
--- /var/cache/linuxmuster/linbo/linbofs64/usr/bin/linbo_cmd	2019-11-15 09:12:41.379260671 +0100
+++ my_linbo_cmd	2020-01-09 15:11:43.169924921 +0100
@@ -1562,6 +1562,18 @@
  fi
  # sets machine password on server
  invoke_macct
+ # do a postsync on start, if configured with PostsyncOnStart=yes in next line after baseimage=${image}.cloop line
+ # does NOT do all the windows/linux stuff: restore bcd,gpt,registry and newdev.dll-patching,
+ image="$(cat /mnt/.linbo)"
+ postsync="$image.cloop.postsync"
+ local RET=""
+ RET="$(grep -i "baseimage[[:space:]]*=[[:space:]]*${image}.cloop" -A 1 /start.conf | grep -i ^postsynconstart | tail -1 | awk -F= '{ print $2 }' | awk '{ print $1 }' | tr A-Z a-z)"
+ if [ "x$RET" = "xyes" ]; then
+     echo "do a postsync anyway"
+     # source postsync script
+     [ -s "/cache/$postsync" ] && . "/cache/$postsync"
+     sync; sync; sleep 1
+ fi
  # kill torrents if any
  killalltorrents
  sync
EOF

cp /usr/share/linuxmuster/linbo/update-linbofs.sh /srv/linbo/my-update-linbofs.sh

cat <<'EOF' | patch -u /srv/linbo/my-update-linbofs.sh -
--- /usr/share/linuxmuster/linbo/update-linbofs.sh      2020-01-09 16:25:41.704274561 +0100
+++ /srv/linbo/my-update-linbofs.sh     2020-01-09 16:30:06.378266405 +0100
@@ -86,7 +86,10 @@
 
  # copy default start.conf
  cp -f $LINBODIR/start.conf .
- 
+
+ #postsynconstart
+ cp /srv/linbo/my_linbo_cmd $linbofscachedir/usr/bin/linbo_cmd
+
  # pack default linbofs${suffix}.lz again
  find . | cpio --quiet -o -H newc | lzma -zcv > "$linbofs" ; RC="$?"
  [ $RC -ne 0 ] && bailout "failed!"
EOF


ln -sf /srv/linbo/my-update-linbofs.sh /usr/sbin/update-linbofs
