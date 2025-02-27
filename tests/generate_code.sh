#!/bin/bash
#
# Copyright 2021 Google Inc. All rights reserved.
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
set -e

commandline="'$*'"

if [[ $commandline == *"--cpp-std c++0x"* ]]; then
  TEST_CPP_FLAGS="--cpp-std c++0x"
else
  # --cpp-std is defined by flatc default settings.
  TEST_CPP_FLAGS=
fi

TEST_CPP_FLAGS="--gen-compare --cpp-ptr-type flatbuffers::unique_ptr $TEST_CPP_FLAGS"
TEST_CS_FLAGS="--cs-gen-json-serializer"
TEST_TS_FLAGS="--gen-name-strings"
TEST_BASE_FLAGS="--reflect-names --gen-mutable --gen-object-api"
TEST_RUST_FLAGS="$TEST_BASE_FLAGS --gen-all --gen-name-strings"
TEST_NOINCL_FLAGS="$TEST_BASE_FLAGS --no-includes"


../flatc --binary --cpp --java --kotlin  --csharp --dart --go --lobster --lua --ts --php --grpc \
$TEST_NOINCL_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS -I include_test monster_test.fbs monsterdata_test.json
../flatc --rust $TEST_RUST_FLAGS -o monster_test -I include_test monster_test.fbs monsterdata_test.json

../flatc --python $TEST_BASE_FLAGS -I include_test monster_test.fbs monsterdata_test.json

../flatc --cpp --java --kotlin --csharp --dart --go --binary --lobster --lua --ts --php --python \
$TEST_NOINCL_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS $TEST_TS_FLAGS -o namespace_test namespace_test/namespace_test1.fbs namespace_test/namespace_test2.fbs

# For Rust we currently generate two independent schemas, with namespace_test2
# duplicating the types in namespace_test1
../flatc --rust --gen-all $TEST_RUST_FLAGS -o namespace_test namespace_test/namespace_test1.fbs namespace_test/namespace_test2.fbs

../flatc --cpp --java --kotlin --csharp --ts --php $TEST_BASE_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS $TEST_TS_FLAGS -o union_vector ./union_vector/union_vector.fbs
../flatc --ts --gen-name-strings --gen-mutable $TEST_BASE_FLAGS $TEST_TS_FLAGS -I include_test monster_test.fbs
../flatc $TEST_BASE_FLAGS $TEST_TS_FLAGS -b -I include_test monster_test.fbs unicode_test.json
../flatc --ts --gen-name-strings $TEST_BASE_FLAGS $TEST_TS_FLAGS -o union_vector union_vector/union_vector.fbs
../flatc --rust $TEST_RUST_FLAGS -o include_test1 -I include_test include_test/include_test1.fbs
../flatc --rust $TEST_RUST_FLAGS -o include_test2 -I include_test include_test/sub/include_test2.fbs
../flatc -b --schema --bfbs-comments --bfbs-filenames . --bfbs-builtins -I include_test monster_test.fbs
../flatc --cpp --bfbs-comments --bfbs-builtins --bfbs-gen-embed $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS -I include_test monster_test.fbs
../flatc -b --schema --bfbs-comments --bfbs-builtins -I include_test arrays_test.fbs
../flatc --jsonschema --schema -I include_test monster_test.fbs
../flatc --cpp --java --kotlin --csharp --python $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS monster_extra.fbs monsterdata_extra.json
../flatc --cpp --java --csharp --jsonschema $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS --scoped-enums arrays_test.fbs
../flatc --rust $TEST_RUST_FLAGS -o arrays_test arrays_test.fbs
../flatc --python $TEST_BASE_FLAGS arrays_test.fbs
../flatc --dart --gen-object-api monster_extra.fbs

# Generate optional scalar code for tests.
../flatc --java --kotlin --lobster --ts optional_scalars.fbs
../flatc --csharp --gen-object-api optional_scalars.fbs
../flatc --rust $TEST_RUST_FLAGS -o optional_scalars optional_scalars.fbs
../flatc $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS --cpp optional_scalars.fbs

# Generate string/vector default code for tests
../flatc --rust $TEST_RUST_FLAGS -o more_defaults more_defaults.fbs

# Generate the schema evolution tests
../flatc --cpp --scoped-enums $TEST_CPP_FLAGS -o evolution_test ./evolution_test/evolution_v*.fbs

# Generate the keywords tests
../flatc --csharp $TEST_BASE_FLAGS $TEST_CS_FLAGS ./keyword_test.fbs
../flatc --rust $TEST_RUST_FLAGS -o keyword_test ./keyword_test.fbs

working_dir=`pwd`
cd FlatBuffers.Test.Swift/Tests/FlatBuffers.Test.SwiftTests
$working_dir/../flatc --bfbs-filenames $working_dir --swift --grpc $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS -I ${working_dir}/include_test ${working_dir}/monster_test.fbs
$working_dir/../flatc --bfbs-filenames $working_dir --swift $TEST_BASE_FLAGS $TEST_CPP_FLAGS $TEST_CS_FLAGS ${working_dir}/union_vector/union_vector.fbs
$working_dir/../flatc --bfbs-filenames $working_dir --swift ${working_dir}/optional_scalars.fbs
$working_dir/../flatc --bfbs-filenames $working_dir --swift --gen-object-api ${working_dir}/more_defaults.fbs
cd $working_dir

# Tests if the --filename-suffix and --filename-ext works and produces the same
# outputs.
../flatc --cpp --filename-suffix _suffix --filename-ext hpp $TEST_NOINCL_FLAGS $TEST_CPP_FLAGS -I include_test monster_test.fbs
if [ -f "monster_test_suffix.hpp" ]; then
  if ! cmp -s "monster_test_suffix.hpp" "monster_test_generated.h"; then
    echo "[Error] Filename suffix option did not produce identical results"
  fi
  rm "monster_test_suffix.hpp"
else
  echo "[Error] Filename suffix option did not produce a file"
fi

# Flag c++17 requires Clang6, GCC7, MSVC2017 (_MSC_VER >= 1914)  or higher.
TEST_CPP17_FLAGS="--cpp --cpp-std c++17 --cpp-static-reflection --gen-object-api -o ./cpp17/generated_cpp17 $TEST_NOINCL_FLAGS"
../flatc $TEST_CPP17_FLAGS -I include_test monster_test.fbs
../flatc $TEST_CPP17_FLAGS optional_scalars.fbs
../flatc $TEST_CPP17_FLAGS union_vector/union_vector.fbs

cd ../samples
../flatc --cpp --lobster $TEST_BASE_FLAGS $TEST_CPP_FLAGS monster.fbs
../flatc --rust $TEST_RUST_FLAGS -o rust_generated monster.fbs 
../flatc -b --schema --bfbs-comments --bfbs-builtins monster.fbs
cd ../reflection
./generate_code.sh --cpp-std c++0x
