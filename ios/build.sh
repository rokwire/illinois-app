#! /bin/bash

# Print context
echo "TARGET: ${TARGET_NAME}"
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "CONFIGURATION: ${CONFIGURATION}"

# Copy GoogleService-Info.plist to output bundle
if [ "${ENVIRONMENT}" = "Dev" ]; then
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Dev.plist"
elif [ "${ENVIRONMENT}" = "Prod" ] || [ "${ENVIRONMENT}" = "Test" ]; then
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Prod.plist"
elif [ "${CONFIGURATION:0:5}" == "Debug" ]; then
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Dev.plist"
else
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Prod.plist"
fi
echo "Using ${GOOGLE_SERVICE_SRC}"

GOOGLE_SERVICE_ORG="${PROJECT_DIR}/${GOOGLE_SERVICE_SRC}"
GOOGLE_SERVICE_DEST="${CODESIGNING_FOLDER_PATH}/GoogleService-Info.plist"
cp "${GOOGLE_SERVICE_SRC}" "${GOOGLE_SERVICE_DEST}"

# Upload app DSYM for FirebaseCrashlytics
if [[ "${CONFIGURATION}" == *"Release"* ]]; then
  echo "Uploading app DSYM for FirebaseCrashlytics"
  "${PODS_ROOT}/FirebaseCrashlytics/run"
  #"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${GOOGLE_SERVICE_SRC}" -p ios "${DWARF_DSYM_FOLDER_PATH}"
fi
