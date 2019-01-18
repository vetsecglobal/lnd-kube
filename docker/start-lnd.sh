#!/usr/bin/env bash

# exit from script if error was raised.
set -e

scriptArgs="$@"

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" > /dev/stderr
    exit 0
}

# return is used within bash function in order to return the value.
return() {
    echo "$1"
}

# set_default function gives the ability to move the setting of default
# env variable from docker file to the script thereby giving the ability to the
# user override it durin container start.
set_default() {
    # docker initialized env variables with blank string and we can't just
    # use -z flag as usually.
    BLANK_STRING='""'

    VARIABLE="$1"
    DEFAULT="$2"

    if [[ -z "$VARIABLE" || "$VARIABLE" == "$BLANK_STRING" ]]; then

        if [ -z "$DEFAULT" ]; then
            error "You should specify default variable"
        else
            VARIABLE="$DEFAULT"
        fi
    fi

   return "$VARIABLE"
}

# Set default variables if needed.
RPCUSER=$(set_default "$RPCUSER" "devuser")
RPCPASS=$(set_default "$RPCPASS" "devpass")
#DEBUG=$(set_default "$DEBUG" "debug")
DEBUG=$(set_default "$DEBUG" "trace")
NETWORK=$(set_default "$NETWORK" "simnet")
CHAIN=$(set_default "$CHAIN" "bitcoin")
BACKEND="btcd"
if [[ "$CHAIN" == "litecoin" ]]; then
    BACKEND="ltcd"
fi

DEPLOYMENT_NAME_DIR=""
if [[ ! -z "$DEPLOYMENT_NAME" ]]; then
    DEPLOYMENT_NAME_DIR="/$DEPLOYMENT_NAME"
fi

kill_lnd() {
    pkill lnd
}


start_lnd() {

    echo "start_lnd debug1"

    exec lnd \
        --noseedbackup \
        --logdir="/data" \
        "--$CHAIN.active" \
        "--$CHAIN.$NETWORK" \
        "--$CHAIN.node"="btcd" \
        "--$BACKEND.rpccert"="/mnt/lk/shared/rpc/rpc.cert" \
        "--$BACKEND.rpchost"="lightning-kube-btcd.lightning-kube" \
        "--$BACKEND.rpcuser"="$RPCUSER" \
        "--$BACKEND.rpcpass"="$RPCPASS" \
        --rpclisten=`hostname -i`:10009 \
        --tlsextraip=`hostname -i` \
        --debuglevel="$DEBUG" \
        "$scriptArgs"

    echo "start_lnd debug2"

#    "$@"
#
#    echo "start_lnd debug3"
}

echo "debug1"

start_lnd &

echo "debug2"

kill_lnd

echo "debug3"

rm /root/.lnd/tls.cert
rm /root/.lnd/tls.key

echo "debug4"

start_lnd

echo "debug5"



#    --tlsextraip=0.0.0.0 \
#--rpclisten=localhost:10009 \

#    --datadir="/mnt/lk/lnd$DEPLOYMENT_NAME_DIR/data" \
#    --logdir="/mnt/lk/lnd$DEPLOYMENT_NAME_DIR/log" \

#    --macaroonpath="/mnt/lk/lnd$DEPLOYMENT_NAME_DIR/data/chain/bitcoin/simnet/admin.macaroon" \
