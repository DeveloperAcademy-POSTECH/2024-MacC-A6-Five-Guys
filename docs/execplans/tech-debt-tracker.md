# Tech Debt Tracker

이 문서는 아키텍처/도메인 경계 정리 과정에서 당장 전면 수정하지 못한 기술 부채를 추적하기 위한 기록입니다.

## TD-001: 하루 경계(04:00~03:59) 규칙의 전역 강제 부족

- Status: Open (Production path mostly aligned; support paths remain)
- Context:
  - `DayBoundaryProviding`/`ReadingDateProviding` 도입 이후 운영 핵심 실행 경계(Main/Daily/Completion/ReadingPlan)는 대부분 도메인 기준 today를 내부 해상합니다.
  - 다만 일부 화면/보조 경로(완독 축하 요약, 프리뷰/샘플 today 주입)는 여전히 `Date()` 또는 UI 계층 직접 today 참조가 남아 있습니다.
- Risk:
  - 운영 경로 즉시 장애 가능성은 낮아졌지만, 경계 우회 지점이 남아 기능 확장/회귀 시 날짜 기준 불일치가 재발할 수 있습니다.
  - 프리뷰/보조 경로의 기준 불일치가 디버깅 시 기준선(정책 today)을 흐릴 수 있습니다.
- Target Layer:
  - `Domain/Service/ReadingDateProviding.swift` 단일 provider 경계 사용
- Trigger Condition:
  - 날짜 경계(03:59/04:00) 관련 버그 또는 날짜 파라미터 추가 시 즉시 우선 적용
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/TotalCalendar/MultiBookProgressView.swift`

## TD-002: SwiftData 모델의 도메인 계산 래퍼 제거

- Status: Resolved (2026-02-15 문서 동기화)
- Context:
  - 기존 추적 당시에는 `ReadingProgress`(SwiftData 모델)에 도메인 계산 래퍼 잔존 가능성을 부채로 기록했습니다.
  - 현재 구현 기준 `ReadingProgress`는 저장 필드만 보유하며, 계산 래퍼 메서드는 존재하지 않습니다.
- Risk:
  - 해당 항목의 즉시 리스크는 해소되었습니다.
  - 다만 향후 SwiftData 모델에 계산 로직이 재유입되면 동일 부채가 재발할 수 있습니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Extensions/UserBookV2+toFGUserBook.swift`
- Current Mitigation:
  - 도메인 계산은 `FGReadingProgress`/UseCase/Calculator 경계에서 수행하고, SwiftData 모델은 저장 전용으로 유지합니다.
- History/Resolved Note:
  - 2026-02-15 기준 코드 재검증에서 `ReadingProgress` 래퍼 메서드 부재가 확인되어 상태를 `Resolved`로 전환했습니다.
- Suggested Follow-up:
  1. 신규 SwiftData 모델 변경 리뷰 시 "저장 모델에 계산 메서드 추가 금지" 규칙을 체크리스트로 유지합니다.

## TD-003: 프레젠테이션 레이어 계산 로직 잔존

- Status: Open
- Context:
  - 아래 화면/뷰모델에 도메인 규칙 성격의 계산 로직이 남아 있어 UseCase 경계와 계산 규칙이 분산됩니다.
- Risk:
  - 화면별 계산식 수정이 분기별로 누락되어 규칙 드리프트가 발생할 수 있습니다.
- Target Layer:
  - `Domain/UseCase` 또는 `Domain/Calculator` 경유 단일 계산 경로
- Priority:
  - P3

### 대상 1: ReadingDateSettingView

- Path:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`
- 현황:
  - 초기 날짜/달력 선택 상태 및 일부 계산 분기가 View 내부에 있습니다.
- 위험:
  - 목표 기간 계산 기준이 다른 화면과 분리될 수 있습니다.
- 목표 레이어:
  - `ReadingPlan` 관련 UseCase/도메인 모델
- 트리거 조건:
  - 목표 기간 규칙 변경, 하루 경계 적용 범위 확장 시

### 대상 2: ReadingDateEditView

- Path:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDateEditView.swift`
- 현황:
  - `dayCount`, `pagesPerDay` 계산이 View 내부에 남아 있습니다.
- 위험:
  - `FinishGoalViewModel`/도메인 계산기와 규칙이 어긋날 수 있습니다.
- 목표 레이어:
  - `ReadingPlanUseCase`와 도메인 계산기(`DateMathCalculator`, `PageMathCalculator`)
