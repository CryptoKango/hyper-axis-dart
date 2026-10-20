#!/usr/bin/env bash

set -euo pipefail

readonly expected_codegen_version="2.13.0"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repository_root="$(cd "${script_dir}/.." && pwd)"
readonly rust_root="$(${script_dir}/fetch_rust_core.sh)"
readonly rust_crate="${rust_root}/crates/hyper-axis-ffi"

if ! command -v flutter_rust_bridge_codegen >/dev/null 2>&1; then
  echo "错误：未找到 flutter_rust_bridge_codegen ${expected_codegen_version}。" >&2
  echo "安装命令：cargo install flutter_rust_bridge_codegen --version =${expected_codegen_version} --locked" >&2
  exit 1
fi

actual_codegen_version="$(flutter_rust_bridge_codegen --version | awk '{print $2}')"
if [[ "${actual_codegen_version}" != "${expected_codegen_version}" ]]; then
  echo "错误：生成器版本必须为 ${expected_codegen_version}，当前为 ${actual_codegen_version}。" >&2
  exit 1
fi

if [[ ! -f "${rust_crate}/Cargo.toml" ]]; then
  echo "错误：未找到 Rust FFI crate：${rust_crate}" >&2
  exit 1
fi

cd "${repository_root}"
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
dart format lib/src/generated
