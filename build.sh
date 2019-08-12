#/bin/sh
cd `dirname $0`

# valiables
export ARTIFACT_NAME=oci-loadtester

# clean up
rm -rf target

# build
mkdir target
cd src

zip --verbose \
    --recurse-paths \
    ../target/${ARTIFACT_NAME} *
