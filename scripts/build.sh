#!/bin/bash
help() {
    echo ""
    echo "SETUP"
    echo "Install qrencode: brew install qrencode"
    echo ""
    echo "Usage: ./scripts/build.sh {BRAND} {ENV} {PLATFORM}"
    echo "{BRAND} brand name | Default: Illinois if the param is missing or empty"
    echo "{ENV} Environment name Values: dev|prod|test Default: dev"
    echo "{PLATFORM} Target platform. Values: all|ios|android Default: all"
    echo "{TAG} Designed for custom build names. Default empty"
    echo ""
    echo ""
}

printUtputUrls() {
    echo "########################################################################"
    echo "Generated URLs for the report"
    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
      #echo "$BRAND $VERSION $FLAVOR_ENV $TAG Android:"
      echo "$BRAND_NAME $SHORT_VERSION_NAME $FLAVOR_ENV $TAG Android"
      echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.apk"
      echo ""
    fi
    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    #echo "$BRAND $VERSION $FLAVOR_ENV $TAG iOS:"
    echo "$BRAND_NAME $SHORT_VERSION_NAME $FLAVOR_ENV $TAG iOS"
    echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.ipa"
    echo "itms-services://?action=download-manifest&url=https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.plist"
    echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.png"
    echo ""
    echo "########################################################################"
    fi
}

cleanupResources() {
    echo "Calling cleanup resource script"
    ./scripts/cleanup_app_resources.sh
    echo "Cleanup resource script finished"
}

prebuild() {
    echo "Calling prebuild_illinois resource script"
    ./scripts/prebuild_illinois.sh
    echo "prebuild_illinois script finished"
}


help
cleanupResources
prebuild

CURRENT_DIR=$(PWD)
FILE_PUBSPEC=$(cat pubspec.yaml)

BRAND="$1"
ENV="$2"
PLATFORM="$3"
TAG="$4"

if [ -z "$BRAND" ]
then
      BRAND="Illinois"
      echo "The BRAND param is empty. Use default value: $BRAND"
fi
if [ -z "$ENV" ]
then
      ENV="dev"
      echo "The ENV param is empty. Use default value: $ENV"
fi
if [ -z "$PLATFORM" ]
then
      PLATFORM="all"
      echo "The PLATFORM param is empty. Use default value: $PLATFORM"
fi

#Custom naming
ENV_NAME="$ENV"
if [ "$ENV" = "test" ]; then
    ENV_NAME="tst"
fi
BRAND_NAME="$BRAND"
if [ "$BRAND" = "Illinois" ]; then
    BRAND_NAME="UIUC"
fi

cd ios
BUNDLE_ID=$(xcodebuild -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk -F ' = ' '{print $2}')
cd ..

TEMPLATE_BRAND="{{BRAND}}"
TEMPLATE_VERSION="{{VERSION}}"
TEMPLATE_ENV="{{ENV}}"
TEMPLATE_BUNDLE_ID="{{BUNDLE_ID}}"
BUILD_DIR="${CURRENT_DIR}/build"
OUTPUT_DIR="${BUILD_DIR}/_output"
FLAVOR_ENV=$(tr '[:lower:]' '[:upper:]' <<<"${ENV:0:1}")${ENV:1} #Upper case the first letter
FLAVOUR_ENV_NAME=$(tr '[:lower:]' '[:upper:]' <<<"${ENV_NAME:0:1}")${ENV_NAME:1} #Upper case the first letter
APK_BUILD_PATH="${BUILD_DIR}/app/outputs/flutter-apk/app-illinois$ENV_NAME-release.apk"
VERSION=$(grep "version:" pubspec.yaml | sed -e 's/.* //' | sed -e 's/+.*//')
SHORT_VERSION_NAME=${VERSION%.*}
if [ -z "$TAG" ] || [ "$TAG" = "" ]
then
    BUILD_OUTPUT_NAME="$BRAND-$VERSION-$ENV"
else
    BUILD_OUTPUT_NAME="$BRAND-$VERSION-$TAG-$ENV"
