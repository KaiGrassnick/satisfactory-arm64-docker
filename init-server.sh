#!/bin/bash

STEAM_APP_ID="1690800"

function installServer() {
  BETA=""
  if [[ "${USE_EXPERIMENTAL}" == "true" ]]; then
    BETA="-beta experimental"
  fi

  FEXBash "./steamcmd.sh +@sSteamCmdForcePlatformBitness 64 +force_install_dir ${SF_SERVER_PATH} +login anonymous +app_update ${STEAM_APP_ID} ${BETA} validate +quit"
}

function main() {
  # Check if we have proper read/write permissions to /satisfactory
  if [ ! -r "${SF_SERVER_PATH}" ] || [ ! -w "${SF_SERVER_PATH}" ]; then
    echo "ERROR: Missing read/write permissions to ${SF_SERVER_PATH}! Please run \"chown -R ${DOCKER_USER}:${DOCKER_GROUP} ${SF_SERVER_PATH}\" on host machine, then try again."
    exit 1
  fi

  # Check for SteamCMD updates
  echo 'Checking for SteamCMD updates...'
  FEXBash './steamcmd.sh +quit'

  # Check if the server is installed
  if [ ! -f "${SF_SERVER_PATH}/FactoryServer.sh" ]; then
    echo 'Server not found! Installing...'
    installServer
  fi

  # If auto updates are enabled, try updating
  if [ "${ALWAYS_UPDATE_ON_START}" == "true" ]; then
    echo 'Checking for updates...'
    installServer
  fi

  # Fix for steamclient.so not being found
  if [[ ! -f /home/steam/.steam/sdk64/steamclient.so ]]; then
    echo 'Fixing steamclient.so...'
    mkdir -p /home/steam/.steam/sdk64
    ln -s /home/steam/Steam/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so
  fi

  echo 'Starting server...'

  # Go to satisfactory server directory
  cd "${SF_SERVER_PATH}" || exit 1

  # Start server
  FEXBash "./FactoryServer.sh ${EXTRA_PARAMS}"
}

main
