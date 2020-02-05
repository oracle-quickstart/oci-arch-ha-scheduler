# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#!/bin/bash -x

frequency=$1
cluster_node_index=$2
custom_command=$3

# Set SELinux to permissive
setenforce permissive
mv /etc/sysconfig/selinux /etc/sysconfig/selinux.bkp
echo '
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted ' > /etc/sysconfig/selinux

cp /etc/sysconfig/selinux /etc/selinux/config

# Create the script for creating the volume group backup
echo '#!/bin/bash -x

# Calling custom command
'${custom_command}'
' > /home/opc/custom_command.sh

sudo chmod +x /home/opc/custom_command.sh
sudo chmod 777 /home/opc/custom_command.sh

# Create the crond opc jobs in the shared location
echo '# Custom command
'${frequency}' /home/opc/custom_command.sh >> /home/opc/cron_custom_command_log.log
' > /var/spool/cron/opc

# Add -c for starting crond service with clustering support
sudo echo '# Settings for the CRON daemon.
# CRONDARGS= :  any extra command-line startup arguments for crond
CRONDARGS="-c"
' > /etc/sysconfig/crond

#Set the crontab master node to node 0
if [ $cluster_node_index == 0 ]
then
    sudo crontab -n
fi

# Restart crond service
sudo service crond restart

# Reboot the system after 1 minute
sudo shutdown -r +1

# END crond configuration
