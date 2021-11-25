![Logo](https://whitesource-resources.s3.amazonaws.com/ws-sig-images/Whitesource_Logo_178x44.png)  

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

# WhiteSource Multi-Repo Scanner
The WhiteSource Multi-Repo Scanner (ws-multi-repo-scanner) is a bash utlity for scanning multiple code repositories using [dockerized unified agent](https://hub.docker.com/r/whitesourceft/dockerua)

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

