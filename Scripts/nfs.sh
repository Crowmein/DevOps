#!/bin/bash
sudo apt-get install nfs-kernel-server
sudo apt-get install nfs-common
/var/lib/jenkins/workspace/django/DevOps/Projeckt/app/ *(rw,sync,no_subtree_check)
sudo exportfs -ra
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
sudo ufw allow from any to any port 2049 proto tcp