# ADR-0006: Stack Back Path-Only Policy

- Status: Accepted
- Date: 2026-02-18
- Last Updated: 2026-02-20
- Owners: FiveGuyes team

## Decision

`NavigationStack` 기반 화면의 back 이동은 `NavigationCoordinator` 경로 명령(`pop`, `popToRoot`)으로만 처리한다.

`dismiss`는 modal presentation(`sheet`, `fullScreenCover`, `popover`) 전용으로 사용한다.
즉, shared stack back 컴포넌트(`CustomBackButton`)에서는 `dismiss`를 호출하지 않는다.

추가로, 빠른 연속 탭으로 같은 화면이 중복 적재되지 않도록 `NavigationCoordinator.push`는 기본적으로 동일 route 연속 push를 차단한다.
필요한 경우에만 `allowDuplicateRoute: true`로 opt-in 한다.

swipe back 제스처 정책은 화면별 UIKit 제어 대신 `NavigationCoordinator` 계산값으로 중앙화한다.
즉, `Screens.defaultBackPolicy`를 기준으로 `effectiveTopPolicy`를 계산하고,
`NavigationRootView`에 단일 attach된 `NavigationInteractivePopHost`에서만 `interactivePopGestureRecognizer` 상태를 적용한다.
화면 파일에서는 `interactivePopGestureRecognizer`를 직접 제어하지 않는다.

## Context

이전 구현은 shared back에서 action 실행 후 `dismiss`를 항상 호출했다.
일부 화면은 action에서 `popToRoot`도 수행했기 때문에 back 탭 한 번에 `popToRoot + dismiss`가 연속 실행될 수 있었다.
현재 루트 stack에서는 항상 재현되지 않지만, 재사용 컨테이너/탭 타이밍에 따라 간헐적인 이중 이동으로 보이는 리스크가 있었다.

또한 push는 호출부별로 직접 실행되어 더블 탭 시 동일 화면 중복 적재 가능성이 남아 있었다.

2026-02-19~2026-02-20 점검에서 swipe back 보조 구현이 화면별로 분산 적용되면, 정책 누수/적용 타이밍 차이로 간헐 증상 분석이 어려워진다는 점을 확인했다.
특히 route별 금지/허용 정책과 뷰 생명주기 기반 UIKit 접근이 섞이면 회귀 원인 추적이 복잡해진다.

## 2026-02-19 Revision: Swipe Back Policy Simplification

초기 접근은 “delegate 캡처/복원 + isEnabled 제어”였다.
이 접근의 목적은 화면 전환 사이클에서 원래 상태를 보존하려는 방어였다.

이번 개정에서는 swipe back 정책을 `isEnabled` 전용으로 단순화했다.
즉, `.systemDefault`는 stack depth 기반 허용, `.disabled`는 강제 차단만 수행하고 delegate에는 관여하지 않는다.

이유는 다음과 같다.

- `interactivePopGestureRecognizer`는 `UINavigationController` 소유 프로퍼티로 stack 화면이 공유하는 제스처 상태다.
- `UIGestureRecognizer.delegate`는 인식 시작 판정에 직접 관여한다.
- 이번 요구사항(허용/차단)은 `isEnabled`만으로 충분히 충족된다.

따라서 delegate 관여를 제거하는 편이 구현 단순성, 정책 가독성, 회귀 분석 용이성에서 더 안전하다고 판단했다.

## 2026-02-20 Revision: Root-Central Route + Fixed Screen Policy

초기 개선 이후에도 간헐 증상 분석 비용이 컸기 때문에, swipe 정책 적용 지점을 root 단일 host로 중앙화했다.

최종 구조는 다음과 같다.

- route 기본 정책: `Screens.defaultBackPolicy`
- 기본 back 정책 상수: `NavigationBackPolicy.standard` (`pop + systemDefault + showsBackButton=true`)
- 최종 정책: `NavigationCoordinator.effectiveTopPolicy` (top route 기본 정책)
- 적용 지점: `NavigationInteractivePopHost`(root 1곳)

추가로 custom back UI는 유지하되, 버튼 동작은 화면 파라미터가 아니라 `effectiveTopPolicy.backMode`를 읽어 수행한다.
따라서 화면별 `swipeBackPolicy`/UIKit 직접 제어 없이도 금지/허용 정책을 일관되게 적용할 수 있다.

