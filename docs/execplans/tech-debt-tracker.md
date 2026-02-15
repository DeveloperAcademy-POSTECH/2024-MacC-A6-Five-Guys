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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
- Suggested Follow-up:
  1. `Date` extension의 `toAdjustedYearMonthDayString/adjustedDate` 경유 정책을 provider 또는 domain policy로 단일화

## TD-005: CompletionCelebrationView 날짜 계산/표현 로직 혼재

- Status: Open
- Context:
  - `CompletionCelebrationView`가 도메인 today 경계를 사용하지 않고 `Date()`를 직접 사용해 완독 기간 텍스트를 구성합니다.
  - 시작일/종료일 비교를 날짜 타입이 아닌 문자열 비교로 처리하고 있습니다.
  - 완독 요약 계산 로직이 View 내부에 남아 있습니다.
- Risk:
  - 04:00 하루 경계 규칙과 화면 표시가 어긋날 수 있고, locale/포맷 변경 시 문자열 비교 오류 가능성이 있습니다.
  - 날짜/요약 규칙이 화면 구현과 결합되어 규칙 변경 시 회귀 위험이 큽니다.
- Target Layer:
  - `Domain/UseCase` 또는 `Domain` 계산 경계에서 완독 요약용 데이터 모델 제공
- Trigger Condition:
  - 완독 요약 문구 규칙 변경, 날짜 경계 정책 변경, 완료 시나리오 UX 개편 시
- Priority:
  - P1
- Execution Priority:
  - Next target (현재 1순위)
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`

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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/String+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/DayBoundaryProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepositoryImpl/SwiftDataBookRepository.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Calendar+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
- Suggested Follow-up:
  1. 저장 모델(`[String: ReadingRecord]`) 호출부에 typed key adapter를 추가해 raw string 직접 접근을 축소
  2. `toAdjustedYearMonthDayString`/`adjustedDate` 호출 경계를 `ReadingDateProviding`/`DayBoundaryProviding`로 제한
  3. 글로벌 UX 확장 시 day-boundary 타임존 정책을 사용자/지역 기반으로 분리하고 전환 전략(마이그레이션 포함)을 별도 설계
  4. legacy 데이터 재유입 가능성이 생기면 전역 1회 플래그를 버전드/조건부 마이그레이션으로 전환

## TD-008: 알림 스케줄링 async 계약 불명확성

- Status: Open
- Context:
  - `NotificationManager.setupAllNotifications`는 `async` 메서드이지만 내부에서 fire-and-forget `Task`를 생성합니다.
  - 호출부 UseCase는 `await`로 순서를 맞춘다고 가정하나, 실제로는 내부 작업 완료 시점이 호출 경계와 분리됩니다.
- Risk:
  - 호출 순서 보장과 테스트 결정성이 약해져 타이밍 의존 회귀를 만들 수 있습니다.
  - 알림 초기화/재등록 시점이 기능 흐름(등록/기록/계획수정)과 어긋날 수 있습니다.
- Target Layer:
  - `Platform/Notification` 경계에서 명시적 async 완료 계약 보장
  - `Domain/UseCase`의 `await` 의미와 실제 부작용 완료 시점 일치
- Trigger Condition:
  - 알림 관련 회귀, 타이밍 이슈, 비동기 결정성 테스트 강화 작업 착수 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/BookManagementUseCases.swift`
- Suggested Follow-up:
  1. `setupAllNotifications` 내부 fire-and-forget `Task` 제거 또는 명시적 완료 동기화 구조로 전환
  2. UseCase 테스트에서 알림 스케줄링 완료 시점을 검증할 수 있는 contract 테스트 추가

## TD-009: UseCase-first 경계 드리프트(엄격 기준)

- Status: Open
- Context:
  - ADR-0002 기준은 Presentation(ViewModel)에서 도메인 실행 단위를 UseCase로 직접 호출하는 구조를 고정합니다.
  - 현재 `MainHomeViewModel`은 `NotificationManaging`을, `BookSearchViewModel`은 `BookSearching`을 직접 의존해 UseCase-first 경계가 일부 완화되어 있습니다.
- Risk:
  - ViewModel 경계 의미가 화면별로 달라져 DI 조립 기준이 분산될 수 있습니다.
  - 인프라 의존이 Presentation으로 확산되면 ADR 용어/규칙(`UseCase` vs `Service`) 일관성이 약화됩니다.
- Target Layer:
  - `ViewModel -> UseCase` 단일 실행 경계 유지
  - 인프라 연동은 UseCase 내부 조합 또는 UseCase 어댑터로 캡슐화
- Trigger Condition:
  - 홈/검색 플로우 수정, DI 표준화, 아키텍처 정리 스프린트 착수 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0002-usecase-first-boundary.md`
- Suggested Follow-up:
  1. 홈 알림 등록 경로를 UseCase 경유로 이동해 `MainHomeViewModel`의 인프라 직접 의존 제거
  2. 검색 기능도 UseCase/Facade 경계로 래핑해 Presentation의 `BookSearching` 직접 의존 제거
  3. `NavigationCoordinator`/`AppDependencies` 조립 템플릿에 UseCase-first 규칙을 명시

## Recommended Execution Order

1. TD-005: CompletionCelebrationView 날짜/요약 경계화 (P1)
2. TD-008: 알림 스케줄링 async 계약 정리 (P2)
3. TD-009: UseCase-first 경계 일관화 (P2)
4. 나머지 P2/P3 항목 순차 정리
