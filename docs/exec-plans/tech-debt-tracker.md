# Tech Debt Tracker

이 문서는 아키텍처/도메인 경계 정리 과정에서 당장 전면 수정하지 못한 기술 부채를 추적하기 위한 기록입니다.

## Review Sync (2026-02-16)

- 본 문서는 2026-02-16 아키텍처 리뷰 결과 8건(P1 1건, P2 4건, P3 3건)을 반영해 갱신되었습니다.
- 이번 리뷰에서 확인된 항목 매핑:
  - Finding 1 -> TD-018
  - Finding 2 -> TD-017
  - Finding 3 -> TD-003
  - Finding 4 -> TD-019
  - Finding 5 -> TD-016
  - Finding 6 -> TD-020
  - Finding 7 -> TD-021
  - Finding 8 -> TD-022

## Review Sync (2026-02-17, Presentation)

- 본 문서는 2026-02-17 Presentation 집중 리뷰 결과 2건(P2 2건)을 반영해 갱신되었습니다.
- 이번 리뷰에서 확인된 항목 매핑:
  - Finding 1 -> TD-024
  - Finding 2 -> TD-023

## Review Sync (2026-02-17, Presentation SwiftUI Follow-up)

- 본 문서는 2026-02-17 SwiftUI 관점 후속 리뷰 결과 2건(P2 2건)을 반영해 갱신되었습니다.
- 이번 리뷰에서 확인된 항목 매핑:
  - Finding 1 -> TD-025
  - Finding 2 -> TD-026

## Review Sync (2026-02-17, Presentation Regression Follow-up)

- 본 문서는 2026-02-17 Presentation 회귀 후속 리뷰에서 중복 제거 후 2건(P2 1건, P3 1건)을 반영해 갱신되었습니다.
- 이번 리뷰에서 확인된 항목 매핑:
  - Finding 2 + Finding 3 -> TD-027
  - Finding 1 + Finding 4 -> TD-028

## Review Sync (2026-02-17, F1-F5 Execution Follow-up)

- 본 문서는 F1~F5 실행 후속 반영으로 상태를 재동기화했습니다.
- 이번 반영 매핑:
  - Finding 1 + Finding 4 + Finding 5 -> TD-007(Partial, 후속 범위 축소)
  - Finding 2 -> TD-027(Closed, 실행일 완료 정책 확정)
  - Finding 3 -> TD-028(Partial, prewarm 관측성 1차 보강)
  - Additional Debt -> TD-029(Analytics 경계 분리 부채 신규 등록)

## Review Sync (2026-02-17, Settings LocalDate Stability)

- 본 문서는 설정일 day drift(타임존 이동 시 시작일/종료일 하루 밀림) 후속 작업을 반영해 갱신되었습니다.
- 이번 반영 매핑:
  - Settings Date Drift Risk -> TD-007(Partial, settings LocalDate source-of-truth 병행 적용)
  - Decision Record -> ADR-0005

## Review Sync (2026-02-17, Date Policy Finalization)

- 본 문서는 날짜 정책 확정 후속(legacy 재유입 자동 재보정 + 구조적 진단 로깅) 반영으로 상태를 재동기화했습니다.
- 이번 반영 매핑:
  - legacy 재유입 조건부 재보정 -> TD-007(Partial, 재유입 보정 리스크 해소)
  - prewarm/migration 구조적 관측성 -> TD-028(Closed)

## TD-001: 하루 경계(04:00~03:59) 규칙의 전역 강제 부족

- Status: Closed (2026-02-17)
- Resolution:
  - Preview/sample에서 `today` 주입에 사용하던 `Date()` 경로를 `DefaultReadingDateProvider().today()`로 통일했습니다.
  - 대표 화면 프리뷰(`ReadingDateSettingView`, `ReadingDatePickerView`, `CalendarGridView`, `MultiBookProgressView`, `ReadingBookProgressCell`, `ReadingBooksCarousel`, `WeeklyProgressCalendar`)를 같은 기준으로 정렬했습니다.
- Context:
  - `DayBoundaryProviding`/`ReadingDateProviding` 도입 이후 운영 핵심 실행 경계(Main/Daily/Completion/ReadingPlan)는 도메인 기준 today를 사용합니다.
  - 다만 일부 프리뷰/샘플 경로는 여전히 `Date()` 기반 today 주입을 사용합니다.
- Risk:
  - 운영 경로 즉시 장애 가능성은 낮지만, 프리뷰/보조 경로 기준선이 분리되면 날짜 경계 회귀 시 디버깅 기준이 흔들릴 수 있습니다.
- Target Layer:
  - `Domain/Service/ReadingDateProviding.swift` 단일 provider 경계 사용
