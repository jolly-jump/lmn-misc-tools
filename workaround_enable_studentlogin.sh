#!/bin/bash
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later


sed -i "s/(sophomorixRole=schooladministrator) /(sophomorixRole=schooladministrator)(sophomorixRole=student) /" /usr/lib/linuxmuster-webui/plugins/lmn_auth/api.py
echo -n "Check if student is in filter: "
grep student /usr/lib/linuxmuster-webui/plugins/lmn_auth/api.py >/dev/null && echo ok
echo "Restarting Schulkonsole/WebUI"
systemctl restart linuxmuster-webui
