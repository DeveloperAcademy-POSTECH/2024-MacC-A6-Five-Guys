# Navigation Back/Gesture Hook Boundary Refactor (Documentation-First)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/PLANS.md` and must be maintained in accordance with that file.

## Purpose / Big Picture

이번 단계의 목표는 구현이 아니라 설계 의사결정을 문서로 고정하는 것이다. 사용자는 back 버튼과 스와이프 제스처의 책임 경계, 액션 실행 규칙, 화면별 정책 차이를 문서만으로 이해할 수 있어야 하며, 다음 구현 단계의 담당자는 추가 맥락 없이 이 계획서를 따라 실제 변경을 수행할 수 있어야 한다.

이번 산출물은 두 가지다. 첫째는 문제-해결-선택 근거를 담은 신규 ADR이고, 둘째는 코드 변경과 검증 절차를 실행 단위로 정리한 ExecPlan이다.

## Progress

- [x] (2026-02-21 00:15Z) 기존 navigation 관련 ADR/ExecPlan(`ADR-0006`, back/swipe 안정화 계획서)을 재점검해 배경 근거를 수집했다.
- [x] (2026-02-21 00:20Z) 신규 ADR 방향을 `docs/decisions/` 체계로 확정하고 설계 쟁점(책임 혼재, 버튼/제스처 경로 불일치, 전역 delegate 리스크, 식별자 리스크)을 정리했다.
- [x] (2026-02-21 00:25Z) `adr-0007-navigation-back-gesture-action-boundary.md` 초안을 작성해 선택한 해결 전략과 가드레일을 기록했다.
- [x] (2026-02-21 00:30Z) 본 ExecPlan에 구현 단계 milestone, 인터페이스 변경 계획, 테스트/수동 시나리오를 고정했다.
- [x] (2026-02-21 13:45Z) `NavigationCoordinator`에 hook/식별자(`routeInstanceID + routeKey`) 계약을 추가하고 path 타입을 `NavigationPathItem`으로 전환했다.
- [x] (2026-02-21 13:50Z) `CustomBackButton`을 coordinator 단일 back 집행 파이프라인으로 전환하고 `UnfinishReading`, `BookSettingsManager`에 before/step-pop hook을 연결했다.
- [x] (2026-02-21 13:54Z) `completionReviewUpdate` 시그니처를 단일화하고 `CompletionCelebration`, `CompletionReview`, `CompletedBooks` 호출부를 동기화했다.
- [x] (2026-02-21 13:58Z) targeted 테스트(`NavigationCoordinatorTests`, `UnfinishReadingViewModelTests`, `CompletionReviewViewModelTests`)를 실행해 exit code 0을 확인했다.
- [x] (2026-02-21 13:58Z) `ADR-0007` 상태를 `Accepted`로 갱신하고 본 ExecPlan living 섹션을 구현 결과로 업데이트했다.

## Surprises & Discoveries

- Observation: 저장소에는 `docs/references/architecture-doc.md`가 없고, 아키텍처 결정 기록은 `docs/decisions/`의 ADR 체계로 관리된다.
  Evidence: `ls docs/references` 실패, `ls docs/decisions` 성공.

- Observation: custom back 액션을 실제로 연결한 화면은 현재 두 군데(`UnfinishReadingView`, `BookSettingsManagerView`)다.
  Evidence: `rg -n "customNavigationBackButton\(" FiveGuyes/FiveGuyes/Sources/Presentation/View -S` 결과.

- Observation: 현재 제스처 정책 적용은 root host(`NavigationInteractivePopHost`) 단일 지점 구조를 이미 갖추고 있다.
  Evidence: `FiveGuyes/FiveGuyes/Sources/App/NavigationRootView.swift` + `FiveGuyes/FiveGuyes/Sources/Presentation/Shared/Navigation/NavigationInteractivePopHost.swift`.

