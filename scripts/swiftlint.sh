#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=0.65.1
CHECKSUM=c3a1d77647ca18c1b7e9be7dbc6cd4490d26422f28814b76370244ff61970869
BINARY_CHECKSUM=52112ece2dfa99c2442a1367f9a365d43784714cf224c3675bf8bc2f18ebd7c8
TOOLS_DIR="$REPO_ROOT/.build/tools/swiftlint"
SWIFTLINT="$TOOLS_DIR/$VERSION/swiftlint"

valid_binary() {
    [[ -x "$1" ]] || return 1
    local checksum
    checksum=$(shasum -a 256 "$1")
    [[ "${checksum%% *}" == "$BINARY_CHECKSUM" ]]
}

if ! valid_binary "$SWIFTLINT"; then
    mkdir -p "$TOOLS_DIR/$VERSION"
    temp_dir=$(mktemp -d "$TOOLS_DIR/.download.XXXXXX")
    trap 'rm -rf "$temp_dir"' EXIT

    archive="$temp_dir/SwiftLintBinary.artifactbundle.zip"
    echo "SwiftLint $VERSION 다운로드 중" >&2
    curl --fail --location --silent --show-error --retry 3 --connect-timeout 10 --max-time 300 \
        --output "$archive" \
        "https://github.com/realm/SwiftLint/releases/download/$VERSION/SwiftLintBinary.artifactbundle.zip"
    actual_checksum=$(shasum -a 256 "$archive")
    [[ "${actual_checksum%% *}" == "$CHECKSUM" ]] || {
        echo 'SwiftLint 다운로드 파일의 SHA-256이 일치하지 않습니다.' >&2
        exit 1
    }

    unzip -q "$archive" -d "$temp_dir"
    extracted="$temp_dir/SwiftLintBinary.artifactbundle/macos/swiftlint"
    [[ -x "$extracted" && "$("$extracted" version)" == "$VERSION" ]] && valid_binary "$extracted" || {
        echo 'SwiftLint 실행 파일, 버전 또는 SHA-256이 올바르지 않습니다.' >&2
        exit 1
    }
    mv -f "$extracted" "$SWIFTLINT"
    rm -rf "$temp_dir"
    trap - EXIT
fi

exec "$SWIFTLINT" "$@"