fi
APK_OUT_PATH="${OUTPUT_DIR}/$BUILD_OUTPUT_NAME.apk"
IPA_OUT_PATH="${OUTPUT_DIR}/$BUILD_OUTPUT_NAME.ipa"
QR_BUILD_PATH="${OUTPUT_DIR}/$BUILD_OUTPUT_NAME.png"
PLIST_TEMPLATE_PATH="$CURRENT_DIR/scripts/templates/template.plist"
PLIST_BUILD_PATH="$OUTPUT_DIR/$BUILD_OUTPUT_NAME.plist"

echo $PLIST_BUILD_PATH
QR_PLIST_URL="itms-services://?action=download-manifest&url=https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BUILD_OUTPUT_NAME.plist"

printUtputUrls

echo "Cleaning the build environment."
rm -rf $OUTPUT_DIR
flutter clean

flutter doctor
flutter pub get

if [ -d "$OUTPUT_DIR" ]; then
  echo "Output dir: ${OUTPUT_DIR} "
else
  mkdir -p ${OUTPUT_DIR}
  echo "Output dir: ${OUTPUT_DIR} created"
fi

echo "Building version: ${VERSION}"

if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    echo "Building $FLAVOUR_ENV_NAME APK..."
  #flutter build apk --no-tree-shake-icons
#    if [ "$ENV" = "dev" ]; then
#      flutter build apk -t lib/mainDev.dart --flavor IllinoisDev --no-tree-shake-icons
#    fi
#
#    if [ "$ENV" = "prod" ]; then
#      flutter build apk -t lib/mainProd.dart --flavor IllinoisProd --no-tree-shake-icons
#    fi
#
#    if [ "$ENV" = "test" ]; then
#      flutter build apk -t lib/mainTest.dart --flavor IllinoisTst --no-tree-shake-icons
#    fi
    flutter build apk -t lib/main${FLAVOR_ENV}.dart --flavor Illinois${FLAVOUR_ENV_NAME} --no-tree-shake-icons
    echo "Building $FLAVOUR_ENV_NAME APK Finished!"
    
    echo "Looking for build apk at: ${APK_BUILD_PATH} "
    
    if [ -f "$APK_BUILD_PATH" ]; then
      cp $APK_BUILD_PATH $APK_OUT_PATH
      echo "Copy to $APK_OUT_PATH"
    fi

  aws s3 cp $APK_OUT_PATH s3://rokwire-ios-beta/Installs/
fi

if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then

  echo "Generating QR image..."
  qrencode -s 10 -d 300 -o $QR_BUILD_PATH "$QR_PLIST_URL"

  echo "Generating iOS plist..."
  cp $PLIST_TEMPLATE_PATH $PLIST_BUILD_PATH
  sed -i '' "s/$TEMPLATE_VERSION/$VERSION/g" $PLIST_BUILD_PATH
  sed -i '' "s/$TEMPLATE_BRAND/$BRAND/g" $PLIST_BUILD_PATH
  sed -i '' "s/$TEMPLATE_ENV/$ENV/g" $PLIST_BUILD_PATH
  sed -i '' "s/$TEMPLATE_BUNDLE_ID/$BUNDLE_ID/g" $PLIST_BUILD_PATH

  #flutter build ios --no-tree-shake-icons
  echo flutter build ios -t lib/main${FLAVOR_ENV}.dart --flavor Illinois${FLAVOUR_ENV_NAME} --no-tree-shake-icons
  flutter build ios -t lib/main${FLAVOR_ENV}.dart --flavor Illinois${FLAVOUR_ENV_NAME} --no-tree-shake-icons

  cd ios
  xcodebuild -workspace Runner.xcworkspace -scheme Runner  -archivePath ../build/_output/tmp/Runner.xcarchive archive
  xcodebuild -exportArchive -archivePath ../build/_output/tmp/Runner.xcarchive -exportPath ../build/_output/tmp/ -exportOptionsPlist ../build/_output/$BUILD_OUTPUT_NAME.plist
  cd ..
  cp ./build/_output/tmp/Illinois.ipa ./build/_output/$BUILD_OUTPUT_NAME.ipa
  #rm -rf ./build/_output/tmp/

  aws s3 cp $QR_BUILD_PATH s3://rokwire-ios-beta/Installs/
  aws s3 cp $PLIST_BUILD_PATH s3://rokwire-ios-beta/Installs/
  aws s3 cp ./build/_output/$BUILD_OUTPUT_NAME.ipa s3://rokwire-ios-beta/Installs/
fi

printUtputUrls

echo "Building finished!"
echo -ne '\007'
