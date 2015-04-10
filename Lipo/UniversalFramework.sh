#!/bin/sh

UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal
RN_TARGET_NAME=${PROJECT_NAME}SDK
CONVENIENCE_FOLDER=${PROJECT_DIR}/Lipo

# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
mkdir -p "${CONVENIENCE_FOLDER}"

# Step 1. Build Device and Simulator versions

xcodebuild -target "${RN_TARGET_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

xcodebuild -target "${RN_TARGET_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${RN_TARGET_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 3. Copy Swift modules (from iphonesimulator build) to the copied framework directory
# cp -R "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${RN_TARGET_NAME}.framework/Modules/Framework.swiftmodule/." "${UNIVERSAL_OUTPUTFOLDER}/${RN_TARGET_NAME}.framework/Modules/Framework.swiftmodule"

# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${RN_TARGET_NAME}.framework/${RN_TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${RN_TARGET_NAME}.framework/${RN_TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${RN_TARGET_NAME}.framework/${RN_TARGET_NAME}"

# Step 5. Convenience step to copy the framework to the project's directory
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${RN_TARGET_NAME}.framework" "${CONVENIENCE_FOLDER}"

# Step 6. Convenience step to open the project's directory in Finder
#open "${PROJECT_DIR}"