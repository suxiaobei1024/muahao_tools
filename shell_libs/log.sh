#!/bin/sh
#****************************************************************#
# ScriptName: log.sh
# Author: $SHTERM_REAL_USER@alibaba-inc.com
# Create Date: 2017-11-09 18:26
# Modify Author: $SHTERM_REAL_USER@alibaba-inc.com
# Modify Date: 2017-11-09 18:26
# Function: 
#***************************************************************#

###########log level
function log_info(){
    local what=$*
    echo -e "\033[32m[ info ]\033[0m ${what}"
}

function log_error(){
    local what=$*
    echo -e "\033[31m\033[01m[ error ]\033[0m ${what}"
}

function log_error_exit(){
    local what=$*
    echo -e "\033[31m\033[01m[ error ]\033[0m ${what}"
	exit 1
}

function log_warn(){
    local what=$*
    echo -e "\033[33m\033[01m[ warning ]\033[0m ${what}"
}

#################
function loginfo(){
    local info=$1
	local msg=$2
    echo -e "\033[32m${info}\033[0m $msg"
}

## Error to warning with blink
function bred(){
    echo -e "\033[31m\033[01m\033[05m[ $1 ]\033[0m"
}

## Error to warning with blink
function log_warns(){
    echo -e "\033[33m\033[01m\033[05m[ $1 ]\033[0m"
}

## blue to echo 
function blue(){
    echo -e "\033[34m[ $1 ]\033[0m"
}

