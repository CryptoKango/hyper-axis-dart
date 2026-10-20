#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly dart_root="$(cd "${script_dir}/.." && pwd)"
readonly rust_root="${dart_root}/../hyper-axis"
readonly native_directory="${rust_root}/target/release/"

if [[ ! -f "${rust_root}/Cargo.toml" ]]; then
  echo "错误：未找到 Rust workspace：${rust_root}" >&2
  echo "请将 hyper-axis 与 hyper-axis-dart 放在同一父目录下。" >&2
  exit 1
fi

cargo build \
  --manifest-path "${rust_root}/Cargo.toml" \
  --package hyper-axis-ffi \
  --release

cd "${dart_root}"
FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR="${native_directory}" \
  dart run tool/smoke_native.dart
