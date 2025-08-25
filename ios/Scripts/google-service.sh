#! /bin/bash

# Print context
echo "TARGET: ${TARGET_NAME}"
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "CONFIGURATION: ${CONFIGURATION}"

# Copy GoogleService-Info.plist to output bundle
if [ "${ENVIRONMENT}" = "Dev" ]; then
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Dev.plist"
elif [ "${ENVIRONMENT}" = "Prod" ]; then
GOOGLE_SERVICE_SRC="Resources/${TARGET_NAME}/GoogleService-Info-Prod.plist"
elif [ "${ENVIRONMENT}" = "Test" ]; then
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
