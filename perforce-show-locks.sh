#!/bin/bash
#
# Created Nov 11th, 2014
#
# Author : ip2k
# Homepage : https://github.com/ip2k/perforce-show-locks
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright (c) 2014, ip2k
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


echo ">> $(date) <<"
users_raw=()  # blank space-separated list of users
p4 monitor show -ael > p4ms &
locks=$(lsof /perforcemetadata-new/burn-perforce100/db.* |awk '$4 ~ /[rwRW]/')
lock_pids=$(echo "$locks"|awk '{print $2}' |sort |uniq)
echo -e "\e[96mLocked Databases (Under 'FD' col, uR = Read, uW = Write)"
echo -e "==========================================================================\e[39m"
echo -e "\e[32mCOMMAND   PID     USER   FD   TYPE DEVICE         SIZE     NODE NAME\e[39m"
echo "$locks"
echo
echo -e "\e[92mJobs using the above locked DBs"
echo -e "================================\e[39m"
echo -e "\e[32mPID	STATUS	OWNER	RUNTIME(hh:mm:ss)	CMD	[ARGS]\e[39m  REF: http://go/p4mon"
for pid in $lock_pids; do
  p4_jobs=$(grep $pid p4ms)
  if [ ${#p4_jobs} -gt 0 ]; then
    users_raw+=($(echo "$p4_jobs" |awk '{print $5}'))
  fi
  echo "$p4_jobs"
#  echo ">>>>>>>>size of p4 jobs: ${#p4_jobs}"
done
echo
echo -e "\e[93mP4 Client Specs for users running above jobs"
echo -e "==============================================\e[39m"
users=$(echo "${users_raw[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')  # sort + uniq users array
#echo "Users: ${users[*]}"
#echo "Length of Users: ${#users[0]}"
if [ ${#users[0]} -gt 1 ]; then  # if the first username is more than 1 chr (AKA blank)
  for user in "${users[*]}"; do
    echo -e "\e[31mclient spec for $user"
    echo -e "-------------------------\e[39m"
    p4 client -o $user |egrep '(//|Options)' |egrep -v '^\#'
    echo
  done
fi

echo
rm p4ms
