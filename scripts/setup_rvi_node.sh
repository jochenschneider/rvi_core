#!/bin/sh
#
# Copyright (C) 2014, Jaguar Land Rover
#
# This program is licensed under the terms and conditions of the
# Mozilla Public License, version 2.0.  The full text of the 
# Mozilla Public License is at https://www.mozilla.org/MPL/2.0/
#

#
# Setup an RVI release with a configuration file.
#
# This script will setup a directory with with the same name
# as the release name. The script uses Ulf Wiger's setup application 
# (github.com/Feuerlabs/setup) to generate the release.
# 
# With the -d argument, a developer release will be built with
# only
#
#  Once setup, the RVI node can be started with ./rvi_node <release_na,e?
#
#  Please note that the generated release will depend on the built
#
#  In order to create a standalone release, use create_rvi_release.sh
#

alias realpath="python -c 'import os, sys; print os.path.realpath(sys.argv[1])'"
SELF_DIR=$(dirname $(realpath "$0"))
TOP_DIR=$(dirname $SELF_DIR)

SETUP_GEN=$SELF_DIR/setup_gen  # Ulf's kitchen sink setup utility

usage() {
    echo "Usage: $0 [-d] -n node_name -c config_file"
    echo "  -n node_name     Specify the name of the rvi node to setup"
    echo 
    echo "  -c config_file   Specifies the setup config file to use when setting "
    echo "                   up the node"
    echo 
    echo "  -d               Create a development release. See below."
    echo 
    echo "The generated node will be created in a subdirectory with the same"
    echo "name as the node name."
    echo 
    echo "The created node can be started with: $SELF_DIR/rvi_node -n node_name"
    echo 
    echo "If the node was created with the -d flag, you need to start"
    echo "the node with $SELF_DIR/rvi_node -d -n node_name"
    echo
    echo "Configuration file examples can be found in hvac_demo/vehicle.config"
    echo 
    echo "The -d flag creates a development release that uses the erlang "
    echo "binaries found in ebin/ and deps/*/ebin. This means that new builds,"
    echo "created by make, can be run directly through "
    echo "$SELF_DIR/rvi_node -n node_name without having to run ./setup_rvi_node.sh ."
    echo
    echo "If the -d flag is omitted, the release will be self-contained in the "
    echo "newly created subdirectory rel/[node_name]."
    echo "This directory, containing a standard erlang reltool release, "
    echo "including the erlang runtime system, can be copied as a stand alone"
    echo "system to a destination node."
    echo 
    echo "Configuration file examples can be found in hvac_demo/vehicle.config"
    exit 1
}


build_type=rel
while getopts "dn:c:" o; do
    case "${o}" in
        n)
            NODE_NAME=${OPTARG}
            ;;
        c)
            CONFIG_NAME=${OPTARG}
            ;;
        d)
            build_type=dev
            ;;

        *)
            usage
            ;;
    esac
done

if [ -z "${NODE_NAME}" ] ; then
    echo "Missing -n flag"
    usage
fi
if [ -z "${CONFIG_NAME}" ] ; then
    echo "Missing -c flag"
    usage
fi

export ERL_LIBS=$TOP_DIR/components:$TOP_DIR/deps:$ERL_LIBS:$TOP_DIR 
echo "ERL_LIBS=$ERL_LIBS"
echo  "Setting up node $NODE_NAME."
rm -rf $NODE_NAME
setupres=$( $SETUP_GEN $NODE_NAME $CONFIG_NAME $NODE_NAME -pa $TOP_DIR/ebin )
if [ -z "${setupres}" ]
then

    if [ "${build_type}" = "dev" ]
    then
	echo "RVI Node $NODE_NAME has been setup."
	echo "Launch with $SELF_DIR/rvi_node.sh -n $NODE_NAME"
	exit
    else
	echo "Building stand alone release for $NODE_NAME"
	# Copy the newly created config file.
	rm -rf rel/$NODE_NAME
	cp $NODE_NAME/sys.config rel/files/sys.config
	./rebar generate 
	# Rename the release after the node name
	mv rel/rvi_core rel/$NODE_NAME
	echo "Stand alone release for $NODE_NAME created under project "
	echo "root directory's ./rel/$NODE_NAME."
	echo
	echo "Start:              ./rel/$NODE_NAME/bin/rvi start"
	echo "Attach console:     ./rel/$NODE_NAME/bin/rvi attach"
	echo "Stop:               ./rel/$NODE_NAME/bin/rvi stop"
	echo "Start console mode: ./rel/$NODE_NAME/bin/rvi console"
	echo 
	echo "Start dev mode:     ./rvi_node.sh -n $NODE_NAME"
	echo 
	echo "./rel/$NODE_NAME can be copied and installed on its destination host."
    fi
else
    >&2 echo $setupres
    exit 1
fi

exit 0

