#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

# example configuration for kvm-backup.sh
declare -A defaultlvs
defaultlvs+=(["lmn7-opnsense"]="/dev/vghost/lmn7-opnsense")
defaultlvs+=(["lmn7-server"]="/dev/vghost/lmn7-serverroot /dev/vghost/lmn7-serverdata" )
TIMEOUT=120
target=/srv/backup
