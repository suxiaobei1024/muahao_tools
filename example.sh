#!/bin/sh
#****************************************************************#
# ScriptName: aa.sh
# Author: $SHTERM_REAL_USER@alibaba-inc.com
# Create Date: 2017-11-09 18:40
# Modify Author: $SHTERM_REAL_USER@alibaba-inc.com
# Modify Date: 2017-11-09 18:40
# Function: 
#***************************************************************#
root_dir=`cd "$(dirname "$0")";pwd`
. ${root_dir}/shell_libs/log.sh

log_info "hello world"
log_warn "hello world"
log_error "hello world"
if [[ $# == 0 ]];then
	log_info "一键部署:./$0 one_deploy"
	loginfo "一键部署" "./$0 one_deploy"

fi
