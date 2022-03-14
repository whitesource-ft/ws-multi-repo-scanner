# Prequisities = tscli curl jq
# Usage
    # ./ts-scanner.sh scanlist.txt
# scanlist is a list of git repos
# mkdir /opt/thunderscan/reports

# update the below variables with your values
export THUNDERSCAN_API_URL=<your thunderscan api url>
export THUNDERSCAN_API_TOKEN=<your api token>

# Run the below part of the script only once to create a template for common exclusions
curl --location --request POST ${THUNDERSCAN_API_URL}'/api/templates' -H 'X-Auth-Token: '${THUNDERSCAN_API_TOKEN} -H 'Content-Type: application/json'  \
-d '{ "name": "common-excludes", "parameters": { "target": { "type": "", "source": "", "path": "" }, "engines": [], "trackedInputs": [], "excludedVulnTypes": null, "depth": { "maxFunctionDepth": 0, "maxVariableTrack": 0 }, "customFilters": [], "exclusions": [ "test", "lib", "docs", "swagger", "angular", "node_modules", "bootstrap", "modernizer", "yui", "dojo", "xjs", "react", "plugins", "3rd", "build", "nuget" ], "patternMatching": [], "customRules": [], "diff": false, "includeFiltered": false, "ignoreStoredFP": false, "deepInputDiscovery": true, "almTrigger": "", "emailTrigger": "", "slackTrigger": "" } }'

# update the below location with your tscli & report location
wscli=/opt/thunderscan/tscli
reportdir=/opt/thunderscan/reports


file=$1
lines=`cat ${file}`
for line in $lines; do
    repo=$(echo ${line} | awk -F "/" '{print $5}' | awk -F "." '{print $1}')
    branch=$(git ls-remote --symref ${line} HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    echo "Scanning repo=${repo} branch=${branch}"
    ${wscli} --git ${line} --branch ${branch} --name ${repo}-${branch} --parent ${repo} --autoparent true
    echo "Scan completed for repo=${repo} branch=${branch}" >> completedscanned.txt
done

# To retrieve reports afterwards, this can replace the script between the for loop if you do not create a report using the below during the scan
# --report --formats PDF --filename ${reportdir}/${repos}
# Replace values in raw data (-d) with your values

# SCAN_ID=$(curl -H "X-Auth-Token: ${THUNDERSCAN_API_TOKEN}" ${THUNDERSCAN_API_URL}"/api/scans?query="${repo}| jq -r '.[0].id')
# curl --output ./reports/${repo} --request POST ${THUNDERSCAN_API_URL}'/api/scans/'${SCAN_ID}'/report?format=pdf' -H 'X-Auth-Token: '${THUNDERSCAN_API_TOKEN} -H 'Content-Type: application/json' \
# -d '{ "company": "Stark Enterprises", "author": "Tony Stark", "email": "tony@stark.com", "description": "Example report", "type": "DefenseCode Default", "level": "technical" }'