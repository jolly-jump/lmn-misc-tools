#!/bin/bash
# -*- coding: utf-8 -*-
#
# Copyright 2020 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

## This script updates the master branch of
## https://github.com/spantaleev/matrix-docker-ansible-deploy.git
## using ansible in the docker-container devture/ansible:2.9.9-r0
##
## assuming you have your own local branch "working-branch"
## where you merge changes from the master branch if the
## master branch works for you
##
## assuming your TARGETDIR has the name of this script (without the .sh ending)

# no arguments: pull master branch and show diff to own branch
# arguments: arguments to the ansible-playbook
#            setup-all --- on the master branch
#            stop --- on the master branch
#            start --- on the master branch
#            sss  --- do all of the above, including merging the master branch on success
#            reset --- do all of the above on the working-branch

TARGETDIR=/root/$(basename $0 .sh)

function sss() {
    set -e
    for run in setup-all stop start; do 
	docker run -it --rm -w /work -v`pwd`:/work -v $HOME/.ssh:/root/.ssh:ro --entrypoint=ansible-playbook devture/ansible:2.9.9-r0  -i inventory/hosts setup.yml --tags=$run
    done
    set +e
    
}

cd $TARGETDIR
if [ -z "$1" ];  then
    git checkout master
    git pull
    git checkout working-branch
    git log working-branch..master --no-merges
    echo "Successfully updated the master branch"
    exit 0
elif [  "$1" = "sss" ]; then
    git checkout master
    sss
    git checkout working-branch
    git merge master --no-edit
    echo "Successfully updated the working-branch"    
    exit 0
elif [ "$1" = "reset" ]; then
    git checkout working-branch
    sss
    echo "Successfully reset to working-branch"
    exit 0
else
    git checkout master
    docker run -it --rm -w /work -v`pwd`:/work -v $HOME/.ssh:/root/.ssh:ro --entrypoint=ansible-playbook devture/ansible:2.9.9-r0  -i inventory/hosts setup.yml --tags=$1
    git checkout working-branch
    echo "Successfully $1 the master branch"    
    exit 0
fi
