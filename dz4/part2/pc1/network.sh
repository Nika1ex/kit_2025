#!/usr/bin/env sh

ip link add lo1 type dummy 
# ip link add lo2 type dummy

ip link set eth1 up
ip link set eth2 up
ip link set lo1 up

ip address flush dev eth1
ip address flush dev eth2
ip address flush dev lo1

ip address add 192.168.1.1/32 dev lo1
ip address add 192.168.13.0/31 dev eth1 # .1/24 -> .0/31
ip address add 172.17.10.0/31 dev eth2 # .1/24 -> .0/31

ip route add default via 192.168.13.1 # .2 -> .1
