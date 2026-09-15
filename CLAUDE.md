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

계층별 상세 규약은 해당 디렉터리의 `CLAUDE.md`를 함께 참고하세요.

## 첫 빌드 전 필수 설정

`Config.xcconfig`는 Debug/Release 양쪽의 base configuration이며 `.gitignore` 대상입니다. **이 파일이 없으면 빌드가 실패합니다.** 클론 직후 반드시 복사하세요.

```bash
cp FiveGuyes/Config.xcconfig.example FiveGuyes/Config.xcconfig
cp FiveGuyes/GoogleService-Info.plist.example FiveGuyes/FiveGuyes/GoogleService-Info.plist
```

`Config.xcconfig`의 `API_KEY`에 알라딘 API 키를 넣습니다. 실제 인증 정보는 커밋하지 않습니다.

`GoogleService-Info.plist`는 빌드에는 필요 없고 Firebase 런타임 동작에만 쓰입니다. 복사 위치에 주의하세요. 앱 타깃은 `FiveGuyes/FiveGuyes/`를 파일시스템 동기화 그룹으로 참조하므로 **그 폴더 안에 있는 파일만 앱 번들에 포함됩니다.** 한 단계 위(`FiveGuyes/`)에 두면 `FirebaseApp.configure()`가 설정을 찾지 못합니다.

## 빌드, 테스트, 개발 명령

```bash
# 타깃과 스킴 확인
xcodebuild -list -project FiveGuyes/FiveGuyes.xcodeproj

# 시뮬레이터용 빌드
xcodebuild build -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# 단위 테스트 (병렬 비활성화 — 아래 주의 참고)
xcodebuild test -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1
```

SwiftLint는 `SwiftLintBuildToolPlugin`(SPM 빌드 플러그인)으로 등록되어 있어 **빌드 시 자동 실행**됩니다. 별도 실행이 필요하면 CLI를 쓸 수 있습니다.

```bash
swiftlint lint --config FiveGuyes/.swiftlint.yml
```

**주의:** 테스트가 시뮬레이터 안에서 멈추는 사례가 있었습니다. 병렬 테스트를 끄고 단일 시뮬레이터로 실행하세요. Firebase/네트워크 로그가 계속 출력되는 동안에도 테스트 자체는 멈춰 있을 수 있어, 로그 출력량만으로 진행 여부를 판단하면 안 됩니다.

## 코딩 스타일 및 네이밍 규칙

Swift 기본 관례를 따릅니다. 들여쓰기는 4칸, 타입은 `UpperCamelCase`, 프로퍼티와 함수는 `lowerCamelCase`를 사용합니다. 가능하면 파일 하나에 주요 타입 하나를 둡니다. import는 정렬하고, 프로덕션 경로에서 강제 언래핑은 피합니다.

`FiveGuyes/.swiftlint.yml`의 규칙을 지키세요. SwiftLint는 정렬된 import, 강제 언래핑 경고, 라인 길이, 함수/타입 길이를 검사하며, 계층 의존성을 막는 커스텀 룰 3개를 `severity: error`로 강제합니다.

- ViewModel은 `...Managing` / `...Providing` / `...Storing` / `...Opening`을 직접 의존하지 않습니다 — UseCase(`...Using`) 경계를 거칩니다.
- View는 `any ...Using`을 직접 참조하지 않습니다 — ViewModel을 경유합니다.
- View는 `@Environment(AppDependencies.self)`를 직접 사용하지 않습니다 — 조립 루트에서만 다룹니다.

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

최근 커밋은 `fix:`, `refactor:`, `docs:`, `chore:` 같은 Conventional Commit 스타일 접두사를 사용합니다. 제목은 짧고 변경 내용을 구체적으로 적습니다. PR에는 변경 목적, 검증한 명령, 관련 이슈나 ADR 링크를 포함하고, UI가 바뀌면 스크린샷 또는 녹화를 첨부하세요.
