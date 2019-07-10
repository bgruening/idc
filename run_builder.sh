#!/bin/bash

set -e

: ${GALAXY_DOCKER_IMAGE:="quay.io/bgruening/galaxy"}
: ${GALAXY_PORT:="8080"}
: ${EPHEMERIS_VERSION:="0.8.0"}
: ${GALAXY_DEFAULT_ADMIN_USER:="admin@galaxy.org"}
: ${GALAXY_DEFAULT_ADMIN_PASSWORD:="admin"}
: ${EXPORT_DIR:="$HOME/export/"}
: ${DATA_MANAGER_DATA_PATH:="${EXPORT_DIR}/data_manager"}

: ${PLANEMO_PROFILE_NAME:="wxflowtest"}
: ${PLANEMO_SERVE_DATABASE_TYPE:="postgres"}

GALAXY_URL="http://localhost:$GALAXY_PORT"

git diff --name-only $TRAVIS_COMMIT_RANGE -- '*.yml' '*.yaml' > changed_files.txt
echo "Following files have changed."
cat changed_files.txt

if [ ! -f .venv ]; then
    virtualenv .venv
    . .venv/bin/activate
    pip install -U pip
    pip install ephemeris
    #pip install ephemeris=="${EPHEMERIS_VERSION}"
    #pip install -e git+https://github.com/galaxyproject/ephemeris.git@dm#egg=ephemeris
fi

echo 'ephemeris installed'

. .venv/bin/activate

mkdir -p ${DATA_MANAGER_DATA_PATH}
chmod 0777 ${DATA_MANAGER_DATA_PATH}

docker run -d -v ${EXPORT_DIR}:/export/ -e GALAXY_CONFIG_GALAXY_DATA_MANAGER_DATA_PATH=/export/data_manager/ -e GALAXY_CONFIG_GALAXY_WATCH_TOOL_DATA_DIR=True -p 8080:80 ${GALAXY_DOCKER_IMAGE}
galaxy-wait -g ${GALAXY_URL}

#TODO: make the yml file dynamic

{ while true; do echo . ; sleep 60; done; } &


if [ -s changed_files.txt ]
then
  for FILE in `cat changed_files.txt`;
    do
      if [[ $FILE == *"data-managers"* ]]; then
         #### RUN single data managers
         shed-tools install -d $FILE -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
         run-data-managers --config $FILE -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
      elif [[ $FILE == *"idc-workflows"* ]]; then
         #### RUN the pipline for new genome
         shed-tools install -d $FILE -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
         run-data-managers --config $FILE -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
     fi
  done
fi

#shed-tools install -d data-managers/humann2_download/chocophlan_full.yaml -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
#run-data-managers --config data-managers/humann2_download/chocophlan_full.yaml -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD

#### RUN the pipline for new genome

#cat idc-workflows/ngs_genomes.yaml  idc-workflows/ngs.yaml > ./temp_workflow.yaml
#shed-tools install -d ./temp_workflow.yaml -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD
#run-data-managers --config ./temp_workflow.yaml -g ${GALAXY_URL} -u $GALAXY_DEFAULT_ADMIN_USER -p $GALAXY_DEFAULT_ADMIN_PASSWORD

ls -l ${DATA_MANAGER_DATA_PATH}
