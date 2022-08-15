:no_entry: [DEPRECATED] This repository will be inaccessible starting January 9th, 2023.  

![Logo](https://whitesource-resources.s3.amazonaws.com/ws-sig-images/Whitesource_Logo_178x44.png)  

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

# GitLab Multi-Repo Scanner
The GitLab Multi-Repo Scanner (gitlab-scanner) is a bash utlity for scanning multiple code repositories from GitLab using the [dockerized unified agent](https://hub.docker.com/r/whitesourceft/dockerua)

## Supported Environments
- GitLab

## Supported Operating Systems
- **Linux (Bash):**	CentOS, Debian, Ubuntu, RedHat

## Prerequisites
- Docker

## Setup

### Clone & Provide Script Access
```
git clone https://github.com/whitesource-ft/ws-multi-repo-scanner.git & cd ws-multi-repo-scanner
chmod +x gitlab-scanner.sh
```
### GitLab Access
```
export GITLAB_TOKEN=<your-gitlab-personal-access-token>
export GITLAB_USER=<your-gitlab-username>
git config --global url."https://${GITLAB_USER}:${GITLAB_TOKEN}@gitlab.com".insteadOf "https://gitlab.com"
```
You can double-check your global git config by using ```git config --global --list```

### WhiteSource Access
```
export WS_APIKEY=<your-api-key>
export WS_USERKEY=<your-user-key>
```

## Execution
### Execution Instructions
```
./gitlab-scanner.sh gitlab.com <your-gitlab-group-id> $GITLAB_TOKEN
```

### Exit Codes

![Logo](https://whitesource-resources.s3.amazonaws.com/ws-sig-images/Whitesource_Logo_178x44.png)  

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

# WhiteSource SAST Multi-Repo Scanners
The WhiteSource SAST Multi-Repo Scanners (WS-SAST-Scanners) are a group of bash scripts for scanning multiple code repositories using WhiteSource SAST & ThunderScan.

## Supported Environments
- List of Git repositories


## Supported Operating Systems
- **Linux (Bash):**	CentOS, Debian, Ubuntu, RedHat

## Prerequisites
- git
- curl
- jq 
- tscli or wscli


## Execution
### Execution Instructions
- Individual script usage instructions are located within each script, but the general usage is the following where scanlist.txt is a list of git repositories for cloning
```
chmod +x script.sh
./script.sh scanlist.txt
```
- ws-sast-scanner - WS-SAST
- ts-scanner - ThunderScan script without templates
- ts-scanner-template - ThunderScan script that uses templates

### Exit Codes


