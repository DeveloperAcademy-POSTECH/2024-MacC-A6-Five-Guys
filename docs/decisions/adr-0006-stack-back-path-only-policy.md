# ADR-0006: Stack Back Path-Only Policy

- Status: Accepted
- Date: 2026-02-18
- Owners: FiveGuyes team

## Decision

`NavigationStack` 기반 화면의 back 이동은 `NavigationCoordinator` 경로 명령(`pop`, `popToRoot`)으로만 처리한다.

`dismiss`는 modal presentation(`sheet`, `fullScreenCover`, `popover`) 전용으로 사용한다.
즉, shared stack back 컴포넌트(`CustomBackButton`)에서는 `dismiss`를 호출하지 않는다.

추가로, 빠른 연속 탭으로 같은 화면이 중복 적재되지 않도록 `NavigationCoordinator.push`는 기본적으로 동일 route 연속 push를 차단한다.
필요한 경우에만 `allowDuplicateRoute: true`로 opt-in 한다.

## Context

이전 구현은 shared back에서 action 실행 후 `dismiss`를 항상 호출했다.
일부 화면은 action에서 `popToRoot`도 수행했기 때문에 back 탭 한 번에 `popToRoot + dismiss`가 연속 실행될 수 있었다.
현재 루트 stack에서는 항상 재현되지 않지만, 재사용 컨테이너/탭 타이밍에 따라 간헐적인 이중 이동으로 보이는 리스크가 있었다.

또한 push는 호출부별로 직접 실행되어 더블 탭 시 동일 화면 중복 적재 가능성이 남아 있었다.

## Options considered

### Option A: Stack back을 path-only로 통일 + Coordinator 중복 push 가드 (선택)

- 장점:
  - 이동 책임이 명확해진다(`stack = path`, `modal = dismiss`).
  - back 동작이 컨테이너 재사용 여부와 무관하게 결정적이다.
  - 더블 탭 방지 로직을 호출부가 아닌 라우팅 경계에서 일관 적용할 수 있다.
- 단점:
  - 기존 shared back API 일부가 변경된다.
  - route 타입 단위 차단이라 같은 화면 타입의 연속 적재가 기본적으로 막힌다(필요 시 opt-in 필요).

### Option B: dismiss 정책 enum을 shared back에 유지

- 장점:
  - 호출부에서 선택적으로 제어 가능하다.
- 미선택 이유:
  - stack back 컴포넌트에 modal 책임이 남아 정책 분기가 계속 증가한다.
  - 호출부 실수로 `pop + dismiss` 재혼용 리스크가 남는다.

### Option C: 화면별 중복 탭 방지(disabled/throttle)만 적용

- 장점:
  - UI 단에서 빠르게 적용 가능하다.
- 미선택 이유:
  - 모든 push 지점에 반복 적용해야 하고 누락 가능성이 높다.
  - 라우팅 정책이 view 계층으로 퍼져 일관성이 떨어진다.

## Rationale

Apple SwiftUI navigation 가이드는 stack 이동을 path/state로 다루는 패턴을 제시한다.
`dismiss`는 현재 presentation을 닫는 동작으로 정의되어 stack path 조작과 책임이 다르다.
따라서 stack back은 path-only로, modal close는 dismiss로 분리하는 것이 프레임워크 모델과 가장 일치한다.

## Guardrails

- `NavigationCoordinator.paths`는 typed path(`[Screens]`)를 사용한다.
- `NavigationCoordinator.push(_:allowDuplicateRoute:)` 기본값은 `allowDuplicateRoute = false`다.
- `Screens.routeKey`는 payload와 무관한 route 타입 식별자로 사용한다.
- `CustomBackButton` 기본 동작은 `coordinator.pop()`이며, 특수 화면은 `backBehavior = .none` + custom action 조합으로 제어한다.
- modal dismiss가 필요한 경우, modal 전용 뷰/버튼에서만 `@Environment(\\.dismiss)`를 사용한다.

## Consequences

긍정적 결과:
- back 동작 예측 가능성이 높아지고 간헐적 이중 이동 리스크가 줄어든다.
- 더블 탭 중복 화면 적재가 coordinator 경계에서 일괄 차단된다.
- 네비게이션 규칙이 문서/코드/테스트에서 동일 의미로 정렬된다.

비용/리스크:
- 기존에 route 타입 중복 적재를 암묵적으로 허용하던 시나리오는 명시적 opt-in이 필요하다.
- stack과 modal을 동시에 다루는 신규 플로우에서는 경계 선택을 설계 단계에서 명확히 해야 한다.

## References

- WWDC22: The SwiftUI cookbook for navigation  
  <https://developer.apple.com/videos/play/wwdc2022/10054/>
- SwiftUI `dismiss` environment value  
  <https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss>
- Apple sample: Food Truck  
  <https://github.com/apple/sample-food-truck>
