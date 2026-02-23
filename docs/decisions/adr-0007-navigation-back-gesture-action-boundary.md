# ADR-0007: Navigation Back/Gesture Action Boundary (Before/Step-Pop Hook Model)

- Status: Accepted
- Date: 2026-02-21
- Owners: FiveGuyes team
- Related: `docs/decisions/adr-0006-stack-back-path-only-policy.md`

## Decision

`ADR-0006`의 path-only 원칙은 유지한다. 추가로 back/gesture 액션 일관성을 위해 책임 경계를 아래처럼 고정한다.

1. View는 back UI 선언과 back 전 판정 훅만 가진다.
- 선언 범위: `showsBackButton`, `beforeBackAction`
- 구현 원칙: `beforeBackAction`은 ViewModel 메서드를 호출한다.

2. Navigation 계층은 이동 정책 집행만 담당한다.
- 정책 범위: `backMode` (`pop`, `popToRoot`, `none`), `gestureEnabled`
- 집행 주체: `NavigationCoordinator`(또는 동등한 navigation store)

3. Hook을 2계층으로 분리한다.
- `beforeBackAction`: `proceed/cancel` 판정 전용
- `onStepPopExitAction`: step-pop 완료 후 후행 액션 전용

4. 훅 오동작 방지를 위해 식별자를 강화한다.
- 대상 식별: `routeInstanceID + routeKey`
- `routeKey` 단독 식별 사용 금지

5. 제스처 제어는 root host 단일 지점에서만 수행한다.
- 허용 경로: `NavigationInteractivePopHost` 단일 지점
- 금지 경로: 앱 전역 `UINavigationController` extension delegate 개입

6. 안전성 기본값을 고정한다.
- `beforeBackAction` 실패 기본값: `cancel`
- back 처리 중 재진입: `in-flight` 잠금
- `onStepPopExitAction` 적용 범위: step-pop만 허용, `popToRoot`에는 미적용

## Context

`ADR-0006` 적용으로 stack back이 path-only로 정렬되었지만, 아래 문제가 남아 있다.

1. Back 정책 책임 혼재
- View와 Navigation 계층이 back 의도를 동시에 다뤄 경계가 불명확하다.

2. 버튼/제스처 액션 불일치 리스크
- `onBackButtonTapped`만으로는 시스템 스와이프 pop 경로를 커버할 수 없다.

3. 제스처 제어 범위 리스크
- `UINavigationController` 전역 delegate 개입은 영향 범위가 넓고 회귀 분석이 어렵다.

4. 훅 대상 식별 리스크
- route 타입 기반 식별만으로는 중복 route/비동기 타이밍에서 오동작 여지가 있다.

현재 코드 관찰 기준으로 custom back 액션이 실제로 연결된 화면은 다음 2개다.

- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/UnfinishReadingView.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`

즉, 화면별 특수 액션 자체는 제한적이지만, 제스처 경로의 일관성 보장을 위해 공통 규칙이 필요하다.

## Options considered

### Option A: 기존 구조 확장 (`Screens.defaultBackPolicy` 중심 + 화면별 액션 개별 처리)

- 장점:
  - 변경 폭이 작다.
  - 현재 코드와 가장 가깝다.
- 단점:
  - 스와이프 pop 경로와 버튼 경로의 액션 동등성 보장이 어렵다.
  - `before`와 `after` 액션 경계가 화면별로 다시 분산된다.

### Option B: View 파일에서 back/gesture/pop 모드 전부 직접 선언 및 집행

- 장점:
  - 화면 파일 가독성이 즉시 높아 보인다.
- 미선택 이유:
  - 정책 누락과 편차가 쉽게 발생한다.
  - root-level gesture 집행 모델과 충돌한다.
  - 테스트 포인트가 View 파일로 분산된다.

### Option C: 선언/집행 분리 + 2계층 hook 모델 (선택)

- 장점:
  - 책임 경계가 명확하다. (View 선언, Navigation 집행)
  - 버튼/스와이프 동등성을 공통 파이프라인으로 보장할 수 있다.
  - 실패/재진입/식별자 규칙을 중앙 테스트로 고정할 수 있다.
- 단점:
  - hook 타입과 전이 처리 로직이 추가되어 초기 설계 비용이 든다.

### Option D: 전역 `UINavigationController` extension으로 delegate 강제 설정

- 장점:
  - 제스처가 즉시 동작할 수 있다.
- 미선택 이유:
  - 범위가 과도하게 넓다.
  - SwiftUI `NavigationStack` 내부 정책과 충돌 위험이 크다.
  - 특정 화면 정책을 세밀하게 반영하기 어렵다.

## Rationale

이번 결정의 목적은 복잡도 증가가 아니라 복잡도의 위치를 통제하는 것이다.

1. 결정성
- back 버튼과 스와이프를 동일한 path 전이 관점으로 해석하면 동작 예측 가능성이 높아진다.

2. 범위 격리
- UIKit 제스처 제어를 root host 한 곳으로 제한해야 회귀 원인을 추적할 수 있다.

3. 테스트 용이성
- `beforeBackAction`(판정)과 `onStepPopExitAction`(후행)을 분리하면 실패/취소/중복 실행을 명확히 검증할 수 있다.

4. MVVM + Clean 정합성
- ViewModel은 비즈니스 액션만 담당하고, navigation 정책 집행은 presentation navigation 계층에서 수행하는 구조가 경계에 부합한다.

5. 화면 로컬 전이 응집
- `bookSettingsManager`의 page 단계 롤백/입력 정리는 navigation 공통 정책이 아니라 화면 로컬 상태 전이다.
- 따라서 coordinator는 `proceed/cancel` 판정 결과만 소비하고, 단계 전이 구현은 View(`beforeBackAction`)에 둔다.

## Guardrails

1. 실행 순서
- 버튼 back: `beforeBackAction -> pop/popToRoot -> (step-pop이면) onStepPopExitAction`
- 스와이프 back: `path 감소 감지 -> (step-pop이면) onStepPopExitAction`

2. hook 사용 규칙
- `beforeBackAction`은 navigation 집행 여부(`proceed/cancel`) 판정 경계로 사용한다.
- navigation 후행 side effect는 `onStepPopExitAction`에만 둔다.
- 단, 화면 로컬 상태 전이(예: `bookSettingsManager` page 롤백)는 `beforeBackAction` 내부에서 처리할 수 있다.

3. 전이 범위
- `onStepPopExitAction`은 step-pop에서만 실행한다.
- `popToRoot`에서는 실행하지 않는다.

4. 동시성 규칙
- 동일 `routeInstanceID`에서 back in-flight 중복 트리거를 차단한다.

5. 제스처 규칙
- root host 단일 지점에서 `isEnabled`와 필요한 delegate 정책을 적용한다.
- 화면 파일/전역 extension에서 `interactivePopGestureRecognizer` 직접 제어를 금지한다.

## Planned interface changes

1. `Screens` 계약 변경
- 제거: `completionReviewUpdate(book: FGUserBook, popToRootOnBack: Bool)`
- 변경: `completionReviewUpdate(book: FGUserBook)`

2. Hook 계약
- `beforeBackAction: () async -> BackDecision`
- `onStepPopExitAction: () async -> Void`
- `BackDecision = proceed | cancel`

3. 식별자 계약
- route payload 외 별도 `routeInstanceID` 도입

## Screen policy scope for planned implementation

아래 정책은 다음 구현 단계에서 고정할 화면별 명세다.

1. `mainHome`
- back 버튼 없음
- gesture 비활성

2. `notiSetting`, `totalCalendar`, `dailyProgress`, `readingDateEdit`, `completionReview`
- `backMode = .pop`
- gesture 활성

3. `bookSettingsManager`
- 전 구간: gesture 비활성
- page1: `backMode = .pop`
- page2~5: `backMode = .none`, `beforeBackAction`으로 단계 롤백

4. `completionCelebration`
- `backMode = .popToRoot`
- gesture 비활성
- back 버튼 노출

5. `unfinishReading`
- `backMode = .pop`
- gesture 활성
- `onStepPopExitAction`으로 공통 후행 액션 실행

## Consequences

긍정적 결과:

- 화면 선언과 navigation 집행 경계가 분리된다.
- 버튼/스와이프 경로의 액션 일관성을 구조적으로 보장할 수 있다.
- 회귀 테스트 관찰점이 명확해진다.

비용/리스크:

- hook 수명주기와 식별자 관리 코드가 추가된다.
- 구현 초기에 테스트 보강이 필요하다.

## Revisit criteria

아래 조건이 발생하면 본 결정을 재검토한다.

1. step-pop 후행 액션이 화면 구조를 과도하게 복잡하게 만든다.
2. `routeInstanceID` 도입 이후에도 훅 오동작 케이스가 반복된다.
3. root host 단일 제어만으로 제스처 안정성 확보가 불충분하다는 실증 데이터가 나온다.

## References

- `docs/decisions/adr-0006-stack-back-path-only-policy.md`
- `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
- `FiveGuyes/FiveGuyes/Sources/Presentation/Shared/Navigation/NavigationInteractivePopHost.swift`
