#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repository_root="$(cd "${script_dir}/.." && pwd)"

# shellcheck source=core-version.sh
source "${script_dir}/core-version.sh"

readonly checkout_dir="${repository_root}/.dart_tool/hyper-axis-core"

if [[ ! -d "${checkout_dir}/.git" ]]; then
  mkdir -p "$(dirname "${checkout_dir}")"
  git clone \
    --filter=blob:none \
    --no-checkout \
    "${HYPER_AXIS_CORE_REPOSITORY}" \
    "${checkout_dir}"
fi

actual_origin="$(git -C "${checkout_dir}" remote get-url origin)"
if [[ "${actual_origin}" != "${HYPER_AXIS_CORE_REPOSITORY}" ]]; then
  echo "错误：Rust Core 缓存的 origin 不匹配：${actual_origin}" >&2
  exit 1
fi

git -C "${checkout_dir}" fetch \
  --depth 1 \
  origin \
  "refs/tags/${HYPER_AXIS_CORE_TAG}:refs/tags/${HYPER_AXIS_CORE_TAG}"

resolved_commit="$(git -C "${checkout_dir}" rev-parse "${HYPER_AXIS_CORE_TAG}^{commit}")"
if [[ "${resolved_commit}" != "${HYPER_AXIS_CORE_COMMIT}" ]]; then
  echo "错误：${HYPER_AXIS_CORE_TAG} 指向 ${resolved_commit}，预期 ${HYPER_AXIS_CORE_COMMIT}。" >&2
  exit 1
fi

git -C "${checkout_dir}" checkout --detach --force "${HYPER_AXIS_CORE_COMMIT}"
printf '%s\n' "${checkout_dir}"