## 2026-02-20 Revision: Stage-2 Compatibility Cleanup

중앙화 이후 호출부 호환 잔재를 줄이기 위해 다음을 반영했다.

- `customNavigationBackButton(action:backMode:swipeBackPolicy:)` 오버로드를 제거하고, `customNavigationBackButton(routeKey:beforeBackAction:onStepPopExitAction:)` 단일 API(모든 인자 optional)로 정리했다.
- 화면 호출부는 기본 경로에서 `customNavigationBackButton()`을 사용하고, 특수 back 훅이 필요한 화면만 `routeKey`/hook 인자를 전달한다.
- `disableNavigationGesture()`/`navigationSwipeBackPolicy(_:)` 호환 레이어와 관련 파일을 제거하고, 호출부는 `customNavigationBackButton` + root host(`navigationRootBackHost()`) 기준으로 정리했다.
- `NavigationRootView`는 루트 전용 모디파이어(`navigationRootBackHost()`)로 host 부착 의도를 명시한다.
- `NavigationCoordinatorTests`에 route 기본 정책, `bookSettingsManager` 고정 swipe 비활성, `isInteractivePopEnabled` 경계 테스트를 추가했다.

목표는 API 단절 없이 오해를 줄이고, 중앙 정책 회귀를 테스트로 고정하는 것이다.

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

- `NavigationCoordinator.paths`는 typed path(`[NavigationPathItem]`)를 사용한다.
- `NavigationCoordinator.push(_:allowDuplicateRoute:)` 기본값은 `allowDuplicateRoute = false`다.
- `Screens.routeKey`는 payload와 무관한 route 타입 식별자로 사용한다.
- `Screens.defaultBackPolicy`는 `NavigationBackPolicy.standard`를 기본값으로 사용하고, 예외 route만 별도 정책을 선언한다.
- `bookSettingsManager`는 기본 정책에서 swipe를 비활성화하고, page2~5의 단계 롤백은 `beforeBackAction`으로 처리한다.
- `customNavigationBackButton(routeKey:beforeBackAction:onStepPopExitAction:)`는 `CustomBackButton`을 통해 `NavigationCoordinator.effectiveTopPolicy.backMode` 기준으로 stack back 동작을 제어하며, 필요 시 화면별 hook(`beforeBackAction`/`onStepPopExitAction`)을 연결한다.
- `NavigationRootView`는 `navigationRootBackHost()`로 root host를 부착한다.
- `interactivePopGestureRecognizer` 접근은 `NavigationInteractivePopHost`로 제한하고, 화면별 UIKit 제어 코드는 두지 않는다.
- modal dismiss가 필요한 경우, modal 전용 뷰/버튼에서만 `@Environment(\\.dismiss)`를 사용한다.

## Consequences

긍정적 결과:
- back 동작 예측 가능성이 높아지고 간헐적 이중 이동 리스크가 줄어든다.
- 더블 탭 중복 화면 적재가 coordinator 경계에서 일괄 차단된다.
- 네비게이션 규칙이 문서/코드/테스트에서 동일 의미로 정렬된다.
- swipe 정책 구현 복잡도와 분석 지점(delegate 캡처/복원)이 줄어든다.

비용/리스크:
- 기존에 route 타입 중복 적재를 암묵적으로 허용하던 시나리오는 명시적 opt-in이 필요하다.
- stack과 modal을 동시에 다루는 신규 플로우에서는 경계 선택을 설계 단계에서 명확히 해야 한다.

## References

- WWDC22: The SwiftUI cookbook for navigation  
  <https://developer.apple.com/videos/play/wwdc2022/10054/>
- SwiftUI `dismiss` environment value  
  <https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss>
- SwiftUI `navigationBarBackButtonHidden(_:)`  
  <https://developer.apple.com/documentation/swiftui/view/navigationbarbackbuttonhidden(_:)>  
- UIKit `interactivePopGestureRecognizer`  
  <https://developer.apple.com/documentation/uikit/uinavigationcontroller/interactivepopgesturerecognizer?language=objc>
- Apple sample: Food Truck  
  <https://github.com/apple/sample-food-truck>
