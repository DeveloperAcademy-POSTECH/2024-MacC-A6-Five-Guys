# ADR-0002: UseCase-First Boundary and Service Terminology

- Status: Accepted (Implemented in production path)
- Date: 2026-02-14
- Owners: FiveGuyes team

## Decision

Presentation 계층(ViewModel)은 도메인 실행 경계를 `BookManagementService` 같은 파사드가 아니라,
필요한 `UseCase`를 직접 주입받아 호출한다.

동시에 용어 규칙을 다음처럼 고정한다.

- `UseCase`: 도메인 규칙 실행 단위 (예: 책 등록, 독서 기록, 목표 기간 수정)
- `Service`: 인프라 기능 제공자 (예: 알림, 시스템 설정, 외부 API, 시계/시간 정책)

즉, ViewModel은 UseCase를 호출하고, UseCase 내부에서 Repository/Infrastructure Service를 조합한다.

## Context

결정 당시 구조는 `BookManagementService`가 ViewModel의 단일 진입점이고 내부에서 UseCase로 위임하는 형태였다.
이 방식은 점진 전환에는 유리했지만, 다음 문제가 남는다.

- ViewModel이 실제로 필요한 실행 단위보다 더 넓은 인터페이스를 의존한다.
- `service` 용어가 "도메인 실행 파사드"와 "인프라 제공자" 두 의미로 혼용된다.
- 화면 단위 테스트에서 필요한 실행 단위를 더 명확하게 조립하기 어렵다.

## Options considered

### Option A: ViewModel -> UseCase 직접 의존 (선택)

- 장점:
  - 화면이 필요한 도메인 실행 단위만 참조해 의존성이 축소된다.
  - 용어가 명확해진다 (`UseCase` vs `Service`).
  - 테스트에서 화면별 필요한 유스케이스만 목킹하면 되어 설정이 단순해진다.
- 단점:
  - 초기 전환 시 DI 조립 코드가 늘어난다.
  - UseCase 인터페이스 정리가 필요하다.

### Option B: ViewModel -> BookManagementService 파사드 유지

- 장점:
  - 변경 범위가 작고 점진 이행이 쉽다.
- 미선택 이유:
  - 의존성 단위가 과도하게 넓고 용어 혼용이 계속된다.

### Option C: 혼합 유지 (일부 화면만 UseCase 직접 호출)

- 장점:
  - 단기 이행이 빠르다.
- 미선택 이유:
  - 경계 규칙이 이중화되어 장기 유지보수에서 오히려 복잡성이 증가한다.

## Rationale

이번 결정은 "도메인 실행 경계와 인프라 제공 경계를 의미적으로 분리"하기 위한 것이다.
`UseCase`를 화면 실행 단위로 올리고, `Service`는 플랫폼/외부 기능 제공자로 제한하면
아키텍처 문서, 코드 네이밍, 테스트 경계가 같은 의미를 갖게 된다.

## Guardrails

- ViewModel은 Repository를 직접 호출하지 않는다.
- ViewModel은 UseCase 인터페이스만 호출한다.
- UseCase는 Domain 모델만 입출력으로 사용한다.
- UseCase가 필요한 외부 기능은 `...Managing`, `...Scheduling`, `...Providing` 같은 Service 인터페이스를 통해 주입받는다.
- `BookManagementService`는 운영 경로에서는 사용하지 않고, Preview/Test 호환 어댑터로만 유지한다.

## Consequences

긍정적 결과:
- 화면 의존성이 축소되고 기능 단위 테스트/리뷰가 쉬워진다.
- `Service` 용어가 인프라 객체로 수렴되어 의사소통 비용이 줄어든다.
- UseCase 중심으로 기능 확장 시 변경 지점을 예측하기 쉬워진다.

비용/리스크:
- 초기에 DI 조립 코드와 프로토콜 수가 증가한다.
- ViewModel 생성부(`NavigationCoordinator`, `BookSettingsManagerView`, Preview)를 일괄 조정해야 한다.

## Migration policy

1. UseCase 인터페이스를 명시하고 AppDependencies에서 조립한다.
2. ViewModel을 화면별로 `BookManagementService` -> 필요한 UseCase로 교체한다.
3. 테스트를 화면 단위로 전환한다.
4. 모든 화면 전환이 완료되면 `BookManagementService`를 삭제하거나 완전한 하위 호환 계층으로 격리한다.

## Implementation status (2026-02-16)

- 완료: `AppDependencies`가 feature-composed UseCase(`ReadingLibraryUsing`, `DailyReadingUsing`, `BookCompletionUsing`, `ReadingPlanUsing`, `BookRegistrationUsing`)를 조립한다.
- 완료: 대상 ViewModel(`MainHome`, `DailyProgress`, `CompletionReview`, `ReadingDateEdit`, `UnfinishReading`, `FinishGoal`)이 UseCase 인터페이스를 직접 주입받는다.
- 완료: UseCase의 알림 의존은 concrete `NotificationManager` 대신 `ReadingNotificationScheduling` 프로토콜로 분리되었다.
- 완료: 운영 `App`/`Presentation/ViewModel` 경로의 `BookManagementService` 의존은 제거되었고, Preview/Test 어댑터 프로토콜로만 유지된다.
- 완료: 런타임 미사용 중복 계층이던 `DefaultBookManagementService` 구현체를 제거했다.
- 완료: action-level `...Using` 프로토콜은 제거하고, Presentation 경계에는 feature-level UseCase 프로토콜만 유지해 과분리를 완화했다.
- 완료: 테스트 기준도 UseCase 중심으로 전환해 `BookManagementUseCasesTests`가 등록/기록/완독/계획변경 핵심 시나리오를 검증한다.
- 완료: `MainHomeViewModel`은 인프라(`NotificationManaging`) 직접 의존 없이 `ReadingLibraryUsing.setupNotifications(for:)`를 통해 알림 트리거를 실행한다.
- 완료: `BookSearchViewModel`은 인프라 프로토콜(`BookSearching`) 대신 UseCase 경계(`BookSearchUsing`)를 주입받고, 인프라 연동은 `BookSearchUseCase` 내부로 캡슐화되었다.
- 완료: 알림 관련 의존 변수명은 `notificationService`로 통일해 `Service` 용어 규칙을 코드 레벨에서 일치시켰다(타입명 `NotificationManager`는 유지).
- 완료: `BookManagementUseCases.swift` 단일 파일을 기능군 3파일(`Library+Registration`, `Daily+Plan`, `Completion`)로 분리해 feature-level UseCase 경계를 유지하면서 파일 책임을 분명히 했다.
