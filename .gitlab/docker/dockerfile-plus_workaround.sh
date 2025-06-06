#!/bin/sh
# This script is workaround for bug https://github.com/edrevo/dockerfile-plus/issues/13
# You DO NOT need to run this script if you build only one image at a time
set -e

FILE_TO_OVERRIDE=$1
TMP_FILE="$1-copy"

echo "Overriding ${FILE_TO_OVERRIDE} to replace \"INCLUDE+\" strings with specified files content"

cp $FILE_TO_OVERRIDE $TMP_FILE

echo -n "" > ${FILE_TO_OVERRIDE}
while IFS= read -r line
do
  if [ $(expr match "${line}" ".*edrevo/dockerfile-plus.*") != 0 ]; then
   continue
  fi

  if [ $(expr match "${line}" "INCLUDE+") != 0 ]; then
   cat ${line##INCLUDE+} >> ${FILE_TO_OVERRIDE}
   continue
  fi
  echo "${line}" >> ${FILE_TO_OVERRIDE}
done < "${TMP_FILE}"

rm $TMP_FILE