- Observation: `popToRoot`가 경로 길이 1 상태에서 실행되면 path diff만으로는 step-pop과 구분되지 않아 후행 훅 오실행 가능성이 있다.
  Evidence: `old.count == new.count + 1` 기준만 두면 `popToRoot(1->0)`가 step-pop 조건을 만족함.

- Observation: 시스템 스와이프 pop 경로에서 hook 타깃의 인스턴스 구분이 없으면 동일 routeKey 재진입 시 stale hook이 오동작할 수 있다.
  Evidence: `routeKey` 단독 식별은 이전 route와 신규 route를 분리하지 못해, `NavigationPathItem(routeInstanceID:)`가 필요했다.

## Decision Log

- Decision: 설계 문서화는 기존 ADR 수정이 아니라 신규 ADR(`ADR-0007`)로 분리한다.
  Rationale: `ADR-0006`의 path-only 결정을 보존하면서, 이번 단계의 핵심(훅 경계/식별자/실행 순서)을 독립 결정으로 추적하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: hook 모델은 `beforeBackAction`(판정 전용)과 `onStepPopExitAction`(후행 전용)의 2계층으로 고정한다.
  Rationale: 버튼/제스처 경로를 공통화하면서도 중복 side effect를 방지하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: 제스처 delegate 관리는 root host 단일 지점 원칙을 유지하고 전역 `UINavigationController` extension 방식은 금지한다.
  Rationale: 영향 범위를 제한해 회귀 분석 가능성을 유지하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: 훅 식별은 `routeInstanceID + routeKey`로 강화하고, `beforeBackAction` 실패 기본값은 `cancel`로 둔다.
  Rationale: 중복 route/비동기 타이밍에서의 오동작 및 예기치 않은 이탈을 방지하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: 버튼 back 집행 진입점은 `CustomBackButton` 직접 pop 호출이 아니라 `NavigationCoordinator.handleBackButtonTap()` 단일 API로 고정한다.
  Rationale: 버튼/제스처 경로의 실행 순서(`before -> 전이 -> step-pop 후행`)를 한 곳에서 강제하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: `popToRoot`는 경로 변화가 step-pop 형태를 보이더라도 후행 훅을 억제하는 suppress 집합으로 분기한다.
  Rationale: ADR-0007 가드레일(`onStepPopExitAction`은 step-pop만, popToRoot 미적용)을 단일 전이 파이프라인에서 보장하기 위함.
  Date/Author: 2026-02-21 / Codex

- Decision: `bookSettingsManager`의 page 단계 롤백은 coordinator로 올리지 않고 View(`beforeBackAction`)에 둔다.
  Rationale: page/index/input 정리는 navigation 공통 정책이 아니라 화면 로컬 상태 전이이므로, 해당 화면에 응집하는 편이 변경 범위를 최소화한다.
  Date/Author: 2026-02-21 / Codex

- Decision: `customNavigationBackButton`의 `hookRevision` 파라미터는 제거한다.
  Rationale: 훅 대상은 `routeInstanceID + routeKey`로 식별되고, `bookSettingsManager` 판정은 참조형 상태를 읽어 최신 page 값을 사용하므로 재등록 트리거가 필수 조건이 아니다.
  Date/Author: 2026-02-21 / Codex

## Outcomes & Retrospective

문서로 고정한 경계를 실제 코드에 반영해 버튼/스와이프 경로를 coordinator 단일 파이프라인으로 통합했다. `completionReviewUpdate` 시그니처 단일화, `beforeBackAction`/`onStepPopExitAction` 분리, `routeInstanceID + routeKey` 식별, `popToRoot` 후행 훅 억제까지 구현 완료했다.

검증 측면에서는 targeted 테스트를 실행해 종료 코드 0을 확인했고, 화면 정책은 설계 명세(`completionCelebration`, `completionReview`, `unfinishReading`, `bookSettingsManager`)와 동일하게 코드 경계를 정렬했다. 후속 과제는 필요 시 수동 시나리오 실행 로그를 추가 축적하는 것이다.

