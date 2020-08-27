#! /bin/bash

# Copy GoogleService-Info.plist in output bundle
if [ "${CONFIGURATION}" = "Debug" ]; then
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Debug.plist"
else
GOOGLE_SERVICE_SRC="${PROJECT_DIR}/Runner/GoogleService-Info-Release.plist"
fi
GOOGLE_SERVICE_DEST="${CODESIGNING_FOLDER_PATH}/GoogleService-Info.plist"
cp "${GOOGLE_SERVICE_SRC}" "${GOOGLE_SERVICE_DEST}"

# Upload app DSYM for Crashlytics
if [ "${CONFIGURATION}" = "Release" ]; then
  echo "Upload app DSYM for Crashlytics"
# "${PODS_ROOT}/Fabric/run"
# "${PODS_ROOT}/Fabric/upload-symbols" -gsp "${GOOGLE_SERVICE_SRC}" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
  "${PODS_ROOT}/Fabric/upload-symbols" -gsp "${GOOGLE_SERVICE_SRC}" -p ios "${DWARF_DSYM_FOLDER_PATH}"
fi
