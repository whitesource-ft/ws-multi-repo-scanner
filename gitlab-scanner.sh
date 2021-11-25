#!/usr/bin/env bash

set -o errexit  # Exit script when a command exits with non-zero status.
set -o errtrace # Exit on error inside any functions or sub-shells.
set -o nounset  # Exit script on use of an undefined variable.
set -o pipefail # Return exit status of the last command in the pipe that exited with a non-zero exit code

# ==============================================================================
#                       Unified Agent Scan All Projects in a Gitlab Group
# ------------------------------------------------------------------------------
## Usage: $0 [-dh] <gitlab-domain> <group-id> <gitlab-token>
##
## Where:
##       - <gitlab-domain> is the domain where gitlab lives (for instance: 'gitlab.com')
##       - <group-id> is the ID of the group who's repos should be cloned
##       - <gitlab-token> is the API access token to make REST API calls with
##
## Options:
##   -h|--help      Print this help dialogue and exit
##   -u|--user      The given ID is a user, not a group
##
## The repositories will be cloned into a sub-directory under the path from Where
## this script has been called. The repository will be cloned into ./${group-id}/${repo-name}
##
## The git executable can be overridden by setting the GIT environmental variable
## before calling this script:
##
##        GIT=/usr/local/git-plus $0 <gitlab-domain> <group-id> <gitlab-token>
# ==============================================================================

: readonly "${GIT:=git}"

usage() {
    local sScript sUsage

    readonly sScript="$(basename "$0")"
    readonly sUsage="$(grep '^##' <"$0" | cut -c4-)"

    echo -e "${sUsage//\$0/${sScript}}"
}

gitlab-clone-projects() {

    local -a aParameters aRepos
    local g_sGitlabDomain g_sGitlabToken g_sId
    local bIsUser
    local sDirectory sRepo

    call-api() {
      local -r sSubject="${1?One parameter required: <api-subject>}"
      curl --silent --header "PRIVATE-TOKEN: ${g_sGitlabToken}" "https://${g_sGitlabDomain}/api/v4/${sSubject}?per_page=100"
    }

    fetch-projects() {
      local iId sSubject

      readonly sSubject="${1?Two parameters required: <subject> <id>}"
      readonly iId="${2?Two parameters required: <subject> <id>}"

      call-api "${sSubject}/${iId}/projects" \
        | grep -E -o '"http_url_to_repo":"[^"]+"' \
        | cut -d '"' -f4
    }

    fetch-group-projects() {
      local -r iId="${1?One parameters required: <id>}"
      fetch-projects 'groups' "${iId}"
    }

    fetch-user-projects() {
      local -r iId="${1?One parameters required: <id>}"
      fetch-projects 'users' "${iId}"
    }

    bIsUser=false
    aParameters=()

    for arg in "$@";do
      case $arg in
        -h|--help )
          usage
          exit
        ;;

        -u|--user )
          readonly bIsUser=true
          shift
        ;;

        * )
          aParameters+=( "$1" )
          shift
        ;;
      esac
    done
    readonly aParameters

    readonly g_sGitlabDomain="${aParameters[0]?Three parameters required: <gitlab-domain> <group-id> <gitlab-token>}"
    readonly g_sId="${aParameters[1]?Three parameters required: <gitlab-domain> <group-id> <gitlab-token>}"
    readonly g_sGitlabToken="${aParameters[2]?Three parameters required: <gitlab-domain> <group-id> <gitlab-token>}"

    if [[ "${bIsUser}" = 'true' ]];then
      readonly sRepos=$(fetch-user-projects "${g_sId}")
    else
      readonly sRepos=$(fetch-group-projects "${g_sId}")
    fi

    aRepos=()
    for sRepo in ${sRepos[*]}; do
      aRepos+=("${sRepo}")
    done

    echo ' =====> Found ' ${#aRepos[@]} ' repositories'

    if [[ -d scandir ]];then
        echo " scandir already exists, deleting"
        rm -rf scandir && mkdir scandir
      else
        mkdir scandir
    fi

    for sRepo in "${aRepos[@]}"; do
        sDirectory="$(echo "${sRepo}" | awk -F "/" '{print $5}' | awk -F "." '{print $1}')"
        groupName="$(echo "${sRepo}" | awk -F "/" '{print $4}')"
        echo " -----> Cloning '${sRepo}'  into directory 'scandir/'${sDirectory}'"
        "${GIT}" clone --recursive "${sRepo}" $PWD/scandir/"${sDirectory}"
        echo "Scanning ${sRepo} of ${groupName}"
        docker run --rm --name dockerua \
        --mount type=bind,source=$PWD/scandir/${sDirectory},target=/home/wss-scanner/Data/ \
        -e WS_APIKEY=$WS_APIKEY \
        -e WS_USERKEY=$WS_USERKEY \
        -e WS_PRODUCTNAME=${groupName} \
        -e WS_PROJECTNAME=${sDirectory} whitesourceft/dockerua:full
    done
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  export -f gitlab-clone-projects
else
  gitlab-clone-projects "${@}"
  exit $?
fi

#EOF