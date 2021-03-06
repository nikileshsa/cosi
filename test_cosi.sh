#!/usr/bin/env bash

# Set to a non-empty value to print debugging messages
DBG_RUN=1
. $GOPATH/src/gopkg.in/dedis/cothority.v0/app/libtest.sh
STATICDIR=test

tails=8

main(){
    startTest
    build
    test Build
    test ServerCfg
    test SignFile
    test Check
    test Reconnect
    stopTest
}

testReconnect(){
    for s in 1 2; do
        setupServers 1
        dbgRun "Running first sign"
        echo "My Test Message File" > foo.txt
        testOK runCl 1 sign foo.txt
        dbgRun "Killing server $s"
        pkill -f "c srv$s/config"
        testFail runCl 1 sign foo.txt
        dbgRun "Starting server $s again"
        runSrv $s &
        sleep 1
        testOK runCl 1 sign foo.txt
        pkill -f ./cosi
    done
}

testCheck(){
    setupServers 1
    testOK runCl 1 check
}

testSignFile(){
    setupServers 1
    echo "Running first sign"
    echo "My Test Message File" > foo.txt
    echo "My Second Test Message File" > bar.txt
    runCl 1 sign foo.txt > /dev/null
    echo "Running second sign"
    runCl 1 sign foo.txt -o cl1/signature > /dev/null
    testOK runCl 1 verify foo.txt -s cl1/signature
    testFail runCl 1 verify bar.txt -s cl1/signature
    rm foo.txt
    rm bar.txt
}

testServerCfg(){
    runSrvCfg 1
    pkill cosi
    testFile srv1/config.toml
}

testBuild(){
    testOK ./cosi help
}

setupServers(){
    CLIENT=$1
    OOUT=$OUT
    OUT=/tmp/config
    SERVERS=cl$CLIENT/servers.toml
    rm -f srv1/*
    rm -f srv2/*
    runSrvCfg 1 
    tail -n 4 srv1/group.toml >  $SERVERS
    runSrvCfg 2 
    echo >> $SERVERS
    tail -n 4 srv2/group.toml >> $SERVERS
    runSrv 1 &
    runSrv 2 &
    OUT=$OOUT
}

runCl(){
    D=cl$1/servers.toml
    shift
    echo "Running Client with $D $@"
    ./cosi $@ -g $D
}

runSrvCfg(){
    echo -e "127.0.0.1:200$1\n$(pwd)/srv$1\n" | ./cosi server setup > $OUT
}

runSrv(){
    ./cosi -d $DBG_SRV server -c srv$1/config.toml
}

build(){
    BUILDDIR=$(pwd)
    if [ "$STATICDIR" ]; then
        DIR=$STATICDIR
    else
        DIR=$(mktemp -d)
    fi
    mkdir -p $DIR
    cd $DIR
    echo "Building in $DIR"
    if [ ! -x cosi ]; then
        go build -o cosi $BUILDDIR/*go
    fi
    for n in $(seq $NBR); do
        srv=srv$n
        rm -rf $srv
        mkdir $srv
        cl=cl$n
        rm -rf $cl
        mkdir $cl
    done
}

if [ "$1" == "-q" ]; then
  DBG_RUN=
  STATICDIR=
fi

main
