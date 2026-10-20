#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly dart_root="$(cd "${script_dir}/.." && pwd)"
readonly rust_root="$(${script_dir}/fetch_rust_core.sh)"
readonly native_directory="${rust_root}/target/release/"

if [[ ! -f "${rust_root}/Cargo.toml" ]]; then
  echo "错误：未找到 Rust workspace：${rust_root}" >&2
  exit 1
fi

cargo build \
  --manifest-path "${rust_root}/Cargo.toml" \
  --package hyper-axis-ffi \
  --release

cd "${dart_root}"
FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR="${native_directory}" \
  dart run tool/smoke_native.dart
