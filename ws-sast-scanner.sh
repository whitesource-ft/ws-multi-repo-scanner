# Prequisities = wscli git curl jq
# Usage
    # ./ws-sast-scanner.sh scanlist.txt
# scanlist is a list of git repos
# mkdir /root/ws-sast/reports

# update the below variables with your values
export SAST_ORGANIZATION=<your organization id>
export SASTCLI_TOKEN=<your api token>
export SAST_SERVER=https://sast-demo.whitesourcesoftware.com

# Run the below part of the script only once to create a template for common exclusions
curl --location --request POST ${SAST_SERVER}'/api/templates' -H 'X-Auth-Token: '${SASTCLI_TOKEN} -H 'Content-Type: application/json'  \
-d '{ "orgId": "${SAST_ORGANIZATION}", "name": "common-excludes", "parameters": { "target": { "type": "", "source": "", "path": "" }, "engines": [], "trackedInputs": [], "excludedVulnTypes": null, "depth": { "maxFunctionDepth": 0, "maxVariableTrack": 0 }, "customFilters": [], "exclusions": [ "test", "lib", "docs", "swagger", "angular", "node_modules", "bootstrap", "modernizer", "yui", "dojo", "xjs", "react", "plugins", "3rd", "build", "nuget" ], "patternMatching": [], "customRules": [], "diff": false, "includeFiltered": false, "ignoreStoredFP": false, "deepInputDiscovery": true, "almTrigger": "", "emailTrigger": "", "slackTrigger": "" } }'

# change wscli location to user home & update report location
wscli=/root/ws-sast/wscli
reportdir=/root/ws-sast/reports

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

# To retrieve reports afterwards, this can replace the script between the for loop if you do not create a report using the below during the scan
# --report --formats PDF --filename ${reportdir}/${repos}
# Replace values in raw data (-d) with your values

# SCAN_ID=$(curl -H "X-Auth-Token: ${SASTCLI_TOKEN}" ${SAST_SERVER}"/api/scans?query="${repo}| jq -r '.[0].id')
# curl --output ./reports/${repo} --request POST ${SAST_SERVER}'/api/scans/'${SCAN_ID}'/report?format=pdf' -H 'X-Auth-Token: '${SASTCLI_TOKEN} -H 'Content-Type: application/json' \
# -d '{ "company": "Stark Enterprises", "author": "Tony Stark", "email": "tony@stark.com", "description": "Example report", "type": "DefenseCode Default", "level": "technical" }'