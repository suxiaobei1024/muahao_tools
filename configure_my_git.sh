#!/bin/bash

configure_inc() {
	git config --global user.email "ahao.mu@shopee.com"
	git config --global user.name "ahao.mu"
}

configure_me() {
    git config --global user.email "ahao.mu@gmail.com"
    git config --global user.name "ahao.mu"
}

usage() {
    echo "$0"
    echo "	./$0 inc"
    echo "	./$0 me"
}

main() {
	if [[ $1 == "inc" ]];then
		configure_inc
	elif [[ $1 == "me" ]];then
		configure_me
	fi
}

if [[ $# == 0 ]];then
    usage 
else
	main $1
fi

