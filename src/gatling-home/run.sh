#!/bin/sh

# Copyright (c) 2019 Hiroshi Hayakawa <hhiroshell@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd `dirname $0`

CONCURRENCY_PER_LB=1
USERS=10
DURATION=20
SCENARIO=atpstore.atpstoreRead
DESCRIPTION="LBs=$(cat ./endpoints.txt | wc -l) | CONCURRENCY_PER_LB=$CONCURRENCY_PER_LB | USERS=$USERS | DURATION=$DURATION"

while read LB
do
    for i
    in `seq 1 $CONCURRENCY_PER_LB`
    do
        JAVA_OPTS="-Dusers=$USERS -Dduring=$DURATION -DbaseUrl=$LB" bin/gatling.sh -s $SCENARIO -rd "$DESCRIPTION" &
    done
done < ./endpoints.txt