- 트리거 조건:
  - 독서 계획 계산 규칙 변경, 목표기간 UI/정책 통합 작업 착수 시

### 대상 3: FinishGoalViewModel

- Path:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/FinishGoalViewModel.swift`
- 현황:
  - 추천 페이지 계산이 프레젠테이션 ViewModel 내부에서 직접 수행됩니다.
- 위험:
  - 동일 계산 규칙이 도메인 스케줄 계산과 분리되어 장기 유지보수 비용이 증가합니다.
- 목표 레이어:
  - `BookRegistration` 관련 UseCase/도메인 계산 경계
- 트리거 조건:
  - 등록 흐름 계산 규칙 조정 또는 공통 계산 API 도입 시

## TD-004: DayBoundary 직접 참조 잔존(Provider 경계 미통일)

- Status: Open
- Context:
  - `ReadingDateProviding`으로 today 해상 경계를 정리했지만, 일부 경로는 아직 `DayBoundary.shared`를 직접 호출합니다.
- Risk:
  - Provider 경계 우회로가 남아 있으면 정책 변경 시 수정 지점이 분산되고 회귀 위험이 커집니다.
- Target Layer:
  - `ReadingDateProviding`를 통한 단일 진입(`today`, `dayKey(from:)`, `adjustedDate(from:)` 확장 포함 검토)
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
- Suggested Follow-up:
  1. `Date` extension의 `toAdjustedYearMonthDayString/adjustedDate` 경유 정책을 provider 또는 domain policy로 단일화

## TD-005: CompletionCelebrationView 날짜 계산/표현 로직 혼재

- Status: Resolved (2026-02-15)
- Context:
  - `CompletionCelebrationView`의 날짜/요약 계산 로직을 `BookCompletionUseCase` 경계로 이동했습니다.
  - 완독 요약은 `CompletionCelebrationSummary` 모델을 통해 전달되며, today 기준은 `ReadingDateProviding`을 사용합니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/CompletionCelebrationViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementCompletionUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/execplans/td-005-completion-celebration-summary-boundary-execplan.md`

## TD-006: ViewModel 조립 책임(Composition Root) 상향 필요

- Status: Open
- Context:
  - 아키텍처 원칙은 View에서 ViewModel을 직접 생성하지 않고, Navigation/Coordinator(Composition Root)에서 주입하는 방식입니다.
  - 현재 일부 화면/프리뷰 경로는 View 내부에서 ViewModel 및 의존성 생성이 남아 있습니다.
- Risk:
  - 화면별 조립 방식이 분산되면 의존성 불일치, 테스트 대역 주입 누락, 경계 드리프트가 발생할 수 있습니다.
- Target Layer:
  - `NavigationCoordinator` 중심 조립 + 화면 진입 시 ViewModel 완전 주입
