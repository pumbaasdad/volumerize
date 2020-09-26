#!/bin/bash

set -o errexit

function dockerTaskOfService() {
  local service=$1
  local tasksArray=
  IFS=' ' read -r -a tasksArray <<< $(docker service ps --format "{{.ID}}" $service)
  TASK_ID=${tasksArray[0]}
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