- Trigger Condition:
  - 날짜 경계(03:59/04:00) 관련 버그 또는 날짜 파라미터 추가 시 즉시 우선 적용
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/TotalCalendar/MultiBookProgressView.swift`

## TD-003: 프레젠테이션 레이어 계산 로직 잔존

- Status: Closed (2026-02-16)
- Resolution:
  - `ReadingGoalMetricsUseCase`를 도입해 `DateMathCalculator`/`PageMathCalculator` 직접 생성 경로를 공통 UseCase로 수렴했습니다.
  - `ReadingDateSettingView`, `ReadingDateEditView`, `FinishGoalViewModel`이 공통 계산 경계를 사용하도록 변경했습니다.
  - `FinishGoalViewModelTests`에 계산 UseCase 위임 회귀 테스트를 추가했습니다.
- Context:
  - 아래 화면/뷰모델에 도메인 규칙 성격의 계산 로직이 남아 있어 UseCase 경계와 계산 규칙이 분산됩니다.
- Risk:
  - 화면별 계산식 수정이 분기별로 누락되어 규칙 드리프트가 발생할 수 있습니다.
- Target Layer:
  - `Domain/UseCase` 또는 `Domain/Calculator` 경유 단일 계산 경로
- Priority:
  - P2
- Review Note (2026-02-16):
  - View 직접 계산 경로가 3곳에서 동시에 확인되어 우선순위를 P3 -> P2로 상향합니다.

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

- Status: Closed (2026-02-17)
- Resolution:
  - `Date+Extension.toAdjustedYearMonthDayString`가 `DayBoundary.shared` 직접 호출 대신 `DefaultReadingDateProvider().dayKey(from:)` 경유로 정책 키를 해석하도록 정리했습니다.
  - `ReadingDateProviding` 계약에 `adjustedDate(from:)`, `dayKey(from:)`를 추가해 provider 경계에서 날짜 정책 연산을 노출했습니다.
- Context:
  - `ReadingDateProviding`으로 today 해상 경계를 정리했지만, 일부 경로는 아직 `DayBoundary.shared`를 직접 호출합니다.
- Risk:
  - Provider 경계 우회로가 남아 있으면 정책 변경 시 수정 지점이 분산되고 회귀 위험이 커집니다.
- Target Layer:
  - `ReadingDateProviding`를 통한 단일 진입(`today`, `dayKey(from:)`, `adjustedDate(from:)` 확장 포함 검토)
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
- Suggested Follow-up:
  1. `Date` extension 호출 경계를 단계적으로 축소해 도메인 경계에서 직접 provider를 호출하도록 수렴

## TD-006: ViewModel 조립 책임(Composition Root) 상향 필요

- Status: Closed (2026-02-17)
- Resolution:
  - `BookSettingsManagerView`에서 `@Environment(AppDependencies.self)`와 하위 ViewModel 직접 생성을 제거했습니다.
  - `NavigationCoordinator`에서 `BookSearchViewModel`, `FinishGoalViewModel`, `ReadingDateSettingViewModel`를 조립해 `BookSettingsManagerView` 생성자로 주입하도록 정리했습니다.
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
  1. 다른 feature 화면도 동일한 조립 템플릿으로 점진 이행
  2. Coordinator 조립 규칙을 아키텍처 문서 예시 코드로 고정

## TD-007: 날짜 키 시맨틱/타입 분리 부족 + 키 포맷 타임존 명시 누락

- Status: Partial (2026-02-17, record timezone snapshot + settings LocalDate key parallel applied)
- Fix Required: Remaining
- Resolution (2026-02-17):
  - `ReadingRecord`에 `timeZoneID`를 추가하고 legacy decode fallback(`Asia/Seoul`)을 적용했습니다.
  - 저장 key는 `yyyy-MM-dd`를 유지하고, 신규/재계산 레코드만 현재 타임존을 기록하는 forward-only 정책을 반영했습니다.
  - `ReadingTimeZoneProviding`을 도입해 UseCase -> Calculator write 경계에서 `activeTimeZoneID`를 명시 전달하도록 정리했습니다.
  - `SwiftDataBookRepo` migration normalize/merge에서 `timeZoneID` 보존 정책을 추가했습니다.
  - `toAdjustedYearMonthDayString`를 제거해 날짜 키 우회 경계를 축소했습니다.
  - 결정 근거는 ADR-0004로 고정했습니다.
  - `FGUserSetting` 설정일을 `ReadingDateKey` source-of-truth로 전환해 설정일 비교/계산 경계에서 `Date` 절대시각 의존을 줄였습니다.
  - SwiftData `UserSettings`에 `startDateKey/targetEndDateKey/nonReadingDayKeys` 병행 필드를 추가하고 key 우선 읽기 정책을 적용했습니다.
  - legacy 설정 데이터는 `Asia/Seoul` 기준 key fallback + fetch/prewarm 1회 backfill로 점진 전환했습니다.
  - migration completion flag가 true여도 legacy/오염 데이터가 재유입되면 조건부 재보정이 자동 실행되도록 `SwiftDataBookRepo` 보정 모드를 추가했습니다.
  - 결정 근거는 ADR-0005로 고정했습니다.
- Context:
  - key 시맨틱은 `ReadingDateKey` + ADR-0003 호환 마이그레이션으로 이미 고정되어 있습니다.
  - 이번 단계에서 value 레벨 타임존 문맥(`ReadingRecord.timeZoneID`)과 settings LocalDate key 문맥(`FGUserSetting.*DateKey`)을 함께 적용해 해외 이동 시 기록/설정의 날짜 경험을 분리 보존합니다.
  - 저장 딕셔너리(`[String: ReadingRecord]`)는 호환을 위해 유지합니다.
- Risk:
  - 저장 모델이 문자열 key를 직접 보유하므로 호출부에서 `.rawValue` 남용이 재발할 수 있습니다.
  - `UserSettings`가 `Date` + `DateKey` 병행 필드를 동시에 보유하므로 후속 제거 마이그레이션 전까지 dual-write drift 가능성이 남습니다.
  - UI에서 타임존/day-boundary 정책을 사용자 설정으로 노출하지 않아 글로벌 UX는 아직 제한적입니다.
- Target Layer:
  - `Domain` value object(`ReadingDateKey`) 기반 키 시맨틱 유지/확장
  - 저장 경계에서도 typed key 우선 경로를 보장하는 API 정리 + record timezone policy 유지
- Trigger Condition:
  - 날짜 키 관련 버그 발생, 저장 포맷/정책 변경, cross-timezone 요구사항 반영 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingRecord.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingTimeZoneProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/String+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/DayBoundaryProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/UserSettings.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Extensions/UserBookV2+toFGUserBook.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Calendar+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0005-settings-localdate-source-of-truth.md`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/exec-plans/td-007-settings-localdate-stability-execplan.md`
- Suggested Follow-up:
  1. 저장 모델(`[String: ReadingRecord]`) 호출부에 typed key adapter를 추가해 raw string 직접 접근을 축소
  2. `UserSettings`의 legacy `Date` 필드를 제거하는 후속 스키마 마이그레이션을 별도 TD로 분리해 수행
  3. 글로벌 UX 확장 시 day-boundary 타임존 정책을 사용자/지역 기반으로 분리하고 전환 전략(마이그레이션 포함)을 별도 설계
  4. 조건부 재보정 스캔 비용과 실행 빈도를 운영 로그로 모니터링하고 버전드 전략 필요 시 분리

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

- Status: Closed (2026-02-17)
- Resolution:
  - `ReadingLibraryUsing`에서 `setupNotifications(for:)`를 제거해 조회/삭제/재스케줄 책임만 유지하도록 API를 축소했습니다.
  - 홈 진입 알림 오케스트레이션은 `HomeNotificationUsing`/`HomeNotificationUseCase`로 분리했습니다.
  - `MainHomeViewModel`을 `ReadingLibraryUsing + HomeNotificationUsing` 2-UseCase 구성으로 전환했습니다.
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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Home/HomeNotificationUseCase.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
- Suggested Follow-up:
  1. 홈 전용 사이드이펙트가 추가될 때도 `HomeNotificationUsing` 경계로만 확장되도록 유지

## TD-015: 야간 알림 시간 상수 유효 범위 이탈

- Status: Open
- Context:
  - `NotificationType.timeContent`의 `.night`가 `(24, 0)`을 반환합니다.
  - `DateComponents.hour` 유효 범위(0...23)를 벗어나며, 트리거가 다음날 00:00으로 밀리거나 무효 처리될 수 있습니다.
- Risk:
  - 의도한 "야간 알림" 시점 보장이 깨질 수 있습니다.
  - 기기/OS 버전에 따라 스케줄 해석이 달라져 재현성 없는 알림 누락이 발생할 수 있습니다.
- Target Layer:
  - `Platform/Notification`의 알림 시각 정책 상수
- Trigger Condition:
  - 알림 시간 정책 변경, 야간 알림 회귀, 알림 스케줄 재구성 시
- Priority:
  - P1
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationType.swift`
- Suggested Follow-up:
  1. `.night` 시각을 유효 범위 값(예: `23:00`)으로 교체하고 정책 의도를 주석/상수명으로 명시
  2. `FGReadingProgressNotificationTests` 또는 `NotificationType` 테스트에 night 시간 유효성 검증 케이스 추가

