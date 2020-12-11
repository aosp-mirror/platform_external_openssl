#!/bin/bash -ex
#
# Copyright 2020 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Regenerate host build configuration

cd `dirname ${BASH_SOURCE[0]}`

for OS in linux darwin; do
    GENDIR=gen-${OS}

    rm -rf ${GENDIR} tmp

    mkdir tmp
    cd tmp

    if [ "$OS" == "linux" ]; then
        CONFIG="linux-x86_64-clang"
    elif [ "$OS" == "darwin" ]; then
        CONFIG="darwin64-x86_64-cc"
    else
        echo "Unknown OS"
        exit 1
    fi

    ../../Configure no-ct no-engine ${CONFIG}
    ../gen_bp.pl ${OS} android/${GENDIR} >../../Android-${OS}.gen.bp

    # Extract the list of generated sources and headers from the perl configdata.pm
    # Ignore buildinf.h as we have a static build info file.
    GENERATED_FILES=(
        $(../list_generated_files.pl | sort -u | grep -v buildinf.h)
    )

    make "${GENERATED_FILES[@]}"
    for f in "${GENERATED_FILES[@]}"; do
        mkdir -p $(dirname ../${GENDIR}/$f)
        cp $f ../${GENDIR}/$f
    done

    cd ..
    rm -rf tmp

    bpfmt -w ../Android-${OS}.gen.bp
done

