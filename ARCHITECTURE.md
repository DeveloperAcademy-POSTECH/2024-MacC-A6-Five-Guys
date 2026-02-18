# FiveGuyes Architecture

문서 메타:
- 문서 버전: `2026.02.18+e9084df`
- 프로덕트 기준 버전: `2026.02.18+e9084df (develop HEAD)`
- 최종 갱신일: `2026-02-18`

이 문서는 자주 기여하는 개발자와 리뷰어를 위한 **안정적인 아키텍처 지도**입니다.

## 1) Bird's-eye view

FiveGuyes는 사용자의 책/목표일/목표페이지를 입력받아, 매일 읽을 목표와 실제 독서 기록을 관리하는 SwiftUI + SwiftData iOS 앱입니다.
핵심 동작은 "독서 상태 입력 -> 스케줄 재계산 -> 저장/알림 갱신"의 반복입니다.

입력(ground state):
- 사용자 책 데이터(메타데이터, 설정, 진행상태, 완독상태)
- 사용자 액션(책 등록, 오늘 페이지 기록, 목표일 수정, 완독 소감)
- 알림 설정(UserDefaults + 시스템 권한)

출력(derived state):
- 일별 누적 목표(`dailyReadingRecords`)
- 화면별 표시 상태(홈, 캘린더, 완독 화면)
- 로컬 알림 예약 상태

업데이트 모델:
- 읽기/설정 변경은 Domain 계산 후 Repository 저장으로 반영됩니다.
- 화면 상태는 저장 상태를 재조회해서 갱신하는 구조를 기본 원칙으로 합니다.

## 2) Entry points

