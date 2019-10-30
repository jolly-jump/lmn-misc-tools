#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

target="/srv/linbo/linuxmuster-client/bionic/common"

echo "fixing permissions in $target"
chmod -R uog+r $target
find $target -type d -exec chmod ugo+x \{\} \;

echo "deleting all *~ files in $target"
find $target -name \*~ -exec rm \{\} \;
