# Navigation Stack Back Path-Only Unification and Duplicate Push Guard

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/PLANS.md`.

## Purpose / Big Picture

이번 작업의 목적은 스택 네비게이션 back 동작을 `NavigationCoordinator` path 명령으로 단일화해 간헐적인 이중 이동 리스크를 제거하는 것입니다. 사용자는 back을 눌렀을 때 항상 한 가지 규칙으로 이동하고, 빠른 연속 탭으로 같은 화면이 중복 적재되지 않습니다.

구체적으로는 shared back에서 `dismiss`를 제거하고, `NavigationCoordinator.push/pop/popToRoot` 계약을 typed path + 안전 반환값으로 정비합니다. 동시에 아키텍처 문서(`ARCHITECTURE.md`)와 ADR(`adr-0006`)에 규칙/예외를 명시해 코드와 문서를 동기화합니다.

## Progress

- [x] (2026-02-18 17:56Z) `NavigationCoordinator.paths`를 `NavigationPath`에서 `[Screens]`로 전환했다.
- [x] (2026-02-18 17:58Z) `Screens.routeKey`를 도입하고 `push(_:allowDuplicateRoute:)` 기본 정책에서 동일 route 연속 push 차단을 적용했다.
- [x] (2026-02-18 18:00Z) `pop()`/`popToRoot()`를 crash-free 계약(`Bool` 반환)으로 변경했다.
- [x] (2026-02-18 18:02Z) `CustomBackButton`에서 `dismiss` 경로를 제거하고 coordinator 기반 `pop` 기본 동작으로 전환했다.
- [x] (2026-02-18 18:03Z) `CompletionReviewView` 특수 분기를 `backBehavior(.none)` + `popToRoot` action으로 고정했다.
- [x] (2026-02-18 18:04Z) `NotiSettingView`, `MultiBookProgressView`, `CustomBackButton` preview에 coordinator 환경을 보강했다.
- [x] (2026-02-18 18:06Z) `NavigationCoordinatorTests`를 신규 추가해 중복 push 가드와 안전 pop 계약을 검증했다.
- [x] (2026-02-18 18:08Z) 타깃 자동 테스트(`NavigationCoordinatorTests`, `CompletionReviewViewModelTests`, `DailyProgressViewModelTests`)를 실행해 통과했다.
- [x] (2026-02-18 18:10Z) `ARCHITECTURE.md` 불변식 갱신 및 `docs/decisions/adr-0006-stack-back-path-only-policy.md` 신규 작성을 완료했다.
- [ ] (2026-02-18 18:11Z) 기기 수동 시나리오 3건(더블탭 중복 진입, 축하->소감 back, 완독리스트->수정 back) 확인 필요.

## Surprises & Discoveries

- Observation: 현재 코드베이스에서 `dismiss()` 직접 호출은 shared back(`CustomBackButton`) 1곳뿐이었다.
  Evidence: `rg -n "dismiss\(" FiveGuyes/FiveGuyes/Sources -S` 결과.

- Observation: 운영 경로에서 modal 라우팅(`sheet/fullScreenCover/popover`) 사용이 없고 루트 `NavigationStack` 단일 경로가 메인 이동 경계였다.
  Evidence: `NavigationRootView.swift` + 전체 검색 결과.

- Observation: preview 일부(`NotiSettingView`, `MultiBookProgressView`)는 shared back 사용에도 coordinator 환경이 없어 path-only 전환 시 보정이 필요했다.
  Evidence: 각 preview 블록 점검.

## Decision Log

- Decision: stack back은 path-only(`pop`/`popToRoot`)로 고정하고 shared back에서 `dismiss`를 제거한다.
  Rationale: stack 경로 제어와 presentation dismiss 책임을 분리해야 컨테이너 구성과 무관하게 back 동작이 결정적으로 유지된다.
  Date/Author: 2026-02-18 / Codex

- Decision: 빠른 연속 탭 방지는 view별 로직이 아니라 `NavigationCoordinator.push` 기본 정책에서 수행한다.
  Rationale: 중복 화면 적재 방지 규칙을 라우팅 경계에서 일관 적용해야 누락/재도입 위험을 줄일 수 있다.
  Date/Author: 2026-02-18 / Codex

- Decision: route 중복 판단은 payload 전체가 아닌 `Screens.routeKey`(화면 타입 단위)로 수행한다.
  Rationale: 같은 화면 타입이 연속으로 쌓이는 UX를 기본 금지해 더블탭 이슈를 직접 차단하고, 예외는 `allowDuplicateRoute` opt-in으로 제한한다.
  Date/Author: 2026-02-18 / Codex

- Decision: 네비게이션 정책 변경은 코드 수정과 함께 ADR-0006으로 고정한다.
  Rationale: 재발 방지를 위해 코드 수준 가드와 문서 수준 규칙을 동시에 유지해야 한다.
  Date/Author: 2026-02-18 / Codex

## Outcomes & Retrospective

완료 결과:

- `NavigationCoordinator`가 typed path 기반으로 정리되어 push/pop/popToRoot 계약이 명시적(`Bool`)이고 안전해졌습니다.
- shared back 컴포넌트는 stack back 책임만 담당하고 `dismiss` 책임은 분리되었습니다.
- 동일 route 연속 push 차단이 coordinator 기본 정책으로 적용되어 더블탭 중복 진입 리스크를 줄였습니다.
- 테스트(신규 + 기존 타깃) 통과로 핵심 회귀는 자동 검증됐습니다.
- 아키텍처 문서/ADR에 정책과 예외가 반영되어 유지보수 기준이 명문화됐습니다.

남은 항목:

- 실제 디바이스/시뮬레이터 수동 시나리오 3건 확인 기록.

## Context and Orientation

이번 작업의 핵심 파일:

- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/Shared/CustomBackButton.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionReviewView.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Presentation/ViewModel/NavigationCoordinatorTests.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/ARCHITECTURE.md`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0006-stack-back-path-only-policy.md`

용어 정의:

- path-only back: `NavigationStack` 경로를 `pop`/`popToRoot`로만 조작해 뒤로 가기 동작을 만드는 방식.
- routeKey: payload와 무관하게 화면 타입을 식별하는 키(`Screens` case 단위).

## Plan of Work

첫 단계로 coordinator를 typed path로 옮기고 routeKey 기반 중복 push 가드를 추가했습니다. 이 변경으로 화면 이동 정책이 라우팅 경계에 집중됩니다.

둘째 단계로 shared back을 `dismiss` 기반에서 coordinator `pop` 기반으로 교체했습니다. 특수 흐름(완독 소감 편집/작성)의 root 복귀는 `backBehavior(.none)` + action(`popToRoot`) 조합으로 분리했습니다.

셋째 단계로 preview의 coordinator 환경 누락을 보정해 개발/검증 경로를 안정화했습니다.

넷째 단계로 NavigationCoordinator 테스트를 추가하고 기존 관련 ViewModel 테스트를 재실행했습니다.

마지막으로 아키텍처 불변식과 ADR을 갱신해 정책을 문서로 고정했습니다.

## Concrete Steps

작업 디렉터리: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 코드 수정
   - `NavigationCoordinator.swift`: typed path, routeKey, push/pop/popToRoot 계약 변경
   - `CustomBackButton.swift`: dismiss 제거, backBehavior 기반 coordinator pop
   - `CompletionReviewView.swift`: `backBehavior` 분기 반영
   - `NotiSettingView.swift`, `MultiBookProgressView.swift`: preview coordinator 주입

2. 테스트 추가
   - `NavigationCoordinatorTests.swift` 신규 작성

3. 자동 검증 실행

   xcodebuild test -quiet -parallel-testing-enabled NO -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/NavigationCoordinatorTests -only-testing:FiveGuyesTests/CompletionReviewViewModelTests -only-testing:FiveGuyesTests/DailyProgressViewModelTests

4. 문서 반영
   - `ARCHITECTURE.md` 불변식 추가
   - `docs/decisions/adr-0006-stack-back-path-only-policy.md` 신규 작성

## Validation and Acceptance

자동 검증 결과:

- 위 `xcodebuild test` 명령이 exit code `0`으로 통과했다.
- 로그에서 테스트 완료 시점(`Testing started completed`)이 확인됐다.

수용 기준 상태:

- stack back path-only: 충족
- coordinator 중복 push 차단: 충족
- 아키텍처 문서 + ADR 반영: 충족
- 자동 테스트 회귀 검증: 충족
- 수동 시나리오 3건: 미확인(후속 필요)

## Idempotence and Recovery

변경은 모두 additive 또는 국소 교체이며 재적용 시 충돌 범위가 제한적입니다. rollback이 필요하면 아래 파일을 개별 되돌리면 됩니다.

- `NavigationCoordinator.swift`
- `CustomBackButton.swift`
- `CompletionReviewView.swift`
- `NotiSettingView.swift`
- `MultiBookProgressView.swift`
- `NavigationCoordinatorTests.swift`
- `ARCHITECTURE.md`
- `docs/decisions/adr-0006-stack-back-path-only-policy.md`

## Artifacts and Notes

핵심 산출물:

- 신규 테스트: `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/NavigationCoordinatorTests.swift`
- 신규 ADR: `docs/decisions/adr-0006-stack-back-path-only-policy.md`

테스트 실행 기록 요약:

- 명령: targeted `xcodebuild test` (3 suites)
- 결과: exit code `0`
- 비고: 기존 SwiftLint 경고와 Run Script 경고는 출력됐으나 실패는 아님

## Interfaces and Dependencies

작업 후 주요 인터페이스:

- `NavigationCoordinator.paths: [Screens]`
- `Screens.routeKey: ScreenRouteKey`
- `push(_ screen: Screens, allowDuplicateRoute: Bool = false) -> Bool`
- `pop() -> Bool`
- `popToRoot() -> Bool`
- `customNavigationBackButton(action:backBehavior:)`
- `BackNavigationBehavior` (`.pop`, `.none`)

외부 라이브러리 추가/변경은 없습니다.

Plan revision note (2026-02-18): 범위를 CompletionReview 단건 안전화에서 stack back 정책 전면 정렬(path-only + 중복 push 가드 + ADR 문서화)로 확장했고, 구현/테스트/문서 결과를 반영했습니다.