- 앱 진입점: `FiveGuyes/FiveGuyes/Sources/App/FiveGuyesApp.swift`
- 루트 네비게이션: `FiveGuyes/FiveGuyes/Sources/App/NavigationRootView.swift`
- 화면 라우팅 정의: `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
- 도메인 실행 단위(UseCase):
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Notification/NotificationSettingUseCase.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Home/HomeNotificationUseCase.swift`
- 하루 경계 단일 진입(Service Provider): `FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
- Preview/Test 스텁 경계:
  - `FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift`
  - `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift`

## 3) Code map

`FiveGuyes/FiveGuyes/Sources`의 상위 맵:
- `App/`: 앱 시작, 루트 네비게이션
- `Presentation/`: SwiftUI View, UI 상태/네비게이션
- `Domain/`: 엔티티, 서비스 인터페이스, 비즈니스 규칙
- `Data/`: Repository 구현, SwiftData 스키마/매핑
- `Platform/`: 알림/분석/시스템 설정/외부 API 같은 OS·네트워크 연동 구현
- `Domain/Calculator/`: 도메인 계산기(`ReadingScheduleCalculator`, `DateMathCalculator`, `PageMathCalculator`)
- `Shared/Extensions/`: Foundation 확장과 날짜/문자열 정규화 유틸리티

주요 컴포넌트:

### Presentation

- 책임: 사용자 입력 수집, 화면 렌더링, 화면 전환
- 소유 상태: 포커스/입력값/토글/선택 인덱스 같은 UI 상태
- 의존: Domain UseCase 프로토콜, Domain 엔티티
- 금지 의존(목표): SwiftData 모델 타입(`UserBookSchemaV2.UserBookV2`)과 직접 저장 로직
- 경계 상태: 앱의 최외곽 입력 경계

### Domain

- 책임: 책 등록/기록/완독/삭제, 스케줄 계산, 유효성 규칙, UseCase 실행 단위 제공
- 소유 상태: 불변 데이터 구조(`FGUserBook`, `FGUserSetting`, `FGReadingProgress`)
- 의존: Repository/알림/시간 정책 같은 추상화
- 금지 의존: SwiftUI, SwiftData, View 타입
- 경계 상태: 앱의 핵심 규칙 계층
- 구현 메모: 운영/Preview/Test 경계 모두 `ViewModel -> UseCase` 인터페이스를 기준으로 정렬되었고, 런타임 미사용 중복 계층(`DefaultBookManagementService`, `BookManagementService`)은 제거되었다.

### Data

- 책임: SwiftData 저장/조회, Domain <-> SwiftData 매핑, 외부 저장소 어댑팅
- 소유 상태: `UserBookSchemaV2`, `BookMetaData`, `UserSettings`, `ReadingProgress`, `CompletionStatus`
- 의존: SwiftData 프레임워크
- 금지 의존: SwiftUI View/네비게이션
- 경계 상태: 영속성 경계

### Platform/External

- 책임: 알림(`NotificationManager`), 시스템 설정 이동(`SystemSettingsManager`), 외부 API(`AladinBookSearchProvider`)
- 경계 상태: iOS 시스템/네트워크 연동 경계

## 4) Architectural invariants

**Architecture Invariant: 도서 관리 핵심 도메인 데이터는 `FG*` 타입으로 계층 경계를 넘는다**
- Rationale: 저장소 기술(SwiftData) 변경 시 UI/도메인 영향 최소화
- Enforced by: `BookRepo`, `BookManagement` feature-level UseCase 시그니처 (`BookSearch`는 전용 도메인 타입 `BookSearchItem` 사용)
- Violation symptoms: View에서 SwiftData 모델 필드 직접 수정

**Architecture Invariant: SwiftData fetch/save는 Data 계층에서만 수행한다**
- Rationale: 테스트 가능성과 사이드이펙트 예측 가능성 확보
- Enforced by: `SwiftDataBookRepo`로 영속성 집중
- Violation symptoms: View의 `modelContext.insert/save/delete`

**Architecture Invariant: 스케줄 계산 로직은 단일 계산기 경로를 사용한다**
- Rationale: 중복 계산식 제거 및 결과 일관성 확보
- Enforced by: `ReadingScheduleCalculator`, `DateMathCalculator`, `PageMathCalculator`
- Violation symptoms: 화면별 다른 계산 결과, 같은 입력의 상이한 목표 페이지

**Architecture Invariant: 화면은 Command/Query를 UseCase 경유로 호출한다**
- Rationale: 화면이 필요한 실행 단위만 의존해 경계/테스트를 단순화
- Enforced by: `AppDependencies`의 UseCase 조립 + ViewModel 생성자 시그니처 (`...Using`)
- Violation symptoms: ViewModel이 과도한 파사드 인터페이스 또는 저장소를 직접 참조

**Architecture Invariant: View는 UseCase를 직접 참조하지 않고 ViewModel로만 상호작용한다**
- Rationale: View 계층을 렌더링/입력 전달 역할로 제한해 조립 책임을 분산시키지 않는다
- Enforced by: `NavigationCoordinator` 조립 + `BookSettingsManagerView` 생성자 주입 패턴 + `.swiftlint.yml` custom rule
- Violation symptoms: `Presentation/View`에서 `any ...Using` 또는 `@Environment(AppDependencies.self)` 직접 사용

**Architecture Invariant: ViewModel은 서비스 프로토콜(`...Managing/...Providing/...Storing/...Opening`)을 직접 의존하지 않는다**
- Rationale: ViewModel 경계에서 UseCase-first 흐름을 강제해 도메인 실행 단위를 명확히 유지한다
- Enforced by: `NotificationSettingUsing`, `HomeNotificationUsing` 같은 feature UseCase + `.swiftlint.yml` custom rule
- Violation symptoms: `Presentation/ViewModel` 생성자에 서비스 프로토콜이 직접 주입됨

**Architecture Invariant: 변환 로직은 매핑 확장 파일에서만 수행한다**
- Rationale: 매핑 규칙의 단일 소스 유지
- Enforced by: `FGUserBook+toUserBookV2.swift`, `UserBookV2+toFGUserBook.swift`
- Violation symptoms: 임의의 View/Service에서 ad-hoc 변환 코드 생성

**Architecture Invariant: 날짜 경계(04:00~03:59)는 단일 정책(`DayBoundaryProviding`)으로 정규화한다**
- Rationale: 날짜 비교/집계 오차 방지
- Enforced by: `DayBoundaryProviding`, `DefaultDayBoundaryPolicy`, `Date+Extension` 위임 경로
- Violation symptoms: 화면별 날짜 키 불일치, 기록 누락/중복

2026-02-17 기준 운영/Preview/Test 경로에 다음 정렬을 반영했습니다: `NotificationSettingUseCase` 도입으로 Noti 경계 UseCase-first 전환, `HomeNotificationUseCase`로 홈 알림 오케스트레이션 분리, `ReadingDateSettingViewModel` 도입으로 View direct UseCase 제거, `Date+Extension`의 provider 경유 통일, `.swiftlint.yml` 경계 가드룰(Stage 1). 남은 정리 항목은 `./docs/exec-plans/tech-debt-tracker.md`에서 추적합니다.

## 5) Boundaries & API surfaces

Boundary A: 도메인 실행 경계 `UseCase` 인터페이스
- 넘어오는 것: 사용자 액션 의도(등록/기록/완독/삭제/조회)
- 금지되는 것: SwiftData 모델 객체 자체, View 상태 객체

Boundary B: 영속성 인터페이스 `BookRepo`
- 넘어오는 것: `FGUserBook`, `FGReadingProgress`, `FGUserSetting` 등 Domain 타입
- 금지되는 것: ViewModel/SwiftUI 상태 객체

Boundary C: DTO/모델 매핑 확장
- 파일: `FGUserBook+toUserBookV2.swift`, `UserBookV2+toFGUserBook.swift`
- 규칙: 모델 변환은 여기서만 수행

Boundary D: 인프라 서비스 경계 (`ReadingNotificationScheduling`, `NotificationManaging`, `NotificationSettingsStoring`, `BookSearchProviding`, `DayBoundaryProviding`)
- 넘어오는 것: Domain 기반 상태(책 정보, 알림 시간 설정)
- 금지되는 것: Presentation 계층에서 직접 시스템 권한/요청 생성, UseCase의 concrete 플랫폼 타입 직접 의존

"only here" 규칙:
- SwiftData IO는 `Data/RepoImpl`에서만 수행
- SwiftData <-> Domain 매핑은 `Data/SwiftData/Extensions`, `Domain/Entity/Extension`에서만 수행
- 외부 API 호출은 `Platform/BookSearch/AladinBookSearchProvider.swift`(또는 이후 동등 Gateway)에서만 수행

## 6) Cross-cutting concerns

테스트 전략(경계 기준):
- Pure 계산 테스트: `FiveGuyes/FiveGuyesTests/Domain/Calculator/DateMathCalculatorTests.swift`, `FiveGuyes/FiveGuyesTests/Domain/Calculator/PageMathCalculatorTests.swift`, `FiveGuyes/FiveGuyesTests/Domain/Calculator/ReadingScheduleCalculator*.swift`
- UseCase/화면 경계 테스트: `FiveGuyes/FiveGuyesTests/Presentation/ViewModel/*.swift`
- UseCase 실행 테스트: `FiveGuyes/FiveGuyesTests/Domain/UseCase/BookManagementUseCases*.swift`, `FiveGuyes/FiveGuyesTests/Domain/UseCase/BookSearchUseCaseTests.swift`
- 알림/다음 독서 계산 테스트: `FiveGuyes/FiveGuyesTests/Domain/Entity/FGReadingProgressNotificationTests.swift`
- 저장소 테스트: `FiveGuyes/FiveGuyesTests/Data/Repo/SwiftDataBookRepoTests.swift` (In-memory SwiftData)

에러 처리 전략:
- Data 계층은 `RepoError`로 저장소 실패를 표준화
- Domain 계산 실패는 `ScheduleCalculationError`로 래핑
- Presentation은 도메인 에러를 사용자 액션 단위 메시지로 변환

## 7) Related docs

- 리팩터링 실행/결과 기록: `./docs/exec-plans/completed/mvvm-architecture-refactoring-execplan.md`
- Architecture debt wave 실행 계획: `./docs/exec-plans/architecture-debt-remediation-wave-plan.md`
- Architecture debt 이슈별 계획: `./docs/exec-plans/architecture-debt-issue-plans.md`
- Presentation 패턴 결정 기록(ADR): `./docs/decisions/adr-0001-presentation-architecture.md`
- UseCase/Service 경계 결정 기록(ADR): `./docs/decisions/adr-0002-usecase-first-boundary.md`
