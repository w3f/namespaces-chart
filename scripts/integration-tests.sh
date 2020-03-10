#!/bin/bash

source /scripts/common.sh
source /scripts/bootstrap-helm.sh

wait_object_present(){
    local name=$1
    local kind=${2:pod}
    local TOTAL_WAIT_TIME=40
    local NEXT_WAIT_TIME=0

    until [ "$(kubectl get ${kind} | grep -m 1 ${name} | awk '{print $1}')" = "${name}" ] || [ $NEXT_WAIT_TIME -eq $TOTAL_WAIT_TIME ]; do
        echo "$(kubectl get ${kind} | grep -m 1 ${name})"
        echo "${kind}${name} not present yet..."
        sleep $(( NEXT_WAIT_TIME++ ))
    done

    if [ $NEXT_WAIT_TIME -eq $TOTAL_WAIT_TIME ]; then
        echo "${kind} ${name} not present in time, exiting"
        exit 1
    fi
}

run_tests() {
    echo Running tests...

    wait_object_present namespace1 namespace
    wait_object_present namespace2 namespace
}

teardown() {
    helm del nstest
}

main(){
    if [ -z "$KEEP_W3F_NAMESPACES" ]; then
        trap teardown EXIT
    fi

    cat > values.yaml <<EOF
namespaces:
- namespace1
- namespace2
EOF
    helm upgrade --install  -f ./values.yaml nstest ./charts/namespaces

    run_tests
}

main
