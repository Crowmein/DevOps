#!/bin/bash

sudo apt install git python3-pip
update-alternatives --install /usr/bin/python python /usr/bin/python3 2
pip3 install ansible
