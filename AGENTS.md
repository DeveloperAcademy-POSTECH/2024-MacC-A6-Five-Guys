# Repository Guidelines

## 프로젝트 구조 및 모듈 구성

이 저장소는 `FiveGuyes/` 아래에 있는 iOS SwiftUI 프로젝트입니다. 앱은 `FiveGuyes/FiveGuyes.xcodeproj`와 공유 스킴 `FiveGuyes`로 빌드합니다. 주요 소스 코드는 `FiveGuyes/FiveGuyes/Sources`에 있으며 역할별로 나뉩니다.

- `App`: 앱 진입점, 의존성 조립, 내비게이션 루트
- `Presentation`: SwiftUI View, Component, ViewModel, Preview, Typography
- `Domain`: Entity, Policy, Calculator, Service, Repository 인터페이스, UseCase
- `Data`: SwiftData, UserDefaults, Repository 구현체
- `Platform`: 도서 검색, 분석, 알림, 시스템 설정 연동
- `Shared`: 공통 확장과 헬퍼

테스트는 `FiveGuyes/FiveGuyesTests`에 있으며 소스 계층을 따라 구성됩니다. 앱 리소스와 폰트는 `FiveGuyes/FiveGuyes/Resources`, 프리뷰 전용 리소스는 `Preview Content`에 둡니다.

계층별 상세 규약은 해당 디렉터리의 `AGENTS.md`를 함께 참고하세요. 레포 안에 `CLAUDE.md`·`.claude/CLAUDE.md`·`CLAUDE.local.md`를 만들지 마세요. 만들면 그 폴더와 하위에서 Claude Code가 `AGENTS.md` 대신 해당 파일을 읽습니다.

## 첫 빌드 전 필수 설정

`Config.xcconfig`는 Debug/Release 양쪽의 base configuration이며 `.gitignore` 대상입니다. **이 파일이 없으면 빌드가 실패합니다.** 클론 직후 반드시 복사하세요.

```bash
cp FiveGuyes/Config.xcconfig.example FiveGuyes/Config.xcconfig
```

`Config.xcconfig`의 `API_KEY`에 알라딘 API 키를 넣습니다. 실제 인증 정보는 커밋하지 않습니다.

`GoogleService-Info.plist`(Firebase 설정 파일, `.gitignore` 대상)는 **Debug 빌드에서는 없어도 됩니다.** 없으면 앱이 Firebase 초기화를 건너뛰고 정상 실행되므로, 자격증명 없이도 빌드·실행이 가능합니다. 테스트는 plist 유무와 상관없이 Firebase와 ATT(앱 추적 투명성) 요청 없이 실행되며, CI도 이 파일을 만들지 않습니다. Release 빌드는 plist를 요구합니다.

Firebase 동작을 실제로 확인해야 할 때만 Firebase 콘솔(프로젝트 설정 > iOS 앱)에서 받은 `GoogleService-Info.plist`를 `FiveGuyes/FiveGuyes/` 안에 넣으세요. 앱 타깃은 이 폴더를 파일시스템 동기화 그룹으로 참조하므로 **그 폴더 안에 있는 파일만 앱 번들에 포함됩니다.** 견본 파일을 복사해 넣으면 `FirebaseApp.configure()`가 시작 중 크래시합니다.

Debug 빌드의 GA(Google Analytics) 수집은 기본으로 꺼져 있습니다. GA 동작을 확인하는 모드를 켜고 끄는 방법과 시작 동작 규칙은 `FiveGuyes/FiveGuyes/Sources/Platform/Analytics/AGENTS.md`를 참고하세요.

## 빌드, 테스트, 개발 명령

```bash
# 패키지 해석, lint, 단일 시뮬레이터 테스트
scripts/verify.sh

# 특정 시뮬레이터로 검사
SIMULATOR_DESTINATION='platform=iOS Simulator,name=iPhone 17' scripts/verify.sh

# verify.sh를 한 번 실행한 뒤 lint만 검사
cd FiveGuyes && ../.build/SourcePackages/artifacts/swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint lint
```

SwiftLint는 `SwiftLintBuildToolPlugin`(SPM 빌드 플러그인)으로 등록되어 있어 **빌드 시 자동 실행**됩니다. lint만 확인할 때는 위 명령을 사용하세요. 플러그인 버전이 바뀌면 Xcode가 플러그인을 다시 승인하라고 요구하고, 승인 전에는 로컬 빌드와 `verify.sh` 테스트가 실패합니다. Xcode에서 한 번 빌드하고 플러그인 경고에서 **Trust & Enable**을 누르세요(CI는 `-skipPackagePluginValidation`으로 건너뜀).

push 전 검증을 켜려면 클론마다 한 번 `git config core.hooksPath .githooks`를 실행합니다. 끄려면 `git config --unset core.hooksPath`를 실행합니다. hook은 깨끗한 작업 트리의 현재 HEAD를 push할 때만 검증을 보장합니다.