## TD-016: 도서 검색 URL 조합의 인코딩/응답 검증 부족

- Status: Closed (2026-02-16)
- Resolution:
  - `AladinBookSearchProvider` 요청 생성을 `URLComponents + queryItems`로 전환했습니다.
  - `HTTPURLResponse.statusCode` 검증과 `BookSearchNetworkError` 명시 오류 매핑을 추가했습니다.
  - `AladinBookSearchProviderTests`를 추가해 특수문자 인코딩/비정상 상태코드 회귀를 고정했습니다.
- Context:
  - `AladinBookSearchProvider`가 검색/상세조회 URL을 문자열 보간으로 직접 조합합니다.
  - `query`/`isbn`이 percent-encoding 없이 삽입되고, HTTP 상태 코드 검증 없이 디코딩을 시도합니다.
- Risk:
  - 공백/`&`/`+` 포함 입력에서 파라미터 오염으로 검색 실패 또는 오동작 가능성이 있습니다.
  - 비정상 응답(4xx/5xx/HTML 오류 페이지)에서도 디코딩 실패로 원인 파악이 어려워집니다.
- Target Layer:
  - `Platform/BookSearch` URL 생성/네트워크 응답 검증 경계
- Trigger Condition:
  - 검색 품질 이슈, API 파라미터 추가, 네트워크 에러 처리 개선 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/BookSearch/AladinBookSearchProvider.swift`
- Suggested Follow-up:
  1. `URLComponents` + `queryItems`로 URL 생성 로직 전환
  2. `HTTPURLResponse.statusCode` 검증 후 명시적 오류 매핑
  3. Provider 레벨 통합 테스트에 URL 인코딩/상태코드 처리 케이스 추가

## TD-017: 페이지 설정 화면 복원 로직 결함

- Status: Closed (2026-02-16)
- Resolution:
  - `BookPageSettingView.initializePageSettings()`에서 `startPage`/`targetEndPage` 복원 대입을 올바르게 수정했습니다.
  - 회귀 검증은 등록 플로우 수동 검증 + 관련 ViewModel 테스트 스위트로 수행했습니다.
- Context:
  - `BookPageSettingView.initializePageSettings()`에서 `startPage`를 복원하지 않고 `targetEndPage`에 두 번 대입하고 있습니다.
- Risk:
  - 사용자가 다음 단계로 이동 후 뒤로 돌아올 때 시작 페이지가 초기값(1)로 유실되어 UX 일관성이 깨집니다.
  - 입력 복원 신뢰도가 떨어져 등록 플로우 이탈 가능성이 커집니다.
- Target Layer:
  - `Presentation/View/BookSetting` 입력 상태 복원 경계
- Trigger Condition:
  - 도서 등록 플로우 수정, back-navigation 상태 유지 정책 변경 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookPageSettingView.swift`
