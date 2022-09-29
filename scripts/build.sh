#!/bin/bash
help() {
    echo ""
    echo "SETUP"
    echo "Install qrencode: brew install qrencode"
    echo ""
    echo "Usage: ./scripts/build.sh {BRAND} {ENV} {PLATFORM}"
    echo "{BRAND} brand name | Default: Illinois if the param is missing or empty"
    echo "{ENV} Environment name | Default: dev"
    echo "{PLATFORM} Target platform. Values: all|ios|android Default: all"
    echo ""
    echo ""
}

help

CURRENT_DIR=$(PWD)
FILE_PUBSPEC=$(cat pubspec.yaml)

BRAND="$1"
ENV="$2"
PLATFORM="$3"


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

cd ios
BUNDLE_ID=$(xcodebuild -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk -F ' = ' '{print $2}')
cd ..

TEMPLATE_BRAND="{{BRAND}}"
TEMPLATE_VERSION="{{VERSION}}"
TEMPLATE_ENV="{{ENV}}"
TEMPLATE_BUNDLE_ID="{{BUNDLE_ID}}"
BUILD_DIR="${CURRENT_DIR}/build"
OUTPUT_DIR="${BUILD_DIR}/_output"
APK_BUILD_PATH="${BUILD_DIR}/app/outputs/apk/release/app-release.apk"
VERSION=$(grep "version:" pubspec.yaml | sed -e 's/.* //' | sed -e 's/+.*//')
APK_OUT_PATH="${OUTPUT_DIR}/$BRAND-$VERSION-$ENV.apk"
IPA_OUT_PATH="${OUTPUT_DIR}/$BRAND-$VERSION-$ENV.ipa"
QR_BUILD_PATH="${OUTPUT_DIR}/$BRAND-$VERSION-$ENV.png"
PLIST_TEMPLATE_PATH="$CURRENT_DIR/scripts/templates/template.plist"
PLIST_BUILD_PATH="$OUTPUT_DIR/$BRAND-$VERSION-$ENV.plist"

echo $PLIST_BUILD_PATH
QR_PLIST_URL="itms-services://?action=download-manifest&url=https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BRAND-$VERSION-$ENV.plist"

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
  echo "Building APK..."
  flutter build apk --no-tree-shake-icons

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

  flutter build ios --no-tree-shake-icons

  cd ios
  xcodebuild -workspace Runner.xcworkspace -scheme Runner  -archivePath ../build/_output/tmp/Runner.xcarchive archive
  xcodebuild -exportArchive -archivePath ../build/_output/tmp/Runner.xcarchive -exportPath ../build/_output/tmp/ -exportOptionsPlist ../build/_output/$BRAND-$VERSION-$ENV.plist
  cd ..
  cp ./build/_output/tmp/Illinois.ipa ./build/_output/$BRAND-$VERSION-$ENV.ipa
  #rm -rf ./build/_output/tmp/

  aws s3 cp $QR_BUILD_PATH s3://rokwire-ios-beta/Installs/
  aws s3 cp $PLIST_BUILD_PATH s3://rokwire-ios-beta/Installs/
  aws s3 cp ./build/_output/$BRAND-$VERSION-$ENV.ipa s3://rokwire-ios-beta/Installs/
fi



echo "########################################################################"
echo "Generated URLs for the report"
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
  echo "Android:"
  echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BRAND-$VERSION-$ENV.apk"
  echo ""
fi
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
echo "iOS:"
echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BRAND-$VERSION-$ENV.ipa"
echo "itms-services://?action=download-manifest&url=https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BRAND-$VERSION-$ENV.plist"
echo "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Installs/$BRAND-$VERSION-$ENV.png"
echo ""
fi
echo "TODO2: Upload to S3 through command line!"
echo -ne '\007'
