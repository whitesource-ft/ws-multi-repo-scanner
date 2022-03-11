# Prequisities = tscli 
# Usage
    # ./ts-scanner.sh scanlist.txt
# scanlist is a list of git repos

# update the below variables with your values
export THUNDERSCAN_API_URL=<your thunderscan api url>
export THUNDERSCAN_API_TOKEN=<your api token>

# Run the below part of the script only once to create a template for common exclusions
curl --location --request POST ${THUNDERSCAN_API_URL}'/api/templates' -H 'X-Auth-Token: '${THUNDERSCAN_API_TOKEN} -H 'Content-Type: application/json'  \
-d '{ "name": "common-excludes", "parameters": { "target": { "type": "", "source": "", "path": "" }, "engines": [], "trackedInputs": [], "excludedVulnTypes": null, "depth": { "maxFunctionDepth": 0, "maxVariableTrack": 0 }, "customFilters": [], "exclusions": [ "test", "lib", "docs", "swagger", "angular", "node_modules", "bootstrap", "modernizer", "yui", "dojo", "xjs", "react", "plugins", "3rd", "build", "nuget" ], "patternMatching": [], "customRules": [], "diff": false, "includeFiltered": false, "ignoreStoredFP": false, "deepInputDiscovery": true, "almTrigger": "", "emailTrigger": "", "slackTrigger": "" } }'

# update the below location with your tscli location
wscli=/opt/thunderscan/tscli


file=$1
lines=`cat ${file}`
for line in $lines; do
    repo=$(echo ${line} | awk -F "/" '{print $5}' | awk -F "." '{print $1}')
    branch=$(git ls-remote --symref ${line} HEAD | awk '/^ref:/ {sub(/refs\/heads\//, "", $2); print $2}')
    echo "Scanning repo=${repo} branch=${branch}"
    ${wscli} --git ${line} --branch ${branch} --name ${repo}-${branch} --parent ${repo} --autoparent true
    echo "Scan completed for repo=${repo} branch=${branch}" >> completedscanned.txt
done
