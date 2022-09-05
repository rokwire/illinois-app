#! /bin/bash

# Print context
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "CONFIGURATION: ${CONFIGURATION}"

# Copy GoogleService-Info.plist in output bundle
if [ "${ENVIRONMENT}" = "Dev" ]; then
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Dev.plist"
echo "Using GoogleService-Info-Dev.plist"
elif [ "${ENVIRONMENT}" = "Prod" ] || [ "${ENVIRONMENT}" = "Test" ]; then
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Prod.plist"
echo "Using GoogleService-Info-Prod.plist"
elif [ "${CONFIGURATION}" == "Debug" ]; then
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Dev.plist"
echo "Using GoogleService-Info-Dev.plist"
else
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Prod.plist"
echo "Using GoogleService-Info-Prod.plist"
fi
GOOGLE_SERVICE_DEST="${CODESIGNING_FOLDER_PATH}/GoogleService-Info.plist"
cp "${GOOGLE_SERVICE_SRC}" "${GOOGLE_SERVICE_DEST}"

# Upload app DSYM for FirebaseCrashlytics
if [[ "${CONFIGURATION}" == *"Release"* ]]; then
  echo "Uploading app DSYM for FirebaseCrashlytics"
  "${PODS_ROOT}/FirebaseCrashlytics/run"
  "${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${GOOGLE_SERVICE_SRC}" -p ios "${DWARF_DSYM_FOLDER_PATH}"
fi
