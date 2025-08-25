#! /bin/bash

# Upload app DSYM for FirebaseCrashlytics
if [ "${CONFIGURATION}" == "Release" ]; then
  echo "Uploading app DSYMs for FirebaseCrashlytics"
  "${PODS_ROOT}/FirebaseCrashlytics/run"
  #"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" -gsp "${GOOGLE_SERVICE_SRC}" -p ios "${DWARF_DSYM_FOLDER_PATH}"
fi
