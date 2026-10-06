#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
SPM_DIR="${SPM_DIR:-$REPO_ROOT/.build/SourcePackages}"
[[ "$SPM_DIR" = /* ]] || SPM_DIR="$REPO_ROOT/$SPM_DIR"
SWIFTLINT="$SPM_DIR/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint"
stage="준비"
started_at=$(date +%s)
results=()

finish() {
    local status=$? now elapsed
    rm -f "${test_log:-}"
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
    [[ -z "${RESULT_BUNDLE_PATH:-}" || ! -e "$RESULT_BUNDLE_PATH" ]] || { echo "결과 번들이 이미 있습니다: $RESULT_BUNDLE_PATH"; exit 1; }
}

check_swiftlint() {
    [[ -x "$SWIFTLINT" ]] || { echo "SwiftLint 실행 파일이 없습니다: $SWIFTLINT"; exit 1; }
    expected_version=$(python3 -c 'import json; p=json.load(open("FiveGuyes/FiveGuyes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")); print(next(x["state"]["version"] for x in p["pins"] if x["identity"] == "swiftlintplugins"))')
    actual_version=$($SWIFTLINT version)
    [[ "$actual_version" == "$expected_version" ]] || { echo "SwiftLint $expected_version이 필요합니다: $actual_version"; exit 1; }
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

[[ -f FiveGuyes/Config.xcconfig ]] || { echo 'FiveGuyes/Config.xcconfig가 없습니다. Config.xcconfig.example을 복사하세요.'; exit 1; }
run_stage '결과 번들 확인' check_result_bundle
run_stage '패키지 해석' xcodebuild -resolvePackageDependencies -project FiveGuyes/FiveGuyes.xcodeproj -clonedSourcePackagesDirPath "$SPM_DIR"
run_stage 'SwiftLint 확인' check_swiftlint
run_stage 'lint' bash -c 'cd FiveGuyes && "$1" lint --no-cache' _ "$SWIFTLINT"
run_stage '시뮬레이터 선택' select_destination
args=(test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination "$destination" -clonedSourcePackagesDirPath "$SPM_DIR" -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1)
[[ -z "${RESULT_BUNDLE_PATH:-}" ]] || args+=(-resultBundlePath "$RESULT_BUNDLE_PATH")
[[ "${CI:-}" != true ]] || args+=(-skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO)
run_tests() {
    test_log=$(mktemp)
    if ! xcodebuild "${args[@]}" 2>&1 | tee "$test_log"; then
        if grep -q 'was disabled because it has changed' "$test_log"; then
            echo 'SwiftLint 플러그인 버전이 바뀌어 Xcode 승인이 필요합니다. Xcode에서 FiveGuyes 프로젝트를 빌드하고 플러그인 경고에서 Trust & Enable을 누른 뒤 다시 실행하세요.'
        fi
        return 1
    fi
}
run_stage '테스트' run_tests
