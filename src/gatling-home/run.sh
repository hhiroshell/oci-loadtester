#!/bin/sh

USERS=10
DURATION=20
CONCURRENCY_PER_LB=1
DESCRIPTION="LBs=$(cat ./endpoints.txt | wc -l) | concurrency-per-lb=1 | users=10 | duration=20"

while read LB
do
    for i
    in `seq 1 $CONCURRENCY_PER_LB`
    do
        JAVA_OPTS="-Dusers=$USERS -Dduring=$DURATION -DbaseUrl=$LB" bin/gatling.sh -s atpstore.atpstoreRead -rd "$DESCRIPTION" &
    done
done < ./endpoints.txt
