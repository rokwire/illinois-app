#!/bin/bash
#EXAMPLE: ./scripts/build_multi.sh "dev test"
ENVS=($1)
BRAND="Illinois" #TBD get from params and set "Illinois" as default
TAG="" #TBD get from params

function printEnvironmentUrls() {
    local ENV="$1"

    local VERSION=$(grep "version:" pubspec.yaml | sed -e 's/.* //' | sed -e 's/+.*//')
    local SHORT_VERSION_NAME=${VERSION%.*}
    local FLAVOR_ENV=$(tr '[:lower:]' '[:upper:]' <<<"${ENV:0:1}")${ENV:1} #Upper case the first letter

    if [ -z "$TAG" ] || [ "$TAG" = "" ]
    then
        BUILD_OUTPUT_NAME="$BRAND-$VERSION-$ENV"
    else
        BUILD_OUTPUT_NAME="$BRAND-$VERSION-$TAG-$ENV"
    fi
    
    local BRAND_NAME="$BRAND"
    if [ "$BRAND" = "Illinois" ]; then
        BRAND_NAME="UIUC"
    fi

    echo "$BRAND_NAME $SHORT_VERSION_NAME $FLAVOR_ENV $TAG Android"
    echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.apk"
    echo ""
    echo "$BRAND_NAME $SHORT_VERSION_NAME $FLAVOR_ENV $TAG iOS"
    echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.ipa"
    echo "itms-services://?action=download-manifest&url=https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.plist"
    echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.png"
    echo ""
}

printReport() {
    echo "########################################################################"
    echo "Generated URLs for the report"

    for ENV in "${ENVS[@]}"
    do
        printEnvironmentUrls $ENV
    done

    echo "########################################################################"
    echo ""
}

buildAll() {
    for ENV in "${ENVS[@]}"
    do
        echo "########################################################################"
        echo "BUILD" $ENV
        ./scripts/build.sh $BRAND $ENV all $TAG
        echo "########################################################################"
        echo ""
    done
}

printReport
buildAll
