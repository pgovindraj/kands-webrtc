#!/bin/bash

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

SCRIPT_ABS_PATH=$(get_abs_path)

FAIL_MARK=last_execution_fails

function fail {
  cd $SCRIPT_ABS_PATH
  echo "FAIL" && touch $FAIL_MARK && exit -1
}

function end {
  pushd $SCRIPT_ABS_PATH > /dev/null

  cp trunk/out/Debug/libjingle_peerconnection.jar . && \
  cp trunk/out/Debug/libjingle_peerconnection_so.so . && \
  rm -f $FAIL_MARK || \
  fail

  popd > /dev/null # $SCRIPT_ABS_PATH

  exit 0;
}

pushd $SCRIPT_ABS_PATH > /dev/null

# Check for updates
if [[ ! -f $FAIL_MARK && -d "trunk" ]]; then
  pushd "trunk" > /dev/null

  DIFF=$(svn diff --summarize -rCOMMITTED:HEAD)
  if [ -z "$DIFF" ]; then
    echo "There is not any change";
    end
  fi

  popd > /dev/null # "trunk"
fi

# Update
gclient sync --nohooks --force && \
cp util/common.gypi trunk/talk/build/common.gypi || \
fail

pushd "trunk" > /dev/null
source ./build/android/envsetup.sh && \
gclient runhooks && \
ninja -C out/Debug libjingle_peerconnection_jar || \
fail
popd > /dev/null # "trunk"

popd > /dev/null # $SCRIPT_ABS_PATH

end
