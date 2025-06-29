#!/usr/bin/env sh

ip link add lo1 type dummy 

ip link set eth1 up
ip link set eth2 up
ip link set lo1 up

ip address flush dev eth1
ip address flush dev eth2
ip address flush dev lo1

ip address add 10.12.12.8/32 dev lo1
ip address add 192.168.13.1/31 dev eth1 # .2/24 -> .1/31
ip address add 10.200.13.0/31 dev eth2 # .1/30 -> .0/31

ip route add default via 10.200.13.1 # .2 -> .1
