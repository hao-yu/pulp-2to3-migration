#!/bin/bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by bootstrap.py. Please use
# bootstrap.py to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

set -euv

# skip this check for everything but PRs
if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  exit 0
fi

if [ "$TRAVIS_COMMIT_RANGE" != "" ]; then
  RANGE=$TRAVIS_COMMIT_RANGE
elif [ "$TRAVIS_COMMIT" != "" ]; then
  RANGE=$TRAVIS_COMMIT
fi

# Travis sends the ranges with 3 dots. Git only wants two.
if [[ "$RANGE" == *...* ]]; then
  RANGE=`echo $TRAVIS_COMMIT_RANGE | sed 's/\.\.\./../'`
else
  RANGE="$RANGE~..$RANGE"
fi

for sha in `git log --format=oneline --no-merges "$RANGE" | cut '-d ' -f1`
do
  pip install requests
  python .travis/validate_commit_message.py $sha
  VALUE=$?

  if [ "$VALUE" -gt 0 ]; then
    exit $VALUE
  fi
done
