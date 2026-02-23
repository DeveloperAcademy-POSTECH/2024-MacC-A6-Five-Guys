# NavigationInteractivePopHost Stability Hardening (Delegate Non-Interference + Depth Gate)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/PLANS.md` and must be maintained in accordance with that file.

## Purpose / Big Picture

현재 사용자 체감 이슈는 edge-swipe back이 동작하더라도 간헐적으로 루트 홈이 살짝 밀렸다가 돌아오는 형태로 나타나는 것입니다. 이 변경의 목표는 스와이프 정책의 실제 적용 지점(`NavigationInteractivePopHost`)을 안정화해, 허용 화면에서는 swipe back이 예측 가능하게 동작하고 루트에서는 제스처가 시작조차 되지 않게 만드는 것입니다.

사용자는 이 변경 후 허용 화면(노티/오늘/전체/날짜수정 등)에서 edge-swipe back이 안정적으로 동작하고, 루트 홈에서는 밀림 없이 정지 상태를 확인할 수 있어야 합니다.

## Progress

- [x] (2026-02-20 16:36Z) `PLANS.md` 규칙 재확인 및 현재 구현 점검 완료.
- [x] (2026-02-20 16:38Z) 이슈 후보 수렴: `NavigationInteractivePopHost`에서 `interactivePopGestureRecognizer.delegate = nil` 상시 적용 확인.
- [x] (2026-02-20 16:40Z) `NavigationInteractivePopHost`를 delegate 비관여 방식으로 수정하고 depth AND 조건을 반영.
- [x] (2026-02-20 16:42Z) 정적 검증 완료: `interactivePopGestureRecognizer` 접근 1건(host), legacy 호출(backMode/swipeBackPolicy/no-op modifier) 0건.
- [x] (2026-02-20 17:01Z) 빌드/타깃 테스트 완료: `xcodebuild ... build` 및 `NavigationCoordinatorTests` 통과.
- [x] (2026-02-20 17:02Z) Outcomes 및 근거 로그 정리.

## Surprises & Discoveries

- Observation: 현재 root host 구현은 정책 적용 시마다 `interactivePopGestureRecognizer.delegate = nil`을 강제합니다.
  Evidence: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/Shared/Navigation/NavigationInteractivePopHost.swift:59`

- Observation: 중앙 정책(`isInteractivePopEnabled`)은 `paths`만 기준으로 계산되고 UIKit 실제 stack depth는 host에서 별도로 반영하지 않습니다.
  Evidence: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift:162`

- Observation: 빌드와 테스트를 병렬 실행하면 Xcode build DB lock으로 테스트가 실패할 수 있습니다.
  Evidence: `unable to attach DB ... build.db: database is locked` 오류가 병렬 실행 1회에서 재현되었고, 테스트 단독 재실행 시 성공했습니다.

## Decision Log

- Decision: 이번 사이클은 화면/코디네이터 계약은 유지하고, root host의 제스처 적용 로직만 수정한다.
  Rationale: 증상에 직접 연결되는 mutation 지점이 host 1곳이며, 변경 범위를 좁히는 것이 회귀 리스크가 가장 낮다.
  Date/Author: 2026-02-20 / Codex

- Decision: `interactivePopGestureRecognizer.delegate`는 더 이상 앱 코드에서 수정하지 않는다.
  Rationale: 현재 문서화된 방향(delegate 비관여)과 구현을 일치시키고, UIKit 기본 전환 가드를 우회하는 리스크를 줄이기 위함이다.
  Date/Author: 2026-02-20 / Codex

- Decision: 제스처 활성화는 `coordinator policy && navigation stack depth > 1`의 AND 조건으로 고정한다.
  Rationale: 라우팅 상태(`paths`)와 UIKit 실제 스택 상태 간의 전환 타이밍 차이를 흡수해 루트 시작 제스처를 구조적으로 차단할 수 있다.
  Date/Author: 2026-02-20 / Codex

## Outcomes & Retrospective

완료 결과:

- 구현 변경은 단일 파일(`NavigationInteractivePopHost.swift`)에 국한했습니다.
- `interactivePopGestureRecognizer.delegate` 변경 코드를 제거했고, 제스처 활성 조건은 `coordinator policy && UINavigationController depth > 1`로 고정했습니다.
- 정적 검증에서 제스처 접근은 host 1곳만 확인됐고, 화면 단 legacy 호출은 0건 상태를 유지했습니다.
- `xcodebuild ... build`와 `xcodebuild test ... -only-testing:NavigationCoordinatorTests`는 최종 통과했습니다.

남은 리스크:

- 실제 루트 홈 밀림 증상 완화 여부는 수동 반복 시나리오(사용자 검증)로 최종 판정해야 합니다.

## Context and Orientation

이 작업은 `NavigationStack`의 edge-swipe pop을 중앙 제어하는 host 하나를 다룹니다. 여기서 “host”는 SwiftUI 뷰 트리에 얇게 붙는 `UIViewControllerRepresentable` 브리지이며, `UINavigationController.interactivePopGestureRecognizer`의 `isEnabled`를 업데이트합니다.