- Suggested Follow-up:
  1. `initializePageSettings()`에서 `startPage`/`targetEndPage`를 각각 올바르게 복원
  2. 페이지 설정 화면 왕복(back-forward) 상태 복원 UI 테스트 또는 ViewModel 테스트 추가

## TD-018: 알림 OFF 상태에서도 시간 변경이 알림 재예약을 유발

- Status: Closed (2026-02-16)
- Resolution:
  - `NotiSettingViewModel.handleNotificationTimeChange`에 앱 내 알림 OFF 조기 반환을 적용했습니다.
  - `NotificationManager` 재등록 경로에 권한/앱 설정 재검증을 추가했습니다.
  - `NotiSettingViewModelTests`에 OFF 상태 시간 변경 회귀 테스트를 추가했습니다.
- Context:
  - `NotiSettingView`의 시간 변경(`selectedTime`)은 항상 `NotiSettingViewModel.handleNotificationTimeChange`로 연결됩니다.
  - 해당 메서드는 앱 내 알림 비활성화 상태와 무관하게 `notificationService.updateNotification`을 호출합니다.
  - `NotificationManager.updateNotification`은 `canSendNotifications` 검증 없이 스케줄 등록을 수행합니다.
- Risk:
  - 사용자가 앱 내 알림을 꺼도 시간 변경 또는 초기 값 동기화 시 알림이 다시 예약될 수 있습니다.
  - 사용자 의도와 실제 알림 동작이 어긋나 신뢰도 저하로 이어질 수 있습니다.
- Target Layer:
  - `Presentation/ViewModel` + `Platform/Notification` 알림 재등록 경계
- Trigger Condition:
  - 알림 설정 화면 로직 변경, 알림 시간 정책 변경, 알림 이슈 재현 시 즉시 우선 대응
