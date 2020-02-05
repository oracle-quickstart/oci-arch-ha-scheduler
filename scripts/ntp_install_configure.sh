# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#!/bin/bash -x

# Install ntp
yum -y install ntp

#enable ports 7001, 7101, 80 and 443 at the OS firewall level

sudo firewall-cmd --direct --permanent --zone=public  --add-rule ipv4 filter OUTPUT 0 -d 169.254.169.254/32 -p udp -m udp --dport 123 -m comment --comment "Allow access to OCI local NTP service" -j ACCEPT
sudo firewall-cmd --reload
sudo service firewalld restart

# Set the date of the instance
sudo ntpdate 169.254.169.254

# Configure the instance to use the Oracle Cloud Infrastructure NTP service for iburs
sudo echo '
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.rhel.pool.ntp.org iburst
#server 1.rhel.pool.ntp.org iburst
#server 2.rhel.pool.ntp.org iburst
#server 3.rhel.pool.ntp.org iburst

server 169.254.169.254 iburst' > /etc/ntp.conf

# Start and enable the NTP service
systemctl start ntpd
systemctl enable ntpd

# disable the chrony NTP client to ensure that the NTP service starts automatically after a reboot
systemctl stop chronyd
systemctl disable chronyd


# END install keppalived