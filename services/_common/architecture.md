# Architecture

> 기준일: 2026-10-07 (규칙을 바꾸면 함께 고친다)
>
> 새 코드를 어느 layer에 두고 무엇에 의존할지 정하는 목표 구조 문서다. 코드가 이 문서와 다르면 코드를 고칠 대상으로 보고 [backlog](../../history/backlog.md)에 추가한다.

## Overall Architecture

- **Feature 단위 MVVM + Clean Architecture**를 따른다. ([ADR-0001](../../history/decisions/adr-0001-presentation-architecture.md))

| 영역 | 기술 |
|---|---|
| 플랫폼 | iOS 17+, Swift (language mode 5) |
| UI | SwiftUI, Observation(`@Observable`) |
| 저장 | SwiftData, UserDefaults |
| 외부 연동 | UserNotifications(로컬 알림), FGNetwork 패키지의 URLSession(카카오 책 검색, 국립중앙도서관 ISBN 서지정보), Firebase Analytics, AppTrackingTransparency |
| 테스트·품질 | Swift Testing, SwiftLint(`scripts/verify.sh`·CI·pre-push) |

```text
┌─ Presentation (MVVM) ────────────────────────────────────────┐
│  ┌──────┐     ┌───────────┐                                  │
│  │ View │ ──> │ ViewModel │                                  │
│  └──────┘     └─────┬─────┘                                  │
└─────────────────────┼────────────────────────────────────────┘
                      v
┌─ Domain ────────────┼────────────────────────────────────────┐
│               ┌─────┴────┐    ┌────────────┐    ┌─────────┐  │
│               │ ...Using │<|──│ ...UseCase │──> │...Repo /│  │
│               │          │    │            │    │ Service │  │
│               └──────────┘    └────────────┘    └────┬────┘  │
└──────────────────────────────────────────────────────┼───────┘
                                                       ^
┌─ Data · Platform ────────────────────────────────────┼───────┐
│                                                 ┌────┴────┐  │
│                                                 │  Impl   │  │
│                                                 └─────────┘  │
└──────────────────────────────────────────────────────────────┘

┌─ App ────────────────────────────────────────────────────────┐
│  AppDependencies: build Impl, bind it to interface           │
└──────────────────────────────────────────────────────────────┘

──>  depends on      <|── / ^  implements
```

| 용어 | 정의 | interface (Domain) | 구현 (Impl) |
|---|---|---|---|
| View | 상태를 그리고 사용자 의도를 ViewModel 메서드로 전달한다 | — | Presentation |
| ViewModel | 의도를 처리해 상태를 바꾸고, 필요한 기능은 UseCase에 요청한다 | — | Presentation |
| UseCase | ViewModel이 요청하는 기능 단위. 앱 규칙을 실행하고 Repository·Service를 조합한다 | `...Using` | `...UseCase` (Domain). 구현 안에서만 쓰는 단일 동작 UseCase는 interface 없이 `...UseCase`로 둔다 |
| Repository | 영속 데이터 접근 | `...Repo` | Data |
| Service | UseCase가 쓰는 Repository 외 기능. 도메인 로직(오늘 날짜, 하루 경계 등)과 외부 연동(알림, 도서 검색 등)을 제공한다 | `...ing` (`...Providing`, `...Scheduling` 등) | Platform, Data(저장), Domain(Foundation 값 타입만 쓰는 구현) |

### Clean Architecture

#### Layer Composition

| layer | 역할 | 배치하는 코드 |
|---|---|---|
| App | 앱을 시작하고 모든 layer를 조립한다 | entry point, 의존성 조립, 화면 조립, 내비게이션 루트 |
| Presentation | 화면을 그리고 사용자 입력을 처리한다 | View·ViewModel, Component, 내비게이션 상태 |
| Domain | 앱 규칙과 기능을 정의하고, 바깥에 필요한 기능을 interface로 요구한다 | Entity, Policy, Calculator, UseCase, Repository·Service interface, Foundation 값 타입만 쓰는 Service 구현 |
| Data | 기기에 데이터를 저장하고 읽는다 | 영속 저장 모델, 키-값 저장소, Repository 구현 |
| Platform | OS와 외부 서비스에 연결한다 | OS 기능 연동(알림, 시스템 설정), 외부 서비스 연동(도서 검색, 분석) |
| Shared | 모든 layer가 쓰는 공통 도구를 둔다 | 공통 Foundation 확장 |

#### Dependency Direction

```text
        ┌──> Presentation ──┐
        │                   │
App ────┼──> Data ──────────┼──> Domain
        │                   │
        └──> Platform ──────┘

App ──> Domain   (구현체 조립)
모든 layer ──> Shared
```

- 다이어그램에 없는 방향의 참조는 허용하지 않는다.
- layer를 넘어 기능(UseCase, Repository, Service)에 의존할 때는 Domain의 protocol을 거친다. Entity와 값 타입은 직접 참조한다.
- 구체 타입을 알고 생성·연결하는 곳은 조립 코드(App, `Presentation/Preview/`)뿐이다. `Presentation/Preview/`는 이를 위해 Data·Platform을 참조할 수 있다.
- Data·Platform의 외부 표현 타입(저장 모델, API DTO)은 그 layer 밖으로 노출하지 않는다. 구현이 Entity로 바꿔 넘긴다.
- 앱은 단일 모듈로 구성하며 lint custom rule이 경계 일부를 error로 검사한다.
- 테스트 전용 대역은 테스트 타깃에 둔다.

## Layer Rules

### App

