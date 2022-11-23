#!/bin/bash
mkdir -p /projects/$1 && cd /projects/$1 && git init && git remote add origin $2 && git fetch origin $3 --depth=1 && git reset --hard $3 && rm -rf .git