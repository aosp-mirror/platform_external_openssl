#!/bin/sh
#
# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Some tests depend on the return code of the ssltest command but the return
# code of the executed command is not transmitted back to the host over adb.
# This script generates a script to run on the target with adb, the generated
# script runs the command and echos the result $?. The host side captures the
# output from the adb command and exits with the same return code as ssltest.
#

ret=1
cmd=$@
echo "$cmd" > tmp.sh
echo "echo Result: \$?" >> tmp.sh
adb push tmp.sh /data 2> /dev/null
rm tmp.sh
adb shell chmod 755 /data/tmp.sh
out=`adb shell /data/tmp.sh | tr -d \n | tr -d \r`
if test "${out#*Result: 0}" != "$out" ; then
    ret=0
    adb shell rm /data/tmp.sh
fi
exit $ret