## Context and Orientation

현재 navigation 경계의 핵심 파일은 `NavigationRootView`, `NavigationCoordinator`, `CustomBackButton`, `NavigationInteractivePopHost`, 그리고 back 액션이 연결된 `UnfinishReadingView`, `BookSettingsManagerView`다. 구현 단계에서 이 파일들을 중심으로 계약 변경을 진행한다.

본 계획의 핵심 용어는 step-pop(경로 길이가 정확히 1 감소하는 pop 전이), beforeBackAction(back 실행 직전 proceed/cancel 판정 훅), onStepPopExitAction(step-pop 완료 후 실행되는 후행 훅), routeInstanceID(동일 route 타입의 비동기 타이밍을 구분하는 인스턴스 식별자)다.

다음 구현 단계에서 고정할 정책 기준선은 다음과 같다. `mainHome`는 back 없이 gesture를 비활성화한다. `notiSetting`, `totalCalendar`, `dailyProgress`, `readingDateEdit`, `completionReview`는 `backMode=.pop`과 gesture 활성 정책을 사용한다. `bookSettingsManager`는 전 구간 gesture를 비활성화하고, page1은 `pop`, page2~5는 `none + beforeBackAction(단계 롤백)`을 적용한다. `completionCelebration`은 `backMode=.popToRoot`, gesture 비활성, back 버튼 노출 정책을 사용한다. `unfinishReading`은 `backMode=.pop`, gesture 활성, `onStepPopExitAction` 적용 정책을 사용한다.

## Plan of Work

Milestone 1에서는 문서 기준선을 확정한다. `ADR-0006`과 현재 코드 경계를 재확인하고, 이번 리팩터링의 해결 대상을 구현 언어가 아니라 행동 계약으로 다시 서술한다.

Milestone 2에서는 계약과 시나리오를 잠근다. `Screens` 계약 변경, 훅 시그니처, 식별자 전략, 실패/재진입 규칙, 화면별 back/gesture 매트릭스를 확정한다.

Milestone 3에서는 구현 실행 계획과 검증 계획을 구체화한다. 파일별 예상 변경 범위를 명시하고, 단위 테스트와 수동 시나리오 수용 기준을 확정한다.

Milestone 4에서는 리뷰 반영 작업을 수행한다. 구현 전 변경 위험과 롤백 경로를 보강하고, 구현 후 갱신이 필요한 living 섹션 업데이트 절차를 명시한다.

## Concrete Steps

작업 디렉터리: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

다음 단계의 첫 작업은 기준선 수집이다. 아래 명령으로 현재 정책 지점을 확인한다.

    rg -n "defaultBackPolicy|effectiveTopPolicy|isInteractivePopEnabled|customNavigationBackButton|navigationRootBackHost" FiveGuyes/FiveGuyes/Sources -S
    rg -n "customNavigationBackButton\(" FiveGuyes/FiveGuyes/Sources/Presentation/View -S

기준선 확인 후 `NavigationCoordinator`에 hook/식별자 계약을 추가하고, `Screens.completionReviewUpdate` 시그니처를 단일화하며, `UnfinishReading`과 `BookSettingsManager`를 새 계약에 맞춘다. 이어서 `NavigationCoordinatorTests`에 hook 실행 순서, cancel 경계, step-pop 경계, in-flight 잠금 케이스를 추가하고 필요 시 ViewModel 테스트의 back 액션 호출 계약을 보강한다.

마지막으로 문서를 동기화한다. 구현 결과에 맞춰 `ADR-0007` 상태를 `Proposed`에서 `Accepted`로 갱신하고, 본 ExecPlan의 `Progress`, `Surprises & Discoveries`, `Outcomes & Retrospective`에 실행 증거를 반영한다.

## Validation and Acceptance

