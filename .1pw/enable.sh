#!/bin/sh

[ "$(basename $PWD)" == '.1pw' ] && cd ..
test -d .1pw && test -f ansible.cfg || { echo "Please run me from the repository root"; exit 1; }

ln -sfn .1pw/.envrc .envrc
