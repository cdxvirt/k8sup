#!/bin/bash

KUBECTL=${KUBECTL_BIN:-/usr/local/bin/kubectl}
KUBECTL_OPTS=${KUBECTL_OPTS:-}

ADDON_CHECK_INTERVAL_SEC=${TEST_ADDON_CHECK_INTERVAL_SEC:-60}
ADDON_PATH=${ADDON_PATH:-/etc/kubernetes/addons}

# Remember that you can't log from functions that print some output (because
# logs are also printed on stdout).
# $1 level
# $2 message
function log() {
  # manage log levels manually here

  # add the timestamp if you find it useful
  case $1 in
    DB3 )
#        echo "$1: $2"
        ;;
    DB2 )
#        echo "$1: $2"
        ;;
    DBG )
#        echo "$1: $2"
        ;;
    INFO )
        echo "$1: $2"
        ;;
    WRN )
        echo "$1: $2"
        ;;
    ERR )
        echo "$1: $2"
        ;;
    * )
        echo "INVALID_LOG_LEVEL $1: $2"
        ;;
  esac
}

# $1 command to execute.
# $2 count of tries to execute the command.
# $3 delay in seconds between two consecutive tries
function run_until_success() {
  local -r command=$1
  local tries=$2
  local -r delay=$3
  local -r command_name=$1
  while [ ${tries} -gt 0 ]; do
    log DBG "executing: '$command'"
    # let's give the command as an argument to bash -c, so that we can use
    # && and || inside the command itself
    /bin/bash -c "${command}" && \
      log DB3 "== Successfully executed ${command_name} at $(date -Is) ==" && \
      return 0
    let tries=tries-1
    log WRN "== Failed to execute ${command_name} at $(date -Is). ${tries} tries remaining. =="
    sleep ${delay}
  done
  return 1
}

function update_addons() {
  local -r enable_prune=$1;
  local -r additional_opt=$2;
  local namespace="default"
  local no_namespace_file_path_list no_namespace_file_path_arry \
        namespace_file_path_list namespace_file_path_arry \
        soft_link_folder_list soft_link_folder_arry \
        filename path length folder

  # Clear all soft-link
  rm -rf ${ADDON_PATH}/.* 2>/dev/null

  # Check files in $ADDON_PATH have namespaces, 
  # if do not have soft-link them to $ADDON_PATH/.default folder,
  # if have soft-link them to $ADDON_PATH/$namespace folder

  # Files without namespace
  no_namespace_file_path_list=$(find ${ADDON_PATH} -type f -name "*.yaml" -o -name "*.json" ! -type l | xargs --no-run-if-empty grep -L "namespace")
  no_namespace_file_path_arry=(${no_namespace_file_path_list// / });
  length=${#no_namespace_file_path_arry[@]}
  if [ ${length} -ne "0" ]; then
    for(( j=0; j<$length; j++ )); do
      path=${no_namespace_file_path_arry[$j]}
      filename=$(echo $path | sed 's/.*\///')

      if [ -d ${ADDON_PATH}/.${namespace} ]; then
        echo "Folder ${ADDON_PATH}/.${namespace} exist!" 1>/dev/null
      else
        mkdir -p ${ADDON_PATH}/.${namespace}
      fi
      ln -sf ${path} ${ADDON_PATH}/.${namespace}/${filename}
    done
  fi

  # Files with namespace
  namespace_file_path_list=$(find ${ADDON_PATH} -type f -name "*.yaml" -o -name "*.json" ! -type l | xargs --no-run-if-empty grep -l "namespace")
  namespace_file_path_arry=(${namespace_file_path_list// / });
  length=${#namespace_file_path_arry[@]}
  if [ ${length} -ne "0" ]; then
    for(( j=0; j<$length; j++ )); do
      path=${namespace_file_path_arry[$j]}
      filename=$(echo $path | sed 's/.*\///')

      if [ "${filename##*.}" == "yaml"  ]; then
        namespace=$(find ${path} | xargs grep "namespace: " | sed 's/.*://; s/"//g; s/,//g; s/ //g')
      elif [ "${filename##*.}" == "json" ]; then
        namespace=$(find ${path} | xargs grep '"namespace":' | sed 's/.*://; s/"//g; s/,//g; s/ //g')
      fi

      if [ -d ${ADDON_PATH}/.${namespace} ]; then
        echo "Folder ${ADDON_PATH}/.${namespace} exist!" 1>/dev/null
      else
        mkdir -p ${ADDON_PATH}/.${namespace}
      fi
      ln -sf ${path} ${ADDON_PATH}/.${namespace}/${filename}
    done
  fi

  # Excute command kubectl apply
  soft_link_folder_list=$(find ${ADDON_PATH} -type d -name ".*")
  soft_link_folder_arry=(${soft_link_folder_list// / });
  length=${#soft_link_folder_arry[@]}
  for(( j=0; j<$length; j++ )); do
    folder=${soft_link_folder_arry[$j]}
    namespace=$(echo ${folder} | sed 's/.*\///; s/^.//')
    run_until_success "${KUBECTL} ${KUBECTL_OPTS} apply --namespace=${namespace} -f ${folder} --prune=${enable_prune} -l cdxvirt/cluster-service=true ${additional_opt}" 1 1

    if [[ $? -eq 0 ]]; then
      log INFO "== Service addon update namespace ${namespace} completed successfully at $(date -Is) =="
    elif [[ $? -ne 0  ]]; then
      log WRN "== Service addon update namespace ${namespace} completed with errors at $(date -Is) =="
    fi
  done
}

log INFO "== Service addon manager started at $(date -Is) with ADDON_CHECK_INTERVAL_SEC=${ADDON_CHECK_INTERVAL_SEC} =="

# Start the apply loop.
# Check if the configuration has changed recently - in case the user
# created/updated/deleted the files on the master.
log INFO "== Entering periodical apply loop at $(date -Is) =="
while true; do
  start_sec=$(date +"%s")
  # Only print stderr for the readability of logging
  update_addons true ">/dev/null 2>&1"
  end_sec=$(date +"%s")
  len_sec=$((${end_sec}-${start_sec}))
  # subtract the time passed from the sleep time
  if [[ ${len_sec} -lt ${ADDON_CHECK_INTERVAL_SEC} ]]; then
    sleep_time=$((${ADDON_CHECK_INTERVAL_SEC}-${len_sec}))
    sleep ${sleep_time}
  fi
done