```text
┌──────────────┐                  ┌─────────────────┐
│ FiveGuyesApp │ creates ───────> │ AppDependencies │
└───────┬──────┘                  └────────┬────────┘
        │ creates                          │ passed to
        v                                  v
┌────────────────────┐             ┌───────────────┐             ┌──────────────────┐
│ NavigationRootView │ creates ──> │ ScreenFactory │ creates ──> │ View + ViewModel │
└──────────┬─────────┘             └───────────────┘             └──────────────────┘
           │ creates, provides to View via environment
           v
┌───────────────────────┐
│ NavigationCoordinator │
└───────────────────────┘
```

| 컴포넌트 | 역할 |
|---|---|
| `FiveGuyesApp` | 앱 entry point. 저장소를 초기화하고 `AppDependencies`를 만든다 |
| `AppDependencies` | Repository·Service·UseCase 구현체를 만들고 interface에 연결한다 |
| `ScreenFactory` | route에 맞는 View와 ViewModel을 만들고 `...Using`을 주입한다 |
| `NavigationRootView` | `ScreenFactory`와 `NavigationCoordinator`를 만들고, `NavigationStack`의 경로와 화면을 연결한다. `NavigationCoordinator`를 environment로 View에 제공한다 |
| `NavigationCoordinator` | 화면 이동 상태를 관리한다. Presentation에 속한다 |

- `AppDependencies`가 `...Using` 구현이 사용하는 내부 UseCase까지 조립한다. 내부 UseCase는 ViewModel에 노출하지 않는다.

### Presentation

```text
┌──────┐   intent method   ┌───────────┐ ──> ...Using
│ View │ ────────────────> │ ViewModel │
│      │ <──────────────── │           │
└──────┘   state property  └───────────┘
```

| 방향 | 규칙 |
|---|---|
| View → ViewModel | 사용자 의도를 ViewModel의 메서드 호출로 전달한다 |
| ViewModel → View | 화면에 그릴 결과는 상태 프로퍼티로 드러낸다 |
| 일회성 결과 | 알럿·토스트 같은 일회성 결과도 optional 상태로 드러낸다 |
| 화면 이동 | View가 `NavigationCoordinator`에 요청하고, coordinator가 이동을 집행한다. 이동 여부나 행선지에 판단이 필요하면 ViewModel이 메서드 반환값(성공 여부, 행선지 enum)으로 돌려준다 |

```swift
func deleteTapped(id: UUID) async       // View → ViewModel: 의도 = 메서드
private(set) var books: [Book]          // ViewModel → View: 상태
var alert: AlertKind?                   // 일회성 결과: optional 상태
func submit() async -> Destination?     // 화면 이동: 판단 결과만 반환
```

- ViewModel은 `...Using`만 주입받는다. View는 `...Using`을 참조하지 않는다. ([ADR-0002](../../history/decisions/adr-0002-usecase-first-boundary.md))
- ViewModel을 두는 화면은 route마다 하나 둔다. 여러 단계로 된 화면은 단계마다 둘 수 있다.
- route 타입(`Screens`, `NavigationPathItem`)은 Presentation에 둔다.
- `NavigationCoordinator`는 화면 이동 상태만 관리하고 의존성을 갖지 않는다. View는 environment로 받고, ViewModel은 모른다. ([ADR-0006](../../history/decisions/adr-0006-stack-back-path-only-policy.md), [ADR-0007](../../history/decisions/adr-0007-navigation-back-gesture-action-boundary.md))
- 여러 Preview가 함께 쓰는 조립·대역·샘플 데이터는 `Presentation/Preview/`에 둔다.

### Domain

- Foundation의 값 타입과 계산(`Date`, `Calendar`, `UUID` 등)만 쓴다. Foundation 외 프레임워크(`os` 포함)는 import하지 않는다.
- 저장·네트워크·앱 환경 API(`UserDefaults`, `URLSession`, `FileManager`, `Bundle` 등)는 Repository나 Service로 요구한다. 이 API를 쓰는 구현은 Data·Platform에 둔다.

### Platform

- OS 기능과 외부 서비스에 연결하는 구현을 둔다. 외부 서비스 연동은 `Platform/<연동>/<출처>/`로 나누고, 출처가 주는 형식(날짜 문자열, 식별자 묶음 등)의 해석은 그 폴더 안에서 끝낸다. Domain 엔티티에는 해석된 값만 넘긴다.
- 여러 연동이 함께 쓰는 공통 코드(HTTP 호출, API 키 읽기)는 아래 로컬 패키지에 둔다. Platform 안에 중복으로 만들지 않는다.

### Local Packages

앱 타입을 몰라도 되는 공통 기반은 `FiveGuyes/Packages/<이름>/`에 로컬 Swift Package로 둔다.

| 규칙 | 내용 |
|---|---|
| 의존 방향 | 패키지는 앱 코드와 다른 패키지를 import하지 않는다. 앱의 조립 코드(App)와 Platform·Data만 패키지를 import한다. `Presentation/Preview/`는 조립 코드로 보아 예외다. Domain·Presentation·Shared는 패키지를 모른다 |
| 언어 모드 | `swiftLanguageModes: [.v6]`. 공개 타입은 `Sendable`이고 전역 가변 상태를 두지 않는다. 앱 타깃의 Swift 6 전환은 패키지 분리가 끝난 뒤 별도로 정한다 |
| 테스트 | 패키지 안의 테스트 타깃에 Swift Testing으로 쓰고, `scripts/verify.sh`의 '패키지 테스트' 단계가 패키지 스킴으로 실행한다 |
| 문서 | 패키지의 공개 API와 규칙은 `services/<서비스>/`에 둔다. 패키지 폴더 안에는 코드만 둔다 |

현재 패키지: `FGNetwork` (`services/network/module.md`).
