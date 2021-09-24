#!/bin/bash 

create_disk_for() {
	seq=$1
	mkdir server$seq
	qemu-img create -f raw ./img/disk${seq}.raw 8192M
	mkfs -t ext4 ./img/disk${seq}.raw
	mount -o loop ./img/disk${seq}.raw ./server$seq
}

create_disk_for 1
