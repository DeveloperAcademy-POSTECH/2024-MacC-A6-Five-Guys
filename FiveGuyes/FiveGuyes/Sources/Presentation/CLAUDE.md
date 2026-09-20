# Presentation

Feature 단위 MVVM. 상태 흐름은 `Action -> ViewModel -> State -> View`입니다.
배경은 `ARCHITECTURE.md`와 `docs/decisions/adr-0001-presentation-architecture.md`를 참고하세요.

## 디렉터리

- `View/` — 화면 단위. 기능별 하위 폴더(`Main`, `BookSetting`, `BookCompletion`, `ReadingCalendar` 등)
- `ViewModel/` — 화면 상태와 UI 이벤트 처리
- `Component/` — 재사용 UI 조각
- `Shared/` — `Navigation`, `Calendar`, `Typography`, `Extensions`
- `Preview/` — 프리뷰 전용 지원 코드

## ViewModel 작성 규약

`@Observable final class` + 필요 시 `@MainActor`가 기본형입니다. `@Published`는 신규 코드에서 쓰지 마세요(구 코드 3곳에만 남아 있음).

필요한 UseCase 인터페이스(`...Using`)를 이니셜라이저로 직접 주입받습니다. Repository를 직접 호출하지 않습니다.

## SwiftLint가 error로 막는 것

빌드 시 자동 검사되므로 위반하면 빌드가 깨집니다.

- ViewModel이 `...Managing` / `...Providing` / `...Storing` / `...Opening`을 직접 의존
- View가 `any ...Using`을 직접 참조
- View가 `@Environment(AppDependencies.self)`를 사용

## Navigation

경로는 `NavigationCoordinator.paths` 단일 소스에서 관리합니다. View는 back UI 선언과 판정 훅만 제공하고, 이동 정책 집행은 coordinator가 합니다.

- `setTopBackHooks(owner:routeKey:beforeBackAction:onStepPopExitAction:)`으로 훅을 등록합니다. 훅은 top route 인스턴스에 바인딩되어 stale 훅이 실행되지 않습니다.
- `beforeBackAction`은 `BackDecision.proceed` / `.cancel` 판정에만 씁니다. 여기서 화면 이동이나 후처리를 하지 마세요.
- pop 이후 후행 액션은 `onStepPopExitAction`으로 분리합니다.
- 제스처 허용 여부는 `isInteractivePopEnabled`가 계산하며 root host 한 곳에서만 처리합니다.

back 동작을 바꾸기 전에 `docs/decisions/adr-0006-stack-back-path-only-policy.md`와 `adr-0007-navigation-back-gesture-action-boundary.md`를 읽으세요.

## 테스트

`FiveGuyesTests/Presentation/`에 대응 테스트를 둡니다. Swift Testing 사용법과 대역 네이밍은 루트 `CLAUDE.md`를 따르세요.
