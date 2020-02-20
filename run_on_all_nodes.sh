#!/bin/bash

configure_network() {

  apt update; apt install bridge-utils -y;

  if [ "$HOSTNAME" = "$HOSTNAME_INFRA" ]
  then
    BR_MGMT_IP="$BR_MGMT_IP_INFRA"
    BR_MGMT_MASK='255.255.255.0'
    BR_VXLAN_IP="$BR_VXLAN_IP_INFRA"
    BR_VXLAN_MASK='255.255.255.0'
  elif [ "$HOSTNAME" = "$HOSTNAME_COMPUTE00" ]
  then
    BR_MGMT_IP="$BR_MGMT_IP_COMPUTE00"
    BR_MGMT_MASK='255.255.255.0'
    BR_VXLAN_IP="$BR_VXLAN_IP_COMPUTE00"
    BR_VXLAN_MASK='255.255.255.0'
  elif [ "$HOSTNAME" = "$HOSTNAME_COMPUTE01" ]
  then
    BR_MGMT_IP="$BR_MGMT_IP_COMPUTE01"
    BR_MGMT_MASK='255.255.255.0'
    BR_VXLAN_IP="$BR_VXLAN_IP_COMPUTE01"
    BR_VXLAN_MASK='255.255.255.0'
  fi

  echo -e 'auto lo
iface lo inet loopback

auto bond0
iface bond0 inet static
    address '$PUBLIC_IP'
    netmask '$PUBLIC_MASK'
    gateway '$PUBLIC_GATEWAY'
    bond-downdelay 200
    bond-miimon 100
    bond-mode 5
    bond-updelay 200
    bond-xmit_hash_policy layer3+4
    bond-slaves enP2p1s0f1
    dns-nameservers '$PUBLIC_DNS1' '$PUBLIC_DNS2'

auto enp4s0f0 
iface enp4s0f0 inet manual
    bond-master bond0

auto enp4s0f1
iface enp4s0f1 inet manual
    bond-master bond1
    bond-primary enp4s0f1

auto bond1
iface bond1 inet manual
    bond-slaves none
    bond-mode active-backup
    bond-miimon 100
    bond-downdelay 250
    bond-updelay 250

auto bond1.'$VLAN_BR_MGMT'
iface bond1.'$VLAN_BR_MGMT' inet manual
    vlan-raw-device bond1

auto bond1.'$VLAN_BR_VXLAN'
iface bond1.'$VLAN_BR_VXLAN' inet manual
    vlan-raw-device bond1

auto br-mgmt
iface br-mgmt inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports bond1.'$VLAN_BR_MGMT'
    address '$BR_MGMT_IP'
    netmask '$BR_MGMT_MASK'

auto br-vxlan
iface br-vxlan inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports bond1.'$VLAN_BR_VXLAN'
    address '$BR_VXLAN_IP'
    netmask '$BR_VXLAN_MASK > /etc/network/interfaces
}

update_os() {
  apt update
  apt install debootstrap ifenslave ifenslave-2.6 lsof lvm2 chrony openssh-server sudo \
          tcpdump vlan python python3 python-pip python3-pip aptitude build-essential git \
          python-dev python3-dev sudo -y
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.utf8
  echo '8021q' >> /etc/modules
  echo '8021q' >> /etc/modules-load.d/openstack-ansible.conf
  service chrony restart
}

configure_ssh() {
  ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
  echo -e 'Host *
  StrictHostKeyChecking no' > /root/.ssh/config
  chmod 400 /root/.ssh/config
}


HOSTNAME=$(hostname)
HOSTNAME_INFRA='infra'
HOSTNAME_COMPUTE00='compute00'
HOSTNAME_COMPUTE01='compute01'
PUBLIC_IP=$(ifconfig bond0 | grep 'inet ' | awk '{print $2}')
PUBLIC_MASK=$(ifconfig bond0 | grep 'inet ' | awk '{print $4}')
PUBLIC_GATEWAY=$(ip route show | grep 'default' | awk '{print $3}')
PUBLIC_DNS1=$(sed -n 1p /etc/resolv.conf | awk '{print $2}')
PUBLIC_DNS2=$(sed -n 2p /etc/resolv.conf | awk '{print $2}')
VLAN_BR_MGMT='1022'
VLAN_BR_VXLAN='1024'
BR_MGMT_IP_INFRA='172.16.0.1'
BR_MGMT_IP_COMPUTE00='172.16.0.2'
BR_MGMT_IP_COMPUTE01='172.16.0.3'
BR_VXLAN_IP_INFRA='172.17.0.1'
BR_VXLAN_IP_COMPUTE00='172.17.0.2'
BR_VXLAN_IP_COMPUTE01='172.17.0.3'

save_public_ip;
configure_network;
update_os;
configure_ssh;