- Priority:
  - P1
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
- Suggested Follow-up:
  1. `handleNotificationTimeChange`에서 앱 내 알림 비활성화 상태면 조기 반환
  2. `NotificationManager.updateNotification`에서도 `canSendNotifications`를 재검증해 이중 방어
  3. "앱 내 알림 OFF + 시간 변경" 회귀 테스트를 `NotiSettingViewModelTests`에 추가

## TD-019: Domain 서비스 계약이 Platform 타입(NotificationType)에 의존

- Status: Closed (2026-02-16)
- Resolution:
  - `NotificationManaging` 계약을 `updateMorningNotification(for:)`로 재정의해 Platform 타입 누수를 제거했습니다.
  - Platform 상세(`NotificationType`)는 `NotificationManager` 내부 구현으로 축소했습니다.
  - Preview/Test 스텁을 Domain 계약 기준으로 정리했습니다.
- Context:
  - `NotificationManaging` 계약이 `NotificationType`(Platform 위치 타입)을 파라미터로 노출합니다.
  - 결과적으로 Domain 서비스 인터페이스가 Platform 구현 상세를 직접 참조합니다.
- Risk:
  - 계층 경계 방향이 느슨해져 모듈 분리 시 순환 의존 위험이 커집니다.
  - 알림 정책 변경 시 Domain 계약과 Platform 구현이 동시에 흔들릴 수 있습니다.
- Target Layer:
  - `Domain/Service` 알림 계약 경계
- Trigger Condition:
  - 알림 계약 변경, 모듈 분리 착수, 알림 타입 확장 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/NotificationManaging.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationType.swift`
- Suggested Follow-up:
  1. Domain 전용 요청 모델(예: `NotificationUpdateRequest`) 또는 명시 메서드(`updateMorningNotification`)로 계약 재정의
  2. Platform의 `NotificationType`은 내부 구현 상세로 축소
  3. ViewModel 테스트 대역이 Domain 계약만 알도록 스텁 정리

## TD-020: NotiSettingView가 시스템 설정 이동을 직접 호출

- Status: Closed (2026-02-16)
- Resolution:
  - `SystemSettingsOpening` 경계를 추가하고 `NotiSettingViewModel`에 주입하도록 변경했습니다.
  - `NotiSettingView`는 `viewModel.openSystemSettings()` 액션 전달만 수행하도록 정리했습니다.
  - `NotiSettingViewModelTests`에 시스템 설정 이동 위임 테스트를 추가했습니다.
- Context:
  - `NotiSettingView`가 버튼 액션에서 `SystemSettingsManager.openSettings`를 직접 호출합니다.
- Risk:
  - Presentation 계층이 플랫폼 동작을 직접 소유해 경계 규칙이 약화됩니다.
  - 시스템 설정 이동 로직의 테스트 대체 지점이 부족해집니다.
- Target Layer:
  - `Presentation -> UseCase/Service` 경유 호출 경계
- Trigger Condition:
  - 알림 설정 화면 리팩터링, 시스템 설정 진입 정책 확장 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/NotiSetting/NotiSettingView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/System/SystemSettingsManager.swift`
- Suggested Follow-up:
  1. 시스템 설정 이동을 ViewModel 주입 서비스(`SystemSettingsOpening` 등)로 위임
  2. View는 액션 전달만 수행하고 실제 호출은 서비스 구현에서 처리

## TD-021: BookSearch만 ObservableObject 패턴으로 남아 상태관리 경로가 이원화됨

- Status: Closed (2026-02-16)
- Resolution:
  - `BookSearchViewModel`을 `@Observable`로 전환하고 `ObservableObject/@Published` 경로를 제거했습니다.
  - `BookSearchView`를 `@State` 소유 패턴으로 정렬하고 하위 뷰 `@ObservedObject` 사용을 제거했습니다.
  - 기존 `BookSearchViewModelTests` 회귀를 통과해 동작 동일성을 확인했습니다.
- Context:
  - 대부분 ViewModel은 `@Observable` 기반인데, `BookSearchViewModel`만 `ObservableObject/@Published` + `@StateObject` 경로를 사용합니다.
- Risk:
  - 상태 업데이트/수명주기 규칙이 기능별로 달라 유지보수 비용과 온보딩 비용이 증가합니다.
  - 향후 공통 상태 처리 규칙 추가 시 예외 경로가 늘어납니다.
- Target Layer:
  - `Presentation/ViewModel` 상태관리 패턴 표준화 경계
