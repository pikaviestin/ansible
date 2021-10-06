#!/bin/sh

[ "$(basename $PWD)" == '.rbw' ] && cd ..
test -d .rbw && test -f ansible.cfg || { echo "Please run me from the repository root"; exit 1; }

ln -sfn .rbw/ansible ansible
ln -sfn .rbw/ansible ansible-playbook

