#!/bin/bash -x

set -o errexit    # abort script at first error

function testPrintVersion() {
  local tagname=$1
  docker run --rm fekide/volumerize:$tagname duplicity -V
}

testPrintVersion $1
