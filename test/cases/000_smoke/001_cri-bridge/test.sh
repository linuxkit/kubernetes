#!/bin/sh
# SUMMARY: build and boot using cri-containerd runtime and Bridged networking
# LABELS:

runtime=cri-containerd
network=bridge

# Doesn't return
. ../common.sh
