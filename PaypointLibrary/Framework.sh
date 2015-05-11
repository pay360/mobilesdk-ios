set -e

mkdir -p "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Headers"
cp -a "${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Headers"