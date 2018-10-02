#!/bin/bash

u_flag='root'
s_flag=''
f_flag=''
h_flag=''
q_flag='false'

print_usage() {
  printf "Executes a local script on the provided remote hosts.\n\n"
  printf "Usage: runOnHosts.sh [-f hosts_file OR -h hosts_string] [-s script_to_run]\n"
  printf "\n"
  printf "Optional: [-u user (root)] [-q (Do not display ssh output)]\n"
  printf "\n" 
  printf "Note: Use ssh-agent ('ssh-add -K') to provide identity for remote hosts\n"
}

if [ $# -eq 0 ]
  then
  	print_usage
  	exit 1
fi

while getopts 'u:s:f:h:q' flag; do
  case "${flag}" in
    u) u_flag="${OPTARG}" ;;
    s) s_flag="${OPTARG}" ;;
    f) f_flag="${OPTARG}" ;;
    h) h_flag="${OPTARG}" ;;
    q) q_flag='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z "$h_flag" ] &&  [ -z "$f_flag" ] ;
  then
    printf "No hosts specified.. Exiting.\n"
    exit 1
fi

if [ -z $s_flag ]
  then
    printf "No script specified.. Exiting.\n"
    exit 1
fi

in_cmd=''
if [ -z "$h_flag" ]
  then
  	in_cmd=$(cat $f_flag)
  else
  	in_cmd="${h_flag}"
fi

quiet_cmd=''
if [ "$q_flag" == "true" ]
  then
  	quiet_cmd="> /dev/null 2>&1"
fi

for HOSTNAME in ${in_cmd} ; do
	printf "Running script '${s_flag}' on host: ${HOSTNAME}\n"
    ssh -o StrictHostKeyChecking=no -l ${u_flag} ${HOSTNAME} "bash -s" < ${s_flag} ${quiet_cmd}
done