수용 기준은 행동으로 판정한다. 버튼 back에서 `beforeBackAction`이 `cancel`이면 pop이 발생하지 않아야 하며, `proceed`인 경우에는 step-pop 이후 `onStepPopExitAction`이 정확히 1회 실행되어야 한다. 시스템 스와이프 pop에서도 같은 후행 훅이 1회 실행되어야 하고, `popToRoot`에서는 실행되지 않아야 한다. 동일 route instance에서 back in-flight 중복 트리거는 차단되어야 하며, `routeInstanceID`가 불일치한 hook은 실행되면 안 된다.

수동 시나리오는 네 가지를 확인한다. `completionCelebration`에서는 gesture가 비활성이고 back 버튼이 `popToRoot`로 동작해야 한다. `completionReview`에서는 back과 gesture가 모두 one-step pop으로 동작해야 한다. `unfinishReading`에서는 버튼과 gesture 모두에서 동일 후행 액션이 실행되어야 한다. `bookSettingsManager`는 전 구간 gesture가 비활성이고, page2~5에서는 back 시 단계 롤백만 발생해야 한다.

## Idempotence and Recovery

문서 단계는 재실행 가능하며, 현재 단계의 변경은 markdown 문서 추가/수정만 포함하므로 재적용 충돌은 파일 경로 단위로 제한된다.

다음 구현 단계에서 문제가 발생하면 `NavigationCoordinator.swift`, `CustomBackButton.swift`, `NavigationInteractivePopHost.swift`, `UnfinishReadingView.swift`, `BookSettingsManagerView.swift`, `NavigationCoordinatorTests.swift`를 파일 단위로 롤백한다. 문서는 구현 증거와 함께 계속 갱신하고, 실패한 시도와 변경 이유는 `Decision Log`와 `Surprises & Discoveries`에 누적 기록한다.

## Artifacts and Notes

이번 단계 산출물은 신규 ADR(`/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0007-navigation-back-gesture-action-boundary.md`)과 본 ExecPlan(`/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/exec-plans/navigation-back-gesture-refactor-execplan.md`)이다.

이번 단계에서 구현/테스트까지 수행했고, `ADR-0007` 상태를 `Accepted`로 전환했다.

테스트 실행 증거:
    xcodebuild test -quiet -parallel-testing-enabled NO -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/NavigationCoordinatorTests -only-testing:FiveGuyesTests/UnfinishReadingViewModelTests -only-testing:FiveGuyesTests/CompletionReviewViewModelTests
    Testing started
    ... IDETestOperationsObserverDebug: Testing started completed.
    (exit code 0)

## Interfaces and Dependencies

다음 단계 구현 완료 시에는 네 가지 계약이 존재해야 한다. 첫째, `Screens`에서 `completionReviewUpdate(book: FGUserBook, popToRootOnBack: Bool)`를 제거하고 `completionReviewUpdate(book: FGUserBook)`만 유지한다. 둘째, hook 계약으로 `beforeBackAction: () async -> BackDecision`, `onStepPopExitAction: () async -> Void`, `BackDecision = .proceed | .cancel`를 제공한다. 셋째, hook 대상을 `routeInstanceID + routeKey` 조합으로 식별한다. 넷째, 제스처 정책은 root host 단일 지점에서만 집행하고 전역 `UINavigationController` extension delegate 제어는 금지한다.

## Assumptions and Defaults

1. 이번 단계는 문서 기준 리팩터링 구현과 테스트까지 포함한다.
2. 검증은 targeted 자동화 테스트를 기본으로 하고, 수동 시나리오는 필요 시 추가 증거를 누적한다.
3. 문서 언어는 한국어 중심으로 작성하고, 타입/시그니처 표기는 코드 표기를 유지한다.
4. 아키텍처 문서 규칙은 저장소 실제 구조 기준으로 `docs/decisions/` ADR 체계를 따른다.

Plan revision note (2026-02-21 13:58Z): 문서 우선 단계에서 고정한 경계를 실제 코드로 구현 완료했고, targeted 테스트 통과 및 ADR 상태(`Accepted`) 전환 결과를 living 섹션 전체에 반영했다.
