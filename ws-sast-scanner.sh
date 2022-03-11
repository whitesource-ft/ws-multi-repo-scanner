# Prequisities = wscli git curl
# Usage
    # ./ws-sast-scanner.sh scanlist.txt
# scanlist is a list of git repos

# Run the below part of the script only once to create a template for common exclusions
export SAST_ORGANIZATION=<your organization id>
export SASTCLI_TOKEN=<your api token>
export SAST_SERVER=https://sast-demo.whitesourcesoftware.com
curl --location --request POST ${SAST_SERVER}'/api/templates' -H 'X-Auth-Token: '${SASTCLI_TOKEN} -H 'Content-Type: application/json'  \
-d '{ "orgId": "${SAST_ORGANIZATION}", "name": "common-excludes", "parameters": { "target": { "type": "", "source": "", "path": "" }, "engines": [], "trackedInputs": [], "excludedVulnTypes": null, "depth": { "maxFunctionDepth": 0, "maxVariableTrack": 0 }, "customFilters": [], "exclusions": [ "test", "lib", "docs", "swagger", "angular", "node_modules", "bootstrap", "modernizer", "yui", "dojo", "xjs", "react", "plugins", "3rd", "build", "nuget" ], "patternMatching": [], "customRules": [], "diff": false, "includeFiltered": false, "ignoreStoredFP": false, "deepInputDiscovery": true, "almTrigger": "", "emailTrigger": "", "slackTrigger": "" } }'

# change wscli location to user home
wscli=/root/ws-sast/wscli

file=$1
lines=`cat ${file}`
for line in $lines; do
    rm -rf ./clonefolder
    echo "Cloning ${line}"
    git clone $line ./clonefolder
    repo=$(basename -s .git $line)
    branch=$(git --git-dir ./clonefolder/.git branch --show-current)
    echo "Cloned ${repo}"
    echo "Scanning ${repo}"
    ${wscli} --dir ./clonefolder --name ${repo}-${branch} --app ${repo} --template common-excludes
    echo ${line} >> completedscanned.txt
done