#!/bin/bash -x

set -o errexit    # abort script at first erro

export IMAGE_VERSION=$1

cd test

./libs/bats-core/bin/bats test.bats

