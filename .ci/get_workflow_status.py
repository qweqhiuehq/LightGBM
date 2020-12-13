# coding: utf-8
import json
from os import environ
from sys import argv, exit
from time import sleep
try:
    from urllib import request
except ImportError:
    import urllib2 as request


def get_runs(workflow_name):
    pr_runs = []
    if environ.get("GITHUB_EVENT_NAME", "") == "pull_request":
        pr_number = int(environ.get("GITHUB_REF").split('/')[-2])
        req = request.Request(url="{}/repos/{}/pulls/{}/comments?sort=created&direction=desc".format(environ.get("GITHUB_API_URL"),
                                                                                                     environ.get("GITHUB_REPOSITORY"),
                                                                                                     pr_number),
                              headers={"Accept": "application/vnd.github.v3+json"})
        url = request.urlopen(req)
        data = json.loads(url.read().decode('utf-8'))
        url.close()
        pr_runs = [i for i in data
                   if i['user']['id'] == 25141164
                   and i['body'].startswith('Workflow **{}** has been triggered!'.format(workflow_name))]
    return pr_runs


def get_status(runs):
    status = 'ok'
    for run in runs:
        body = run['body']
        if "Status: " in body:
            if "Status: skipped" in body:
                continue
            if "Status: failure" in body:
                status = 'fail'
                break
            if "Status: success" in body:
                status = 'ok'
                break
        else:  # in progress
            status = 'rerun'
            break
    return status


if __name__ == "__main__":
    workflow_name = argv[1]
    while True:
        status = get_status(get_runs(workflow_name))
        if status != 'rerun':
            break
        sleep(60)
    if status == 'fail':
        exit(1)
