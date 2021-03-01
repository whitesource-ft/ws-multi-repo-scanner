![Logo](https://whitesource-resources.s3.amazonaws.com/ws-sig-images/Whitesource_Logo_178x44.png)  

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub release](https://img.shields.io/github/release/whitesource-ft/wss-template.svg)](https://github.com/whitesource-ft/wss-template/releases/latest)  
# WhiteSource Multi-Repo Scanner
The WhiteSource Multi-Repo Scanner (ws-multi-repo-scanner) is a command-line tool for scanning multiple code repositories.  

## Supported Environments
- Azure DevOps
- Bitbucket
- GitLab


## Supported Operating Systems
- **Linux (Bash):**	CentOS, Debian, Ubuntu, RedHat
- **Windows (PowerShell):**	10, 2012, 2016

## Prerequisites
- Java JDK 8 or 11
- Python 3.5 or later

multi-repo-scanner package (contains: wss-unified-agent.jar, wss-unified-agent.config, params.config, multi-repo-scanner.py, requirements.txt).

## Setup
### Installation
1. Download the **ws-multi-repo-scanner** package to your computer and extract it to its own directory
2. Open the command line, navigate into the tool's directory and execute the command:  
    `pip install -r requirements.txt`  
    (if you have more than one version of PIP, use `pip3`)
3. Edit the **params.config** file and update the appropriate configuration parameters

### Configuration Parameters
| Section | Parameter | Type | Required | Description |
| :--- | :--- | :---: | :---: | :--- |
| General | **RepoType** | enum | Yes | AzureRepos &#124; Bitbucket &#124; GitLab |
| General | **ApiKey** | string | Yes | WhiteSource organization API Key |
| General | **WssUrl** | string | Yes | WhiteSource Server URL |
| General | **RepoAuthToken** | string | Yes | Repository user auth token (see details below) |
| General | **RepoUsername** | string | Yes | Repository username (for repo API) |
| General | **RepoProject** | string | Yes | WhiteSource product name (corresponding to the Azure project name) |
| General | **RepoBranch** | list | No | Branches to scan (Comma/space separated list. Defaults to "master") |
| General | **RepoTag** | list | No | Tags to scan (Comma/space separated list) |
| General | **MaxReposToScan** | int | No | Maximum number of repositories to scan (defaults to 10) |
| AzureDevOps | **AzureUrl** | string | No | Azure Server URL (optional for TFS usage). Default: https://dev.azure.com/{organization}/{project} |
| AzureDevOps | **RepoCloneToken** | string | Yes | Repo git clone credentials/password (from the repo, click Clone -> Generate Git Credentials) |
| AzureDevOps | **RepoOrganization** | string | Yes | Azure organization name |
| GitLab | **RepoGroupId** | string | Yes | GitLab Group Id |

#### Obtaining RepoAuthToken
- Azure DevOps: see [Personal Access Token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page)
- Bitbucket: see [Authentication Methods](https://developer.atlassian.com/bitbucket/api/2/reference/meta/authentication)
- GitLab: see [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)  

## Execution
### Execution Instructions
Open the command line, navigate into the tool's directory and execute the command:  
    `python multi-repo-scanner.py`  
    (if you have more than one version of Python, use `python3`)  

### Exit Codes
| Code | Description |
| :---: | :--- |
| 0 | Success |
| -1 | Repository connection error |
| -5 | Failure |
\* For non-zero exit codes, see log for details
