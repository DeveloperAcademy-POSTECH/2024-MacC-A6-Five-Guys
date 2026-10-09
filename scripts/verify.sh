#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
SPM_DIR="${SPM_DIR:-$REPO_ROOT/.build/SourcePackages}"
[[ "$SPM_DIR" = /* ]] || SPM_DIR="$REPO_ROOT/$SPM_DIR"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-}"
[[ -z "$RESULT_BUNDLE_PATH" || "$RESULT_BUNDLE_PATH" = /* ]] || RESULT_BUNDLE_PATH="$REPO_ROOT/$RESULT_BUNDLE_PATH"
PACKAGE_RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:+${RESULT_BUNDLE_PATH%.xcresult}-FGNetwork.xcresult}"
stage="준비"
started_at=$(date +%s)
results=()

finish() {
    local status=$? now elapsed
    if [[ $status -ne 0 ]]; then
        now=$(date +%s)
        elapsed=$((now - started_at))
        results+=("$stage: ${elapsed}s")
    fi
    printf '\n검증 결과 (종료 코드 %s)\n' "$status"
    printf '%s\n' "${results[@]}"
    [[ $status -eq 0 ]] || printf '실패 단계: %s\n' "$stage"
}
trap finish EXIT

run_stage() {
    stage=$1
    started_at=$(date +%s)
    printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$stage"
    shift
    "$@"
    results+=("$stage: $(($(date +%s) - started_at))s")
}

check_result_bundle() {
    local result_bundle
    for result_bundle in "$RESULT_BUNDLE_PATH" "$PACKAGE_RESULT_BUNDLE_PATH"; do
        [[ -z "$result_bundle" || ! -e "$result_bundle" ]] || { echo "결과 번들이 이미 있습니다: $result_bundle"; exit 1; }
    done
}

select_destination() {
    if [[ -n "${SIMULATOR_DESTINATION:-}" ]]; then
        destination=$SIMULATOR_DESTINATION
    else
        destination="platform=iOS Simulator,id=$(xcrun simctl list -j devices available | python3 -c 'import json,re,sys; best=None
for runtime, devices in json.load(sys.stdin)["devices"].items():
 m=re.search(r"iOS-(\d+)-(\d+)",runtime)
 if m:
  for d in devices:
   if d.get("isAvailable") and d["name"].startswith("iPhone"):
    candidate=((int(m.group(1)),int(m.group(2))),d["udid"]); best=max(best,candidate) if best else candidate
if not best: raise SystemExit("No available iPhone simulator found")
print(best[1])')"
    fi
}

test_package() {
    local args=(
        test
        -scheme FGNetwork
        -destination "$destination"
        -clonedSourcePackagesDirPath "$SPM_DIR"
        -parallel-testing-enabled NO
        -maximum-concurrent-test-simulator-destinations 1
    )
    [[ -z "$PACKAGE_RESULT_BUNDLE_PATH" ]] || args+=(-resultBundlePath "$PACKAGE_RESULT_BUNDLE_PATH")
    [[ "${CI:-}" != true ]] || args+=(CODE_SIGNING_ALLOWED=NO)
    (
        cd FiveGuyes/Packages/FGNetwork
        xcodebuild "${args[@]}"
    )
}

[[ -f FiveGuyes/Config.xcconfig ]] || { echo 'FiveGuyes/Config.xcconfig가 없습니다. Config.xcconfig.example을 복사하세요.'; exit 1; }
run_stage '결과 번들 확인' check_result_bundle
run_stage '패키지 해석' xcodebuild -resolvePackageDependencies -project FiveGuyes/FiveGuyes.xcodeproj -clonedSourcePackagesDirPath "$SPM_DIR"
run_stage 'lint' bash -c 'cd FiveGuyes && ../scripts/swiftlint.sh lint --no-cache'
run_stage '시뮬레이터 선택' select_destination
run_stage '패키지 테스트' test_package
args=(test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "$destination" -clonedSourcePackagesDirPath "$SPM_DIR" -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1)
[[ -z "$RESULT_BUNDLE_PATH" ]] || args+=(-resultBundlePath "$RESULT_BUNDLE_PATH")
[[ "${CI:-}" != true ]] || args+=(CODE_SIGNING_ALLOWED=NO)
run_stage '테스트' env SWIFTLINT_ALREADY_RUN=1 xcodebuild "${args[@]}"