- Trigger Condition:
  - 화면 생성자 정리 작업 착수, DI 표준화 단계 진행 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`
- Suggested Follow-up:
  1. View 생성자에서 ViewModel 기본값/직접 생성 제거
  2. Navigation 경로별 ViewModel/UseCase 주입 템플릿 표준화

## TD-007: 날짜 키 시맨틱/타입 분리 부족 + 키 포맷 타임존 명시 누락

- Status: Open (Compatibility migration + scoped completion key applied)
- Fix Required: Partial
- Decision:
  - `toYearMonthDayString()`/`toDate()` 타임존 명시는 반영 완료했습니다(`ReadingDateKey` 경유).
  - 저장 키 시맨틱은 `ReadingDateKey` value object로 1차 고정했지만, 저장 딕셔너리(`[String: ReadingRecord]`)는 호환을 위해 유지했습니다.
  - `SwiftDataBookRepository` fetch 경계에 1회 호환 마이그레이션을 도입해 legacy 저장 키를 정책 키로 정리했습니다.
  - 마이그레이션 구현은 repository 내부 구조체(`ReadingRecordKeyMigrationV1`) + `UserDefaults` 직접 접근으로 경량화해 추후 삭제 경계를 repository 내부로 고정했습니다.
  - 완료 플래그는 앱/스토어/버전 스코프 키를 기본으로 사용하고, 기존 단일 키는 fallback 읽기 후 승격합니다.
  - 앱 시작 시 prewarm을 선실행하고 fetch 경계 호출은 fallback 재시도 경계로 유지합니다.
  - 남은 범위는 raw string 저장 경계 축소, `toAdjustedYearMonthDayString`/`adjustedDate` 호출 경계 제한, 글로벌 타임존 UX 확장입니다.
- Context:
  - 저장/조회 키 생성/파싱은 `ReadingDateKey` 타입으로 통일했습니다.
  - `DayBoundaryProviding.adjustedDayKey(from:)`는 `ReadingDateKey`를 반환하도록 변경해 정책 키 경계를 타입화했습니다.
  - 저장 호환성은 repository 레이어 1회 마이그레이션으로 보정합니다(`lastReadDate` anchor + safe shift).
  - `toAdjustedYearMonthDayString()`/`adjustedDate()`는 여전히 `Date` 확장 API로 남아 있어, 장기적으로는 도메인 정책 경계로 더 수렴할 필요가 있습니다.
  - 글로벌 사용자 UX를 위해서는 한국 고정 정책을 설정 가능 정책으로 확장해야 하지만, 이번 범위에서는 의도적으로 제외했습니다.
- Risk:
  - 현재 런타임 키 불일치 리스크는 감소했지만, 저장 모델이 문자열 키를 직접 보유하므로 호출부에서 `.rawValue` 남용이 재발할 수 있습니다.
  - 정책 반영 날짜 API(`toAdjustedYearMonthDayString`/`adjustedDate`)가 범용 확장에 남아 있어 경계 우회 가능성이 있습니다.
  - 해외 사용자 환경에서는 한국 고정 기준으로 인해 day-boundary 체감 차이가 발생할 수 있습니다.
  - 완료 플래그 충돌 리스크는 앱 스코프 키로 줄었지만, 여전히 1회 완료 모델이므로 이후 백업 복원/외부 import로 legacy 키가 재유입되면 자동 보정이 적용되지 않을 수 있습니다.
- Target Layer:
  - `Domain` value object(`ReadingDateKey`) 기반 키 시맨틱 유지/확장
  - 저장 경계에서도 typed key 우선 경로를 보장하는 API 정리
- Trigger Condition:
  - 날짜 키 관련 버그 발생, 저장 포맷/정책 변경, cross-timezone 요구사항 반영 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/String+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/DayBoundaryProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepositoryImpl/SwiftDataBookRepository.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Calendar+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
- Suggested Follow-up:
  1. 저장 모델(`[String: ReadingRecord]`) 호출부에 typed key adapter를 추가해 raw string 직접 접근을 축소
  2. `toAdjustedYearMonthDayString`/`adjustedDate` 호출 경계를 `ReadingDateProviding`/`DayBoundaryProviding`로 제한
  3. 글로벌 UX 확장 시 day-boundary 타임존 정책을 사용자/지역 기반으로 분리하고 전환 전략(마이그레이션 포함)을 별도 설계
  4. legacy 데이터 재유입 가능성이 생기면 전역 1회 플래그를 버전드/조건부 마이그레이션으로 전환

## TD-008: 알림 스케줄링 async 계약 불명확성

- Status: Resolved (2026-02-16)
- Context:
  - `NotificationManager.setupAllNotifications`에서 내부 fire-and-forget `Task`를 제거했습니다.
  - 호출 경계에서 `clearRequests -> morning -> night`가 직렬 `await`로 실제 완료됩니다.
  - `NotificationManaging` 의존 변수명을 `notificationService`로 통일해 Service 용어 규칙을 맞췄습니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotificationSettingViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Presentation/ViewModel/NotificationSettingViewModelTests.swift`

## TD-009: UseCase-first 경계 드리프트(엄격 기준)

