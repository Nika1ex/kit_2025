#!/usr/bin/env sh

ip link add lo1 type dummy 

ip link set eth1 up
# ip link set eth1 mtu 200
ip link set eth2 up
# ip link set eth2 arp off
ip link set lo1 up

ip address flush dev eth1
ip address flush dev eth2
ip address flush dev lo1

ip address add 100.100.2.12/32 dev lo1
ip address add 172.17.18.0/31 dev eth1
ip address add 172.17.10.1/31 dev eth2 # .2/24 -> .1/31

ip route add default via 172.17.10.0 # .1 -> .0
