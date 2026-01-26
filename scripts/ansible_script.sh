#!/bin/bash

ansible all -m group -a 'name=it state=present'

ansible all -m user -a 'name=jan group=it state=present'

ansible all -m copy -a 'src=scripts/file_01 dest=/home/jan owner=jan group=it mode=0700'
