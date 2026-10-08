# Setup

개발 환경을 준비하고 빌드·검증하는 방법.

## Required Files

| 파일 | 필요 여부 | 할 일 |
|---|---|---|
| `FiveGuyes/Config.xcconfig` | **필수.** 없으면 빌드 실패 | 견본을 복사한다. 도서 검색을 확인할 때만 `API_KEY`에 알라딘 API 키를 넣는다 |
| `FiveGuyes/FiveGuyes/GoogleService-Info.plist` | Debug·테스트는 없어도 됨. Release는 필수 | Firebase 동작을 확인할 때만 넣는다 |

```bash
cp FiveGuyes/Config.xcconfig.example FiveGuyes/Config.xcconfig
```

두 파일 모두 `.gitignore` 대상이다. 실제 인증 정보는 커밋하지 않는다.

**`GoogleService-Info.plist`**

- Debug 빌드에서는 없으면 Firebase 초기화를 건너뛰고 정상 실행된다. Release는 항상 초기화하므로 반드시 필요하다.
- 테스트는 plist 유무와 상관없이 Firebase와 ATT(앱 추적 투명성) 요청 없이 실행된다. CI도 이 파일을 만들지 않는다.
- 넣을 때는 Firebase 콘솔(프로젝트 설정 > iOS 앱)에서 받은 파일을 `FiveGuyes/FiveGuyes/` 안에 둔다. 앱 타깃은 이 폴더를 파일시스템 동기화 그룹으로 참조하므로 **그 폴더 안의 파일만 앱 번들에 포함된다.**
- 견본 파일을 복사해 넣으면 `FirebaseApp.configure()`가 시작 중 크래시한다.
- Debug 빌드의 GA 수집은 기본으로 꺼져 있다. 켜고 끄는 방법은 `services/analytics/launch-and-ga.md`를 본다.

## Build and Test

```bash
# 패키지 해석, lint, 단일 시뮬레이터 테스트
scripts/verify.sh

# 특정 시뮬레이터로 검사
SIMULATOR_DESTINATION='platform=iOS Simulator,name=iPhone 17' scripts/verify.sh

# lint만 검사 (SwiftLint가 없으면 자동 설치)
cd FiveGuyes && ../scripts/swiftlint.sh lint --no-cache
```

- 앱·테스트 타깃은 폴더를 파일시스템 동기화 그룹으로 참조한다. 새 Swift 파일은 Xcode 프로젝트 파일을 고치지 않아도 타깃에 들어간다.
- `xcodebuild`로 테스트를 직접 돌릴 때는 병렬 실행을 끄고 단일 시뮬레이터를 쓴다. `verify.sh`는 이미 그렇게 실행한다.

**SwiftLint**

- `verify.sh`와 위 lint 명령은 SwiftLint 0.65.1을 첫 실행 시 내려받아 SHA-256을 확인하고 `.build/tools/`에 보관한다. 이후에는 보관된 바이너리를 사용한다.
- lint는 `verify.sh`와 이를 호출하는 CI·pre-push에서 실행된다. Xcode 빌드만 실행할 때는 lint가 실행되지 않는다.

## Pre-push Hook

| 동작 | 명령 (클론마다 한 번) |
|---|---|
| 켜기 | `git config core.hooksPath .githooks` |
| 끄기 | `git config --unset core.hooksPath` |

hook은 push할 때 `scripts/verify.sh`를 실행한다. 커밋 안 된 변경이 있거나 HEAD가 아닌 커밋을 push하면 거부한다. 건너뛰려면 `git push --no-verify`를 쓴다.

## Local Files

`.local/`은 개인 작업 문서 보관용이며 git이 추적하지 않는다.
