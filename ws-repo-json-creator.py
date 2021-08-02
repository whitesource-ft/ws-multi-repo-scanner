from github import Github
import os
import json
import sys

def get_repos():
    repos = []
    for repo in g.get_user().get_repos():
        if repo.fork:
           continue
        repos.append(repo.name)
        # TODO need to think if we should add only repos with the provided account name ; Script won't work without it
    return repos


def get_branches(repos):
    scmRepositories = []
    for repo in repos:
        full_repo_name = "{}/{}".format(account,repo)
        # TODO this is the place we need to think what to do with other accounts
        new_repo = g.get_repo(full_repo_name)
        branches = list(new_repo.get_branches())
        for branch in branches:
            a={}
            a['url'] = repo
            a['branch'] = branch.name
            scmRepositories.append(a)
    scm = {"scmRepositories": scmRepositories}
    return scm


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('[-] Please provide account and GH Token\n Example: MY_ACCOUNT TOKEN')
    account = sys.argv[1]
    token = sys.argv[2]
    g = Github(token)
    repos = get_repos()
    output_json = get_branches(repos)
    with open('scmRepos.json', 'w', encoding='utf-8') as f:
        json.dump(output_json, f)


