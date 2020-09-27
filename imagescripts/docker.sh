#!/bin/bash

set -o errexit

# From  https://stackoverflow.com/a/42955871/6475604
function parse_node() {
  read title
  id_start=0
  name_start=`strindex "$title" NAME`
  image_start=`strindex "$title" IMAGE`
  node_start=`strindex "$title" NODE`
  dstate_start=`strindex "$title" DESIRED`
  id_length=name_start
  name_length=`expr $image_start - $name_start`
  node_length=`expr $dstate_start - $node_start`

  read line
  id=${line:$id_start:$id_length}
  name=${line:$name_start:$name_length}
  name=$(echo $name)
  node=${line:$node_start:$node_length}
  echo $name.$id
  echo $node
}

strindex() { 
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

function dockerTaskOfService() {
  local exec_task=$1
  local exec_instance=$2

  if true; then 
    read fn 
    local docker_fullname=$fn
    read nn
    local docker_node=$nn 
  fi < <( docker service ps -f name=$exec_task.$exec_instance --no-trunc -f desired-state=running $exec_task | parse_node )
  SWARM_TASK=${docker_fullname}
}

function stopContainers() {
  local arrayContainers=
  IFS=' ' read -r -a arrayContainers <<< "$1"
  local min=0
  local max=$(( ${#arrayContainers[@]} ))

  for (( i=$min; i<$max; i++ ))
  do
    docker stop "${arrayContainers[$i]}" || true
  done
}

function startContainers() {
  local arrayContainers=
  IFS=' ' read -r -a arrayContainers <<< "$1"
  local min=0
  local max=$(( ${#arrayContainers[@]} -1))

  for (( i=$max; i>=$min; i-- ))
  do
    docker start ${arrayContainers[$i]} || true
  done
}