- Trigger Condition:
  - BookSearch 기능 확장, Observation 전환 작업 착수 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookSearchView.swift`
- Suggested Follow-up:
  1. `BookSearchViewModel`을 `@Observable`로 정렬하거나, 예외 유지 시 명시적 ADR/가이드로 이유를 문서화
  2. View 바인딩 방식(`@State`/`@Bindable`)을 다른 화면과 동일 패턴으로 정렬

## TD-022: 계층 경계가 컴파일 단에서 강제되지 않음(단일 앱 타깃)

- Status: Partial (2026-02-17, Stage 1 complete)
- Resolution (Stage 1):
  - `.swiftlint.yml`에 custom rule 3종을 추가해 경계 위반을 정적 검사로 차단했습니다.
    1. `Presentation/ViewModel`의 `...Managing/...Providing/...Storing/...Opening` 직접 의존 금지
    2. `Presentation/View`의 `any ...Using` 직접 의존 금지
    3. `Presentation/View`의 `@Environment(AppDependencies.self)` 금지
  - 검색 기반 Acceptance 검증에서 3개 패턴 모두 0건을 확인했습니다.
- Context:
  - 현재 프로젝트는 앱 타깃 하나에 Domain/Data/Platform/Presentation을 함께 컴파일합니다.
  - 경계 위반이 발생해도 컴파일 단계에서 차단되지 않고 리뷰/규약 의존으로만 통제됩니다.
- Risk:
  - 동일한 경계 누수가 반복될 가능성이 높고, 구조 품질이 리뷰 역량에 과의존합니다.
  - 장기적으로 모듈 변경 시 영향 범위가 넓어지고 회귀 비용이 증가합니다.
- Target Layer:
  - 빌드 타깃/모듈 경계(예: Domain/Data/Platform 분리) 설계
- Trigger Condition:
  - 중대 아키텍처 리팩터링, 모듈화 예산 확보, 빌드 시간/경계 이슈 반복 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/.swiftlint.yml`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj/project.pbxproj`
- Suggested Follow-up:
  1. 2단계로 Domain 모듈 분리 가능성 검증 스파이크(빌드/테스트 영향 포함)
  2. 단계별 모듈화 로드맵(분리 순서, public API 경계, 마이그레이션 기준) 문서화

## TD-023: 검색 완료 중복 탭 시 등록 마법사 단계 건너뛰기

- Status: Closed (2026-02-17)
- Resolution:
  - `BookSearchViewModel`에 `isCompletingSelection`, `completeSelection()`을 도입해 in-flight 중복 완료 요청을 ViewModel 경계에서 차단했습니다.
  - `BookSearchView` 완료 버튼 경로를 `completeSelection()` 단일 성공 경로로 정리하고, 요청 중 버튼 비활성/비활성 스타일을 반영했습니다.
  - `BookSearchViewModelTests`에 완료 성공/선택 없음/중복 요청 무시 케이스를 추가하고, `BookSearchProviderStub`에 지연/게이트 훅을 확장해 경쟁 조건 회귀를 고정했습니다.
- Context:
  - `BookSearchView`의 상단 "완료" 버튼은 탭마다 새로운 `Task`를 생성하고, 완료 시점마다 `pageModel.nextPage()`를 호출합니다.
  - in-flight 요청 여부를 제어하는 상태(`isSubmitting`)가 없어 네트워크 지연 구간에서 연속 탭이 누적될 수 있습니다.
- Risk:
  - `currentPage`가 1 -> 2 -> 3 이상으로 연속 증가해 페이지 입력 단계를 건너뛰거나 의도하지 않은 단계로 진입할 수 있습니다.
  - 등록 플로우의 값 전이 순서가 깨져 사용자 입력 복원/검증 UX 일관성이 저하됩니다.
- Target Layer:
  - `Presentation/View/BookSetting` 등록 마법사 액션 전이 경계
- Trigger Condition:
  - 검색 API 지연, 중복 탭 제보, 등록 플로우 단계 이탈 이슈 발생 시 즉시 우선 대응
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookSearchView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSettingPageModel.swift`
- Suggested Follow-up:
  1. `BookSearchViewModel` 또는 View 계층에 요청 중 상태를 도입해 완료 버튼 중복 탭을 차단
  2. `pageModel.nextPage()`를 단일 성공 경로에서 1회만 실행하도록 보장
  3. 지연 응답 조건에서 중복 탭 회귀 시나리오(단위/통합/UI 중 최소 1개) 추가

## TD-024: BookSettingPageModel 단계 상한 미보장으로 빈 화면 경로 유입 가능

- Status: Closed (2026-02-17)
- Resolution:
  - `BookSettingPageModel`에 `minimumPage = 1`, `maximumPage = 5` 상수를 도입하고 `nextPage()/previousPage()`를 clamp 기반으로 변경했습니다.
  - `BookSettingPageModelTests`를 추가해 초기값/하한/상한 회귀를 단위 테스트로 고정했습니다.
