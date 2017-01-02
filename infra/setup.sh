#!/bin/bash

sudo htpasswd -b /etc/origin/master/htpasswd dev1 dev1
sudo htpasswd -b /etc/origin/master/htpasswd test1 test1

oc login -u system:admin
oc project openshift
oc delete is oc-jenkins
oc create is oc-jenkins
oc tag --source=docker --scheduled=true omallo/oc-jenkins:latest openshift/oc-jenkins:latest

oc login -u admin -p admin
oc new-project cicd
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n rubex-dev
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n rubex-test

oc login -u admin -p admin
oc new-project rubex-dev
oc policy add-role-to-user edit dev1 -n rubex-dev
oc policy add-role-to-user view test1 -n rubex-dev

oc login -u admin -p admin
oc new-project rubex-test
oc policy add-role-to-user edit test1 -n rubex-test
oc policy add-role-to-group system:image-puller system:serviceaccounts:rubex-test -n rubex-dev

oc process \
    -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json \
    -v MEMORY_LIMIT=2Gi \
    -v JENKINS_IMAGE_STREAM_TAG=oc-jenkins:latest \
    | oc apply -f -

# ---

oc login -u dev1 -p dev1
oc project rubex-dev

oc new-app --name frontend ruby:2.3~https://github.com/omallo/ruby-ex # then: configure GitHub webhook
oc expose service frontend

oc tag rubex-dev/frontend:latest rubex-dev/frontend:test

oc login -u test1 -p test1
oc project rubex-test

oc new-app rubex-dev/frontend:test
oc expose service frontend

oc login -u dev1 -p dev1
oc project rubex-dev

oc tag rubex-dev/frontend:latest rubex-dev/frontend:test
