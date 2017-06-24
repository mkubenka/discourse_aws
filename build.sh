#!/bin/bash -ex

if [ ! -d "discourse_docker" ]; then
    git clone https://github.com/discourse/discourse_docker.git
else
    (cd discourse_docker && git pull --rebase)
fi

source ./common-variables.sh

version_label=v`date +"%Y%m%d-%H%M%S"`
docker_tag=$docker_registry/$docker_repository:$version_label

image=$(grep image=discourse discourse_docker/launcher | cut -d= -f2)
docker_path=`which docker.io || which docker`
$docker_path history $image >/dev/null 2>&1 || $docker_path pull $image

# generate discourse_docker/containers/app.yml

templates=/pwd/containers/app.yml
if [ -e ../containers/app.yml ]; then
    templates+=" /userconf/containers/app.yml"
fi
$docker_path \
    run \
    --rm \
    -v `pwd`/../:/userconf \
    -v `pwd`:/pwd \
    $image \
    /usr/local/bin/ruby \
    -I /pups/lib \
    /pwd/merge_templates.rb \
    /pwd/discourse_docker/containers/app.yml \
    $templates

(
    cd discourse_docker
    ./launcher bootstrap app
)

docker tag local_discourse/app $docker_tag

$(aws ecr get-login --no-include-email)

aws ecr describe-repositories --repository-name $docker_repository > /dev/null 2>&1 && rc=$? || rc=$?
if [ $rc -ne 0 ]; then
    aws ecr create-repository --repository-name $docker_repository
fi

docker push $docker_tag

# todo: remove unused images
