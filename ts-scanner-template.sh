# Prequisities = tscli curl jq git
    # chmod +x ./ts-scanner-bb.sh
    # Run the below commented script only once to create a template for common exclusions
    # curl --location --request POST ${THUNDERSCAN_API_URL}'/api/templates' -H 'X-Auth-Token: '${THUNDERSCAN_API_TOKEN} -H 'Content-Type: application/json'  \
    # -d '{ "name": "common-excludes", "parameters": { "target": { "type": "", "source": "", "path": "" }, "engines": [], "trackedInputs": [], "excludedVulnTypes": null, "depth": { "maxFunctionDepth": 0, "maxVariableTrack": 0 }, "customFilters": [], "exclusions": [ "test", "lib", "docs", "swagger", "angular", "node_modules", "bootstrap", "modernizer", "yui", "dojo", "xjs", "react", "plugins", "3rd", "build", "nuget" ], "patternMatching": [], "customRules": [], "diff": false, "includeFiltered": false, "ignoreStoredFP": false, "deepInputDiscovery": true, "almTrigger": "", "emailTrigger": "", "slackTrigger": "" } }'

# Usage
    # ./ts-scanner-bb.sh scanlist.txt
# scanlist is a list of git repos
# mkdir /opt/thunderscan/reports && mkdir /opt/thunderscan/templates

# update the below variables with your values
export THUNDERSCAN_API_URL=<your thunderscan api url>
export THUNDERSCAN_API_TOKEN=<your api token>

# update the below location with your locations
wscli=/opt/thunderscan/tscli
reportdir=/opt/thunderscan/reports
templatedir=/opt/thunderscan/templates
tstemplate=/opt/thunderscan/common-excludes.json


# find the template ID & save to .json file for use
TS_TEMPLATE_ID=$(curl -H "X-Auth-Token: ${THUNDERSCAN_API_TOKEN}" "${THUNDERSCAN_API_URL}/api/templates" | jq -r '.[] | select(.name=="common-excludes").id')
curl -H "X-Auth-Token: ${THUNDERSCAN_API_TOKEN}" "${THUNDERSCAN_API_URL}/api/templates/${TS_TEMPLATE_ID}" > ${tstemplate}

# for loop for scanning or reporting

file=$1
lines=`cat ${file}`
for line in $lines; do
    rm -rf ./clonefolder
    echo "Cloning ${line}"
    git clone $line ./clonefolder
    repo=$(basename -s .git $line)
    branch=$(git --git-dir ./clonefolder/.git branch --show-current)
    echo "Found repo=${repo} branch=${branch}"
    echo "creating scan specific template"
    jq --arg name "${repo}-${branch}" '.name |= $name' ${tstemplate} > ${templatedir}/${repo}-${branch}.json
    echo "Scanning repo=${repo} branch=${branch} using ${templatedir}/${repo}-${branch}.json"
    ${wscli} --upload ./clonefolder --template ${templatedir}/${repo}-${branch}.json --parent ${repo} --autoparent true
    echo "Scan completed for repo=${repo} branch=${branch}" >> completedscanned.txt
done

# To retrieve reports afterwards, this can replace the script between the for loop if you do not create a report using the below during the scan
# --report --formats PDF --filename ${reportdir}/${repos}
# Replace values in raw data (-d) with your values

# SCAN_ID=$(curl -H "X-Auth-Token: ${THUNDERSCAN_API_TOKEN}" ${THUNDERSCAN_API_URL}"/api/scans?query="${repo}| jq -r '.[0].id')
# curl --output ${reportdir}/${repo}.html --request POST ${THUNDERSCAN_API_URL}'/api/scans/'${SCAN_ID}'/report?format=html' -H 'X-Auth-Token: '${THUNDERSCAN_API_TOKEN} -H 'Content-Type: application/json' \
# -d '{ "company": "Stark Enterprises", "author": "Tony Stark", "email": "tony@stark.com", "description": "Example report", "type": "DefenseCode Default", "level": "technical" }'