**주의:** 테스트는 병렬 실행을 끄고 단일 시뮬레이터로 실행하세요. 과거에 알림 권한 팝업 때문에 테스트가 멈춘 사례(#214)는 #215와, 테스트 중 Firebase·ATT 요청을 생략하는 앱 시작 규칙으로 원인이 해결되었습니다.

## 코딩 스타일 및 네이밍 규칙

Swift 기본 관례를 따릅니다. 들여쓰기는 4칸, 타입은 `UpperCamelCase`, 프로퍼티와 함수는 `lowerCamelCase`를 사용합니다. 가능하면 파일 하나에 주요 타입 하나를 둡니다. import는 정렬하고, 프로덕션 경로에서 강제 언래핑은 피합니다.

`FiveGuyes/.swiftlint.yml`의 규칙을 지키세요. SwiftLint는 정렬된 import, 강제 언래핑 경고, 라인 길이, 함수/타입 길이를 검사하며, 계층 경계와 Domain·Presentation import를 `severity: error`로 강제합니다. `print`, 신규 `@Published` 등은 warning으로 알립니다.

- ViewModel은 Service·Repository를 직접 의존하지 않습니다 — UseCase(`...Using`) 경계를 거칩니다.
- View는 `any ...Using`을 직접 참조하지 않습니다 — ViewModel을 경유합니다.
- View는 `@Environment(AppDependencies.self)`를 직접 사용하지 않습니다 — 조립 루트에서만 다룹니다.
- Domain은 UI·인프라 프레임워크를, Presentation은 Preview 외 SwiftData·Firebase·UserNotifications를 import하지 않습니다.

## 테스트 가이드라인

테스트 프레임워크는 **Swift Testing**입니다(XCTest 아님). `import Testing`, `@Suite`, `@Test`, `#expect` / `#require`를 사용하며, 테스트 타입은 `class`가 아니라 `struct`로 작성합니다. `@MainActor` 격리가 필요한 ViewModel 테스트에는 타입에 `@MainActor`를 붙입니다.

```swift
@testable import FiveGuyes
import Foundation
import Testing

@Suite("DailyProgressViewModel 테스트")
@MainActor
struct DailyProgressViewModelTests {
    @Test("DailyProgressViewModel: 목표 초과 입력 시 제출 차단")
    func dailyProgress_overTarget_preventsSubmit() {
        let viewModel = DailyProgressViewModel(
            dailyReadingUseCase: DailyReadingUseCaseStub(),
            bookCompletionUseCase: BookCompletionUseCaseStub()
        )
        viewModel.pagesToReadToday = 101

        let canSubmit = viewModel.requestSubmit(targetEndPage: 100)

        #expect(!canSubmit)
        #expect(viewModel.showTargetExceededAlert)
    }
}
```

테스트 파일은 대상 타입 이름을 따라 `DailyProgressViewModelTests.swift`처럼 작성하고, 공통 픽스처는 `*TestSupport.swift`에 둡니다. 테스트 대역은 역할에 따라 `...Stub`(고정 응답) 또는 `...Spy`(호출 기록)로 이름 짓습니다. 도메인 계산기, 정책, UseCase, Repository 동작, ViewModel 상태 전이가 바뀌면 관련 테스트를 추가하거나 갱신하세요.

## 기능 문서와 우선순위

작업 흐름은 `develop`에서 `feature/issue-<번호>-<설명>` 또는 `bugfix/...` 브랜치를 만들고, 동작이 바뀌면 `docs/features` 명세를 같은 PR에서 먼저 고친 뒤 구현·`scripts/verify.sh`·PR 템플릿·develop 머지 순서입니다. 출시는 develop에서 main으로 머지합니다. 기능 요구사항을 검증하는 테스트 이름에는 대응 ID를 넣습니다(예: `notiSetting_c2_...`). 계산기·마이그레이션·저장소 등 ID가 없는 테스트에는 요구하지 않습니다.

`docs/README.md`가 `docs/` 하위 폴더의 성격과 고치는 법을 설명합니다. 앱이 어떻게 동작해야 하는지의 기준은 `docs/features/`의 기능 문서입니다. 코드가 기능 문서와 다르면 코드의 버그로 보고 이슈로 추적합니다.

## 설계 배경 문서

구조 개요는 `ARCHITECTURE.md`에 있습니다. 계층 경계나 내비게이션 정책을 바꾸는 작업이라면 **먼저 관련 ADR을 읽으세요.** 아래 결정들은 코드만 봐서는 이유를 복원할 수 없습니다.

- `docs/decisions/adr-0001-presentation-architecture.md` — Feature 단위 MVVM과 상태 흐름
- `docs/decisions/adr-0002-usecase-first-boundary.md` — ViewModel이 UseCase를 직접 주입받는 이유
- `docs/decisions/adr-0003-reading-record-key-migration-policy.md` — SwiftData 독서 기록 키 마이그레이션
- `docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md` — 타임존 forward-only 정책
- `docs/decisions/adr-0005-settings-localdate-source-of-truth.md` — 설정 화면의 날짜 기준
- `docs/decisions/adr-0006-stack-back-path-only-policy.md` — back을 path로만 처리하는 이유
- `docs/decisions/adr-0007-navigation-back-gesture-action-boundary.md` — back 제스처와 액션의 경계

## 커밋 및 Pull Request 가이드라인

접두사(`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`)는 영어로 쓰고 제목·본문은 한국어로 씁니다. PR에는 변경 목적, 검증한 명령, 관련 이슈나 ADR 링크를 포함하고, UI가 바뀌면 스크린샷 또는 녹화를 첨부하세요.

## 프로젝트와 비밀값 주의

새 Swift 파일은 Xcode 프로젝트 파일을 고칠 필요가 없습니다. 소스·테스트 폴더 안 비코드 파일은 해당 타깃의 `membershipExceptions`에 추가합니다. `DEVELOPMENT_TEAM`과 공유 스킴의 디버그 인자 변경은 커밋하지 않습니다. `Config.xcconfig`의 키와 plist 값은 출력·커밋하지 않습니다(현재 키 이름: `API_KEY`).

시뮬레이터·프리뷰가 깨지면 시뮬레이터 서비스를 재시작하고, 프리뷰 캐시를 삭제한 뒤, 시뮬레이터를 초기화합니다. `.local/`은 개인 작업 문서 보관용이며 git이 추적하지 않습니다.