핵심 파일:

- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/Shared/Navigation/NavigationInteractivePopHost.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
- `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/App/NavigationRootView.swift`

용어 정의:

- interactive pop gesture: iOS에서 왼쪽 edge-swipe로 이전 화면으로 돌아가는 시스템 제스처.
- stack depth: `UINavigationController.viewControllers.count` 값. depth가 1이면 루트 화면이다.

## Plan of Work

먼저 host에서 `delegate = nil` 코드를 제거합니다. 그 다음 정책 적용 함수를 `isInteractivePopEnabled` 단일 값이 아니라, 실제 `viewControllers.count > 1` 조건과 함께 계산하도록 바꿉니다. 이 변경으로 coordinator가 허용 정책을 내려도 루트 depth에서는 제스처를 시작하지 못하게 됩니다.

그 후 정적 검색으로 제스처 접근 지점이 여전히 host 단일 파일인지 확인하고, legacy 호출 제거 상태가 유지되는지 재검증합니다. 마지막으로 빌드와 `NavigationCoordinatorTests` 타깃 테스트를 실행해 회귀가 없는지 확인하고, 결과를 본 문서의 `Progress`/`Outcomes`에 반영합니다.

## Concrete Steps

작업 디렉터리: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 코드 수정
   - `NavigationInteractivePopHost.swift`에서 `delegate` 할당 제거
   - `isEnabled` 최종값을 `isInteractivePopEnabled && (viewControllers.count > 1)`로 변경

2. 정적 검증

   rg -n "interactivePopGestureRecognizer" FiveGuyes/FiveGuyes/Sources

   rg -n "customNavigationBackButton\\([^\\)]*(backMode:|swipeBackPolicy:)" FiveGuyes/FiveGuyes/Sources/Presentation/View

   rg -n "\\.(disableNavigationGesture|navigationSwipeBackPolicy)\\(" FiveGuyes/FiveGuyes/Sources/Presentation/View

3. 빌드/테스트 검증

   xcodebuild -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build

   xcodebuild test -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/Presentation/ViewModel/NavigationCoordinatorTests

4. 본 문서 업데이트
   - `Progress`, `Surprises & Discoveries`, `Outcomes & Retrospective`를 실행 결과로 갱신

## Validation and Acceptance

수용 기준:

1. `interactivePopGestureRecognizer.delegate`를 변경하는 코드가 host 구현에 남아있지 않다.
2. 제스처 활성 로직이 policy + depth AND 조건으로 적용된다.
3. `interactivePopGestureRecognizer` 접근 위치가 root host 1곳으로 유지된다.
4. 빌드 성공(`** BUILD SUCCEEDED **`) 및 타깃 테스트 성공(`** TEST SUCCEEDED **`).
5. 수동 검증 시 루트 홈에서 edge-swipe 시작(밀림) 재현 빈도가 감소한다.

## Idempotence and Recovery

이번 변경은 단일 파일 국소 수정이라 반복 적용해도 동일 상태가 됩니다. 검증 실패 시 `NavigationInteractivePopHost.swift` 한 파일만 롤백해 즉시 이전 동작으로 복구할 수 있습니다. 문서는 사실 기록만 추가하므로 기능 영향이 없습니다.

## Artifacts and Notes

정적 검색 결과:

- `rg -n "interactivePopGestureRecognizer|delegate\\s*=\\s*nil" FiveGuyes/FiveGuyes/Sources`
  - 결과: `NavigationInteractivePopHost.swift` 1건, `delegate = nil` 0건
- `rg -n "customNavigationBackButton\\([^\\)]*(backMode:|swipeBackPolicy:)" FiveGuyes/FiveGuyes/Sources/Presentation/View`
  - 결과: 0건
- `rg -n "\\.(disableNavigationGesture|navigationSwipeBackPolicy)\\(" FiveGuyes/FiveGuyes/Sources/Presentation/View`
  - 결과: 0건

빌드/테스트 핵심 로그:

- `** BUILD SUCCEEDED **`
- `** TEST SUCCEEDED **`
- 병렬 실행 1회 실패 로그: `unable to attach DB ... build.db: database is locked` (단독 재실행으로 해결)

## Interfaces and Dependencies

외부 인터페이스는 변경하지 않습니다.

- 유지: `BackSwipePolicy`, `NavigationCoordinator.effectiveTopPolicy`, `NavigationCoordinator.isInteractivePopEnabled`, `customNavigationBackButton(...)`
- 변경: `NavigationInteractivePopHost` 내부 적용 로직만 수정
- 의존성 추가 없음

Plan revision note (2026-02-20): 신규 작성. root 홈 밀림 증상을 줄이기 위해 host 단일 파일의 delegate 비관여 + depth gate 강화 범위로 작업을 제한했다.
Plan revision note (2026-02-20): 구현 후 문서를 실행 결과 기준으로 갱신했다(정적 검증 수치, build/test 통과, 병렬 실행 DB lock 발견 및 재실행 처리).