- Status: Resolved (2026-02-16)
- Context:
  - `MainHomeViewModel`의 인프라 직접 의존을 제거하고 `ReadingLibraryUsing.setupNotifications(for:)` 경유로 이동했습니다.
  - `BookSearchViewModel`의 `BookSearching` 직접 의존을 제거하고 `BookSearchUsing` 경계를 도입했습니다.
  - `BookManagementUseCases` 단일 파일을 기능군 3파일로 분리해 UseCase 경계 탐색성과 유지보수성을 개선했습니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookSearch/BookSearchUseCase.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementLibraryAndRegistrationUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementDailyAndPlanUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementCompletionUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0002-usecase-first-boundary.md`

## TD-010: 알림 일괄 등록 시 권한 체크 중복 호출

- Status: Open
- Context:
  - `NotificationManager.setupAllNotifications`는 내부에서 morning/night를 각각 호출하고, 각 호출에서 `canSendNotifications -> requestAuthorization`를 다시 수행합니다.
  - 동일 흐름에서 권한/앱 설정 판단이 중복됩니다.
- Risk:
  - 불필요한 권한 상태 조회가 누적되어 알림 등록 성능과 비동기 결정성이 흔들릴 수 있습니다.
  - 추후 권한 처리 정책 변경 시 수정 지점이 분산될 수 있습니다.
- Target Layer:
  - `Platform/Notification`에서 일괄 등록 기준 단일 권한 체크 보장
- Trigger Condition:
  - 알림 등록/권한 처리 정책 변경, 비동기 성능 점검 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
- Suggested Follow-up:
  1. `setupAllNotifications` 진입 시 권한 체크 1회 수행 후 morning/night 스케줄링 실행
  2. 권한 체크 실패 시 조기 반환 계약을 테스트로 명시

## TD-011: ReadingLibraryUseCase 응집도 저하 (조회 + 홈 알림 트리거 혼합)

- Status: Open
- Context:
  - `ReadingLibraryUsing`에 홈 진입 알림 실행용 `setupNotifications(for:)`가 포함되어, 도서 조회/삭제 책임과 홈 라이프사이클 부작용 책임이 결합되어 있습니다.
- Risk:
  - 홈 전용 사이드이펙트가 ReadingLibrary 경계로 계속 유입될 수 있습니다.
  - 기능 경계 의미가 확장되며 UseCase 탐색/유지보수 비용이 커집니다.
- Target Layer:
  - 홈 라이프사이클 전용 UseCase 또는 오케스트레이션 경계 분리
- Trigger Condition:
  - 홈 진입 플로우 확장, 추가 사이드이펙트 도입 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementLibraryAndRegistrationUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
- Suggested Follow-up:
  1. 홈 진입 오케스트레이션 전용 `...Using` 경계 분리 검토
  2. ReadingLibrary 경계는 조회/삭제/재스케줄 도메인 책임으로 다시 축소

## TD-012: Preview/Test 어댑터 매핑 중복

- Status: Open
- Context:
  - `BookManagementService -> ...Using` 매핑 어댑터가 Preview와 Test 지원 파일에 유사 로직으로 중복되어 있습니다.
- Risk:
  - 인터페이스 변경 시 양쪽 동시 수정 누락 가능성이 높아집니다.
  - 테스트/프리뷰 행위 불일치가 숨은 회귀를 만들 수 있습니다.
- Target Layer:
  - Preview/Test 공통 어댑터 재사용 또는 단일 팩토리 경계
- Trigger Condition:
  - `...Using` 인터페이스 변경, 프리뷰/테스트 인프라 리팩토링 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/Preview/PreviewSupport.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Presentation/ViewModel/ViewModelTestSupport.swift`
- Suggested Follow-up:
  1. 공통 어댑터 타입 또는 빌더를 도입해 중복 제거
  2. 인터페이스 변경 시 단일 수정 지점으로 정리

## TD-013: Notification 경계 선언 위치 정렬

- Status: Resolved (2026-02-16)
- Context:
  - `NotificationManaging`, `NotificationSettingsStoring` 선언을 `NotificationSettingViewModel`에서 분리해 Domain Service 경계로 이동했습니다.
  - `UserDefaultsNotificationSettingsStore` 구현을 Data(UserDefaults) 계층으로 이동해 Presentation이 인프라 구현을 소유하지 않도록 정렬했습니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/NotificationManaging.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/NotificationSettingsStoring.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/UserDefaults/UserDefaultsNotificationSettingsStore.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotificationSettingViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`

## Recommended Execution Order

1. TD-008: 알림 스케줄링 async 계약 정리 (P2) - Resolved (2026-02-16)
2. TD-009: UseCase-first 경계 일관화 (P2) - Resolved (2026-02-16)
3. TD-013: Notification 경계 선언 위치 정렬 (P1) - Resolved (2026-02-16)
4. TD-010: 알림 일괄 등록 권한 체크 중복 제거 (P2)
5. TD-011: ReadingLibraryUseCase 책임 재분리 (P2)
6. TD-012: Preview/Test 어댑터 중복 제거 (P3)
7. 나머지 Open P2/P3 항목 순차 정리