- Context:
  - `BookSettingPageModel.nextPage()`는 `currentPage += 1`로 상한 없이 증가합니다.
  - `BookSettingsManagerView.pageView`는 정의된 enum 값 외에는 `default: EmptyView()`로 처리합니다.
- Risk:
  - 반복 호출 또는 비정상 액션 누적으로 `currentPage`가 범위를 벗어나면 사용자가 빈 화면 상태를 마주할 수 있습니다.
  - 단계형 UX 상태 머신이 숫자 오염에 취약해져 재현성 낮은 화면 이탈이 발생할 수 있습니다.
- Target Layer:
  - `Presentation/ViewModel` 단계 상태 머신 경계
- Trigger Condition:
  - 단계 전이 로직 수정, 비동기 액션 추가, 등록 플로우 회귀 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSettingPageModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`
- Suggested Follow-up:
  1. `nextPage()`에 `bookSettingDone` 상한 clamp 적용
  2. 단계 enum 기반 전이 함수로 경계값을 타입 수준에서 제한
  3. 단계 상한/하한 회귀 테스트 추가

## TD-025: 검색 응답 경쟁으로 최신 검색 결과가 이전 질의로 역전될 수 있음

- Status: Open
- Context:
  - `BookListView.requestSearchBooks()`는 호출마다 새 `Task`를 생성하고 이전 요청을 취소하지 않습니다.
  - `BookSearchViewModel.searchBooks(query:)`는 응답 완료 순서 검증 없이 `books`를 즉시 갱신합니다.
- Risk:
  - 느린 이전 질의 응답이 나중에 도착하면 최신 질의 결과를 덮어써 화면이 과거 검색 상태로 되돌아갈 수 있습니다.
  - 사용자는 검색 입력과 목록 결과가 불일치한 UI를 경험할 수 있습니다.
- Target Layer:
  - `Presentation/ViewModel` 검색 상태 전이/동시성 제어 경계
- Trigger Condition:
  - 검색 API 지연, 연속 검색 UX 개선, 검색 결과 불일치 제보 발생 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookListView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
- Suggested Follow-up:
  1. 검색 Task 취소 또는 request-id(epoch) 검증으로 latest-only 반영 정책을 강제
  2. 필요 시 debounce 패턴을 도입해 연속 질의의 불필요한 요청을 축소
  3. out-of-order 응답 회귀 테스트를 추가

## TD-026: 완료 처리 진행 중 선택 변경 허용으로 전달 값 불일치 가능

- Status: Open
- Context:
  - `completeSelection()`은 시작 시점의 `selectedBook`을 캡처해 페이지 조회를 수행합니다.
  - 요청 진행 중에도 `BookRowView` 탭으로 `selectedBook`을 계속 변경할 수 있습니다.
- Risk:
  - 사용자가 완료 후 즉시 다음 단계에서 보는 값과 직전 화면에서 최종 선택했다고 인지한 값이 달라질 수 있습니다.
  - 비동기 완료 시점에 따라 선택/페이지 값 정합성이 흔들려 재현성 낮은 UX 이슈가 발생할 수 있습니다.
- Target Layer:
  - `Presentation/View/BookSetting` 선택 상호작용 잠금 정책
- Trigger Condition:
  - 완료 액션 네트워크 지연, 선택값 불일치 제보, 등록 플로우 정합성 점검 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookRowView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookSearchView.swift`
- Suggested Follow-up:
  1. 완료 처리 중 목록 선택 상호작용을 잠그거나, ViewModel에서 선택 변경을 차단
  2. 완료 시작 시 선택 스냅샷과 UI 표시값 정합성을 유지하는 정책을 명시
  3. 완료 in-flight 중 선택 변경 회귀 테스트를 추가

## TD-027: 미완독 종료 시 완료일 기준 회귀(목표 종료일 미반영)

- Status: Closed (2026-02-17, 실행일 완료일 정책 확정)
- Resolution:
  - 미완독 종료/완독 저장 경로의 완료일은 `todayProvider.today()`(실행일)로 확정했습니다.
  - 회귀 이슈가 아니라 제품 정책으로 분류하고 관련 테스트/제품 문서를 동기화했습니다.
- Context:
  - `UnfinishReadingViewModel.completeBook(_:)`는 완료 처리 시 `id`, `review`만 전달하고 완료일 전달 경로가 없습니다.
  - `BookCompletionUseCase.completeBook(id:review:)`는 내부에서 `todayProvider.today()`를 완료일로 고정 해상합니다.
- Risk:
  - 정책 문서와 구현/테스트가 분리되면 동일 논의가 반복될 수 있습니다.
