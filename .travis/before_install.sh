#!/usr/bin/env bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by bootstrap.py. Please use
# bootstrap.py to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

set -mveuo pipefail

export PRE_BEFORE_INSTALL=$TRAVIS_BUILD_DIR/.travis/pre_before_install.sh
export POST_BEFORE_INSTALL=$TRAVIS_BUILD_DIR/.travis/post_before_install.sh

COMMIT_MSG=$(git log --format=%B --no-merges -1)
export COMMIT_MSG

if [ -f $PRE_BEFORE_INSTALL ]; then
    $PRE_BEFORE_INSTALL
fi

if [[ -n $(echo -e $COMMIT_MSG | grep -P "Required PR:.*" | grep -v "https") ]]; then
  echo "Invalid Required PR link detected in commit message. Please use the full https url."
  exit 1
fi

if [ "$TRAVIS_PULL_REQUEST" != "false" ] || [ -z "$TRAVIS_TAG" -a "$TRAVIS_BRANCH" != "master"]
then
  export PULP_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulpcore\/pull\/(\d+)' | awk -F'/' '{print $7}')
  export PULP_SMASH_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp-smash\/pull\/(\d+)' | awk -F'/' '{print $7}')
  export PULP_ROLES_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/ansible-pulp\/pull\/(\d+)' | awk -F'/' '{print $7}')
  export PULP_BINDINGS_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp-openapi-generator\/pull\/(\d+)' | awk -F'/' '{print $7}')
  export PULP_OPERATOR_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp-operator\/pull\/(\d+)' | awk -F'/' '{print $7}')
  export PULP_BINDINGS_PR_NUMBER=$(echo $COMMIT_MSG | grep -oP 'Required\ PR:\ https\:\/\/github\.com\/pulp\/pulp-openapi-generator\/pull\/(\d+)' | awk -F'/' '{print $7}')
else
  export PULP_PR_NUMBER=
  export PULP_SMASH_PR_NUMBER=
  export PULP_ROLES_PR_NUMBER=
  export PULP_BINDINGS_PR_NUMBER=
  export PULP_OPERATOR_PR_NUMBER=
  export PULP_BINDINGS_PR_NUMBER=
fi

# dev_requirements contains tools needed for flake8, etc.
# So install them here rather than in install.sh
pip install -r dev_requirements.txt

# check the commit message
./.travis/check_commit.sh



# Lint code.
flake8 --config flake8.cfg

cd ..
git clone --depth=1 https://github.com/pulp/ansible-pulp.git
if [ -n "$PULP_ROLES_PR_NUMBER" ]; then
  cd ansible-pulp
  git fetch --depth=1 origin +refs/pull/$PULP_ROLES_PR_NUMBER/merge
  git checkout FETCH_HEAD
  cd ..
fi


git clone --depth=1 https://github.com/pulp/pulp-operator.git
if [ -n "$PULP_OPERATOR_PR_NUMBER" ]; then
  cd pulp-operator
  git fetch --depth=1 origin +refs/pull/$PULP_OPERATOR_PR_NUMBER/merge
  git checkout FETCH_HEAD
  RELEASE_VERSION=v0.9.0
  curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
  chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu && sudo mkdir -p /usr/local/bin/ && sudo cp operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/operator-sdk && rm operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
  sudo operator-sdk build --image-builder=docker quay.io/pulp/pulp-operator:latest
  cd ..
fi

git clone https://github.com/pulp/pulp-openapi-generator.git
if [ -n "$PULP_BINDINGS_PR_NUMBER" ]; then
  cd pulp-openapi-generator
  git fetch origin +refs/pull/$PULP_BINDINGS_PR_NUMBER/merge
  git checkout FETCH_HEAD
  cd ..
fi


git clone --depth=1 https://github.com/pulp/pulpcore.git

if [ -n "$PULP_PR_NUMBER" ]; then
  cd pulpcore
  git fetch --depth=1 origin +refs/pull/$PULP_PR_NUMBER/merge
  git checkout FETCH_HEAD
  cd ..
fi



# When building a (release) tag, we don't need the development modules for the
# build (they will be installed as dependencies of the plugin).
if [ -z "$TRAVIS_TAG" ]; then

  git clone --depth=1 https://github.com/pulp/pulp-smash.git

  if [ -n "$PULP_SMASH_PR_NUMBER" ]; then
    cd pulp-smash
    git fetch --depth=1 origin +refs/pull/$PULP_SMASH_PR_NUMBER/merge
    git checkout FETCH_HEAD
    cd ..
  fi

  # pulp-smash already got installed via test_requirements.txt
  pip install --upgrade --force-reinstall ./pulp-smash

fi


pip install ansible

cd pulp-2to3-migration

if [ -f $POST_BEFORE_INSTALL ]; then
    $POST_BEFORE_INSTALL
fi
