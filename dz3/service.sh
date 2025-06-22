#! /usr/bin/bash

while true; do
  echo "`date` I am still alive"
  echo "`date` Error simulation: something happened!" >&2
  sleep 1
done