- Target Layer:
  - `Domain/UseCase` 완료 처리 계약(`BookCompletionUsing`) + `Presentation/ViewModel` 미완독 종료 액션 경계
- Trigger Condition:
  - 미완독 종료 UX 조정, 완료일 표시 정책 변경, 기간 통계 해석 이슈 제보 발생 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/UnfinishReadingViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Domain/UseCase/BookManagementUseCasesCompletionAndPlanTests.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/product/current-feature-spec.md`
- Suggested Follow-up:
  1. 정책 변경 요구가 생길 경우(목표 종료일 보존 모드) 별도 ADR/feature flag로 다룰 것

## TD-028: 앱 부트스트랩 마이그레이션 prewarm 실패 관측성 부족

- Status: Closed (2026-02-17, 구조적 진단 로깅 반영)
- Resolution:
  - `MigrationDiagnosticLogging` 경계를 추가하고 `SystemMigrationDiagnosticLogger(os.Logger)` 구현을 도입했습니다.
  - `AppDependencies` prewarm 실패 경로를 `print`에서 구조적 로그 호출로 교체했습니다.
  - `SwiftDataBookRepo` migration fetch/settings_backfill/record_key_migration 실패를 동일 이벤트 스키마로 기록하도록 정리했습니다.
  - 실패 이벤트에 `stage`, `migrationKeyScope`, `didMutate`, `errorType`, `message`를 포함하도록 고정했습니다.
- Context:
  - 앱 초기화(`AppDependencies`)에서 `prewarmReadingRecordKeyMigrationIfNeeded()` 실행 실패를 빈 `catch`로 무시합니다.
  - 재시도 경로가 있더라도 초기 실패 신호가 남지 않아 장애 원인 추적 근거가 부족합니다.
- Risk:
  - 로깅은 확보됐지만 analytics 파이프라인 연동/대시보드화는 TD-029 범위입니다.
- Target Layer:
  - `App` 부트스트랩 초기화 관측성/진단 로깅 경계
- Trigger Condition:
  - 마이그레이션 정책 변경, 앱 부팅 시 데이터 이상 제보, 초기화 진단 강화 작업 착수 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/MigrationDiagnosticLogging.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
- Suggested Follow-up:
  1. TD-029 범위에서 analytics 파이프라인으로 필요한 진단 이벤트 전달 여부를 결정

## TD-029: Presentation의 Firebase Tracking 직접 호출 경계 분리 필요

- Status: Open
- Context:
  - 다수의 View가 `Tracking.Screen.*.setTracking()`을 직접 호출하고, `Tracking` 구현은 `FirebaseAnalytics`에 직접 결합되어 있습니다.
  - 관측 이벤트 정책 변경 시 Presentation 레이어를 반복 수정해야 합니다.
- Risk:
  - Analytics SDK 변경/이벤트 스키마 변경 시 영향 범위가 화면 코드로 확산됩니다.
  - 테스트 대역 주입이 어려워 이벤트 회귀를 정적 점검에 의존하게 됩니다.
- Target Layer:
  - `Domain/Service` 추상 이벤트 계약 + `Platform/Analytics` 구현체 분리
- Trigger Condition:
  - GA 이벤트 정책 변경, Analytics SDK 교체, 이벤트 테스트 자동화 요구 발생 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Analytics/Tracking.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/TotalCalendar/MultiBookProgressView.swift`
- Suggested Follow-up:
  1. `Tracking` 호출을 ViewModel/UseCase 경계로 이동할 이벤트 계약 프로토콜을 정의
  2. `Platform/Analytics`에서 Firebase 의존을 구현체로 한정
  3. 핵심 이벤트 2~3개를 대상으로 대역 주입 가능한 회귀 테스트 경로를 추가

## Recommended Execution Order

1. TD-015: 야간 알림 시간 상수 유효 범위 이탈 (P1)
2. TD-010: 알림 일괄 등록 권한 체크 중복 제거 (P2)
3. TD-025: 검색 응답 경쟁으로 최신 결과가 역전되는 문제 (P2)
4. TD-026: 완료 in-flight 중 선택 변경으로 값 불일치 가능 (P2)
5. TD-007: 날짜 키 시맨틱/타입 경계 후속 정리 (P2, Partial)
6. TD-022: 컴파일 단 경계 강제 2단계(모듈화 스파이크/분리 착수) (P3)
7. TD-029: Analytics 경계 분리 (P3)

완료(2026-02-16):
- TD-018, TD-017, TD-019, TD-020, TD-016, TD-003, TD-021
완료(2026-02-17):
- TD-001, TD-011, TD-006, TD-004, TD-022(Stage 1), TD-023, TD-024, TD-027, TD-028
