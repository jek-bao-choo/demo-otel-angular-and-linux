#!/bin/bash
# Build the Angular app and bundle it into adt-service-a's static resources, then rebuild the jars.
# Usage: ./build-into-service-a.sh
set -euo pipefail

cd "$(dirname "$0")"
npx ng build --configuration production

STATIC=../adt-service-a/src/main/resources/static
rm -rf "${STATIC}"
mkdir -p "${STATIC}"
cp -R dist/web/browser/. "${STATIC}/"
echo "Copied Angular build into ${STATIC}"

cd ..
mvn -q clean package -DskipTests
ls -la adt-service-a/target/adt-service-a.jar
