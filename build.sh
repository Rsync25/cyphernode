#!/bin/bash

TRACING=1

trace()
{
  if [ -n "${TRACING}" ]; then
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] ${1}" > /dev/stderr
  fi
}

trace_rc()
{
  if [ -n "${TRACING}" ]; then
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] Last return code: ${1}" > /dev/stderr
  fi
}


build_docker_image() {
  
  local dockerfile="Dockerfile"

  if [[ ""$3 != "" ]]; then
    dockerfile=$3
  fi

  trace "building docker image: $2:latest"
  #docker build -q $1 -f $1/$dockerfile -t $2:latest > /dev/null
  docker build $1 -f $1/$dockerfile -t $2:latest

}

build_docker_images() {
  trace "Updating SatoshiPortal repos"
  git submodule update --recursive --remote

  local archpath=$(uname -m)
  local clightning_dockerfile=Dockerfile

  # compat mode for SatoshiPortal repo
  # TODO: add more mappings?
  if [[ $archpath == 'armv7l' ]]; then
    archpath="rpi"
    clightning_dockerfile="Dockerfile-alpine"
  fi

  trace "Creating cyphernodeconf image"
  build_docker_image install/ cyphernodeconf

  trace "Creating SatoshiPortal images"
  build_docker_image install/SatoshiPortal/dockers/$archpath/bitcoin-core cyphernode/bitcoin
  build_docker_image install/SatoshiPortal/dockers/$archpath/LN/c-lightning cyphernode/clightning $clightning_dockerfile
  
  trace "Creating cyphernode images"
  build_docker_image api_auth_docker/ cyphernode/gatekeeper
  build_docker_image proxy_docker/ cyphernode/proxy
  build_docker_image cron_docker/ cyphernode/proxycron
  build_docker_image pycoin_docker/ cyphernode/pycoin
  build_docker_image otsclient_docker/ cyphernode/otsclient
  
}

build_docker_images

