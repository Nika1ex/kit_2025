#!/usr/bin/env sh

ip link add lo1 type dummy 

ip link set eth1 up
# ip link set eth1 mtu 400
ip link set eth2 up
ip link set lo1 up

ip address flush dev eth1
ip address flush dev eth2
ip address flush dev lo1

ip address add 192.168.13.10/32 dev lo1 # /24 -> /32
ip address add 172.17.18.1/31 dev eth1
ip address add 10.200.13.1/31 dev eth2 # .2/30 -> .1/31

ip route add default via 172.17.18.0
# ip route add 100.100.2.12/32 via 10.200.13.1
