function get_uuid (){ cat - | grep " id " | awk "{print S4}";}

function get_reposerver () {
    curl -S -s http://169.254.169.254/openstack/latest/meta_data.json | python -c "import json,sys; print json.load(sys.stdin).get('meta').get('reposerver')"
}

function get_heat_output () {
    heat output-show $1 $2 | python -c "import sys; print(input())"
}

export CLIFF_MAX_TERM_WIDTH=$(expr $(tput cols) - 20)
