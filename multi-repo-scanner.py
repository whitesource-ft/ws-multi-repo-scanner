#!/usr/bin/python3
import enum
import os
import json
import sys
import base64
import requests
import logging
import subprocess
from threading import Thread
from json import JSONEncoder
from configparser import ConfigParser

# todo change variable names (syntax)
# todo BB - check for increasing the maxPage

# Constants
DEFAULT_WSS_URL = "https://saas-eu.whitesourcesoftware.com/agent"
GITLAB = "Gitlab"
BITBUCKET = "Bitbucket"
AZURE_REPOS = "AzureRepos"
DOUBLE_SLASH = "\\"
GENERAL_SETTINGS = 'General'
AZURE_REPO_SETTINGS = 'AzureDevOps'
GITLAB_REPO_SETTINGS = 'GitLab'
WRITE_MODE = "w"
REPOSITORIES_JSON = "repositories-{partition}.json"
UTF_8_ENCODING = "utf-8"
COLON_SEPARATOR = ":"

AZURE_REPOS_URL = "{serverUrl}/{organization}/{project}/_apis/git/repositories?api-version=6.0"
AZURE_DEVOPS_CLOUD_URL = "https://dev.azure.com"
BITBUCKET_URL = "https://api.bitbucket.org/2.0/repositories/{username}"
GITLAB_URL = "https://gitlab.com/api/v4/groups/{repoGroupId}/projects"


# Classes
class RepoType(enum.Enum):
    AzureRepo = 1
    BitBucket = 2
    Gitlab = 3


class Configuration:
    def __init__(self):
        # logging settings
        logging.basicConfig()
        logging.getLogger().setLevel(logging.INFO)
        logging.info("Fetching and validating configuration...")

        # read config params
        config = ConfigParser()
        config.optionxform = str
        config.read('./params.config')

        # fetch general settings
        self.apiKey = config.get(GENERAL_SETTINGS, 'ApiKey')
        self.wssUrl = config.get(GENERAL_SETTINGS, 'WssUrl', fallback=DEFAULT_WSS_URL)
        self.repoBranch = config.get(GENERAL_SETTINGS, 'RepoBranch', fallback='master')
        self.repoTag = config.get(GENERAL_SETTINGS, 'RepoTag')
        repo_type = config.get(GENERAL_SETTINGS, 'RepoType')
        self.parallelReposScan = int(config.get(GENERAL_SETTINGS, 'ParallelReposScan', fallback=10))
        self.maxReposToScan = int(config.get(GENERAL_SETTINGS, 'MaxReposToScan', fallback=10))

        # scm.user
        self.repoUsername = config.get(GENERAL_SETTINGS, 'RepoUsername')
        self.repoAuthToken = config.get(GENERAL_SETTINGS, 'RepoAuthToken')
        self.project = config.get(GENERAL_SETTINGS, 'RepoProject')

        # determine and populate SCM settings
        if repo_type.__eq__(AZURE_REPOS):
            # init Azure Repos params
            logging.info("Initializing Azure Repos parameters...")
            self.repoType = RepoType.AzureRepo
            self.azureURL = config.get(AZURE_REPO_SETTINGS, 'AzureURL', fallback=AZURE_DEVOPS_CLOUD_URL)
            # scm.pass
            self.repoCloneToken = config.get(AZURE_REPO_SETTINGS, 'RepoCloneToken')
            self.organization = config.get(AZURE_REPO_SETTINGS, 'RepoOrganization')
        elif repo_type.__eq__(BITBUCKET):
            # init BitBucket params
            self.repoType = RepoType.BitBucket
        elif repo_type.__eq__(GITLAB):
            # init BitBucket params
            self.repoType = RepoType.Gitlab
            self.repoGroupId = config.get(GITLAB_REPO_SETTINGS, 'RepoGroupId')
        else:
            logging.info("Wrong Repo Type. Existing...")
            sys.exit(-5)


class Repo:
    def __init__(self, url, repo_name):
        self.url = url
        self.repoName = repo_name


class ScmRepository:
    def __init__(self, url, branch, tag):
        self.url = url
        self.branch = branch
        self.tag = tag


# todo check if can be serealized differently
class ScmRepositories:
    def __init__(self, scmRepositories):
        self.scmRepositories = scmRepositories

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)


class MyEncoder(JSONEncoder):
    def default(self, o):
        return o.__dict__


# Methods
def main():
    # read the configuration
    config = Configuration()

    # fetch relevant repositories
    if config.repoType == RepoType.AzureRepo:
        repos = getAzureRepos(config)
    elif config.repoType == RepoType.BitBucket:
        repos = getBitbucketRepos(config)
    else:
        repos = getGitlabRepos(config)

    partition = 1
    for repo in repos:
        scmRepositories = []
        scmRepositories.append(ScmRepository(repo.url, config.repoBranch, config.repoTag))
        thread = Thread(target=writeToFileAndExecuteScan, args=(
            ScmRepositories(scmRepositories), repo.repoName, config, partition))
        thread.start()
        partition += 1


