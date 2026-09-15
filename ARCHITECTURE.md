# Architecture

## 개요

FiveGuyes는 SwiftUI 기반 iOS 앱이며, 현재 구조는 Feature 단위 MVVM과 UseCase 중심 도메인 경계를 따른다. 상세한 의사결정 기록은 `docs/decisions`의 ADR 문서를 기준으로 한다.

## 계층 구조

- `Presentation`: SwiftUI View, Component, ViewModel, Navigation 관련 상태를 담당한다.
- `Domain`: Entity, Policy, Calculator, UseCase, Repository/Service 인터페이스를 담당한다.
- `Data`: SwiftData, UserDefaults, Repository 구현체를 담당한다.
- `Platform`: 알림, 외부 도서 검색, 분석, 시스템 설정 같은 인프라 연동을 담당한다.
- `App`: 의존성 조립과 앱 진입점을 담당한다.

## Presentation 원칙

Presentation은 Feature 단위 MVVM을 사용한다. 상태 흐름은 `Action -> ViewModel -> State -> View` 방향을 따른다.

- View는 SwiftData, Repository, 계산기, UseCase를 직접 호출하지 않는다.
- View는 ViewModel의 상태를 렌더링하고 사용자 액션을 전달한다.
- ViewModel은 화면 상태와 UI 이벤트 처리를 담당한다.
- 화면 상태는 가능한 한 ViewModel의 단일 상태에서 파생한다.

## Domain 실행 경계

ViewModel은 필요한 UseCase 인터페이스를 직접 주입받아 호출한다. `Service`라는 이름은 알림, 시스템 설정, 외부 API, 시간 정책처럼 인프라 기능을 제공하는 객체에 사용한다.

- ViewModel은 Repository를 직접 호출하지 않는다.
- UseCase는 Domain 모델을 입출력으로 사용한다.
- UseCase가 외부 기능이 필요하면 `...Managing`, `...Scheduling`, `...Providing`, `...Storing` 형태의 Service 인터페이스를 주입받는다.
- `AppDependencies`는 조립 루트에서 UseCase와 구현체를 연결한다.

## Navigation 원칙

Navigation은 path 중심으로 관리한다. View는 back UI 선언과 back 전 판정 훅만 제공하고, 실제 이동 정책은 `NavigationCoordinator` 같은 navigation 계층이 집행한다.

- `beforeBackAction`은 진행 또는 취소 판정에만 사용한다.
- step-pop 이후 후행 액션은 별도 hook으로 분리한다.
- 제스처 제어는 root host 단일 지점에서 처리한다.

## 참고 ADR

- `docs/decisions/adr-0001-presentation-architecture.md`
- `docs/decisions/adr-0002-usecase-first-boundary.md`
- `docs/decisions/adr-0006-stack-back-path-only-policy.md`
- `docs/decisions/adr-0007-navigation-back-gesture-action-boundary.md`