def writeToFileAndExecuteScan(scmRepositories, repoName, config, partition=1):
    if len(scmRepositories.scmRepositories) > 0:
        encodedJson = MyEncoder().encode(scmRepositories)
        s = json.dumps(encodedJson).replace(DOUBLE_SLASH, "")[1:-1]
        filename = REPOSITORIES_JSON.format(partition=partition)
        open(filename, WRITE_MODE).write(s)
        # repositories.json file has been created by now
        executeScan(filename, repoName, config, partition)


def executeScan(repositoriesFile, projectName, config, partition):
    logging.info("==== Starting #%d WhiteSource scan (%s) ====", partition, projectName)
    if config.repoType == RepoType.AzureRepo:
        scmPass = config.repoCloneToken
    else:
        scmPass = config.repoAuthToken

    ws_env = {**os.environ, **{"WS_SCM_USER": config.repoUsername,
                               "WS_SCM_PASS": scmPass}}
    subprocess.run(['java', '-jar', 'wss-unified-agent.jar', '-c', 'wss-unified-agent.config',
                    '-apiKey', config.apiKey, '-project', projectName, '-wss.Url', config.wssUrl,
                    '-product', config.project, '-scm.repositoriesFile', repositoriesFile], env=ws_env)
    # todo return code
    os.remove(repositoriesFile)

def getGitlabRepos(config):
    logging.info("Fetching Gitlab repositories...")
    url = GITLAB_URL.format(repoGroupId=config.repoGroupId)
    headers = {'Authorization': 'Bearer %s' % config.repoAuthToken}
    response = requests.get(url, headers=headers)
    repos = []

    if response.status_code == 200:
        logging.info("Got 200 HTTP response code from %s" % url)
        json_data = json.loads(response.text)
        for repo in json_data:
            if len(repos) >= config.maxReposToScan:
                break
            repos.append(Repo(repo['http_url_to_repo'], repo['name']))
    else:
        logging.error("An error occurred. Got %d status code, reason: %s", response.status_code, response.reason)
        sys.exit(-1)
    return repos

def getBitbucketRepos(config):
    logging.info("Fetching BitBucket repositories...")
    url = BITBUCKET_URL.format(username=config.repoUsername)
    headers = {'Authorization': 'Bearer %s' % config.repoAuthToken}
    response = requests.get(url, headers=headers)
    repos = []

    if response.status_code == 200:
        logging.info("Got 200 HTTP response code from %s" % url)
        json_data = json.loads(response.text)
        for repo in json_data['values']:
            if len(repos) >= config.maxReposToScan:
                break
            repos.append(Repo(repo['links']['clone'][0]['href'], repo['name']))
    else:
        logging.error("An error occurred. Got %d status code, reason: %s", response.status_code, response.reason)
        sys.exit(-1)
    return repos


def getAzureRepos(config):
    logging.info("Fetching Azure repositories...")
    url = AZURE_REPOS_URL.format(serverUrl=config.azureURL, organization=config.organization, project=config.project)
    headers = {'Authorization': 'Basic %s' % generateEncodedAuthToken(config.repoUsername, config.repoAuthToken)}
    response = requests.get(url, headers=headers)
    repos = []

    if response.status_code == 200:
        logging.info("Got 200 HTTP response code from %s" % url)
        json_data = json.loads(response.text)
        for repo in json_data['value']:
            if len(repos) >= config.maxReposToScan:
                break
            repos.append(Repo(repo['remoteUrl'], repo['name']))
    else:
        logging.error("An error occurred. Got %d status code, reason: %s", response.status_code, response.reason)
        sys.exit(-1)
    return repos


def generateEncodedAuthToken(username, token):
    token = username + COLON_SEPARATOR + token
    tempToken = base64.b64encode(bytes(token, UTF_8_ENCODING))
    # remove bytes
    return str(tempToken)[2:-1]


# to use when UA will create a project per repository
# def mainTemp():
#     # read the configuration
#     config = Configuration()
#     scmRepositories = []
#
#     # fetch relevant repositories
#     if config.repoType == RepoType.AzureRepo:
#         repos = getAzureRepos(config)
#         for repo in repos:
#             scmRepositories.append(ScmRepository(repo.url, config.repoBranch, config.repoTag))
#
#
#     if len(scmRepositories) > config.parallelReposScan:
#         counter = 0
#         partition = 1
#         while counter <= len(scmRepositories):
#             thread = Thread(target=writeToFileAndExecuteScan, args=(ScmRepositories(scmRepositories[counter:counter + config.parallelReposScan]), partition))
#             thread.start()
#             counter+=config.parallelReposScan
#             partition+=1
#     else:
#         writeToFileAndExecuteScan(ScmRepositories(scmRepositories))


if __name__ == '__main__':
    main()
    sys.exit(0)
