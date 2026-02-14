# Tech Debt Tracker

이 문서는 아키텍처/도메인 경계 정리 과정에서 당장 전면 수정하지 못한 기술 부채를 추적하기 위한 기록입니다.

## TD-001: 하루 경계(04:00~03:59) 규칙의 전역 강제 부족

- Status: Open (Partial mitigation applied)
- Context:
  - `DayBoundaryProviding`/`ReadingDateProviding`를 도입해 핵심 실행 경계(Main/Daily/Completion/ReadingPlan)는 도메인 기준 오늘(`today`)을 내부 해상하도록 정리했습니다.
  - 하지만 일부 캘린더/프리뷰 경로는 여전히 UseCase가 아닌 UI 계층에서 today를 직접 조회합니다.
- Risk:
  - 동일 날짜라도 호출 경로별로 해석 기준이 달라지면 알림/캘린더/D-day 표시 불일치가 재발할 수 있습니다.
- Target Layer:
  - `Domain/Service/ReadingDateProviding.swift` 단일 provider 경계 사용
- Trigger Condition:
  - 날짜 경계(03:59/04:00) 관련 버그 또는 날짜 파라미터 추가 시 즉시 우선 적용
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDatePicker/CalendarGridView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDatePicker/ReadingDatePickerView.swift`

## TD-002: SwiftData 모델의 도메인 계산 래퍼 제거

- Status: Open
- Context: `ReadingProgress`(SwiftData 모델)에 도메인 계산 래퍼 메서드가 남아 있습니다.
- Risk: 장기적으로 데이터 모델과 도메인 모델의 책임 경계가 다시 흐려질 수 있습니다.
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`
- Current Mitigation:
  - 래퍼 내부 구현은 도메인 모델(`FGReadingProgress`, `FGUserSetting`) 위임으로 변경해 계산 규칙 중복은 제거했습니다.
- Suggested Follow-up:
  1. 실제 호출 지점을 도메인 모델 API로 직접 전환합니다.
  2. 더 이상 필요 없는 SwiftData 래퍼 메서드를 삭제해 데이터 모델을 순수 저장 모델로 제한합니다.

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
  - P2
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

- Status: Open
- Fix Required: Yes
- Decision:
  - `toYearMonthDayString()`의 타임존 명시 누락은 환경 의존적 키 불일치 가능성이 있어 수정 대상입니다.
  - 즉시 장애가 재현되지 않더라도, 다음 도메인 날짜/키 정비 작업에서 우선 반영해야 합니다.
- Context:
  - `Date+Extension`의 `toYearMonthDayString()`는 저장/조회 키 역할로 광범위하게 사용됩니다.
  - `toAdjustedYearMonthDayString()`/`adjustedDate()`는 04:00 정책 의미를 갖지만, `Date` 확장 메서드 형태라 호출부에서 시맨틱이 혼재되기 쉽습니다.
  - 현재 `toYearMonthDayString()` 내부 `DateFormatter`에 타임존이 명시되지 않아, `Calendar.app`(Asia/Seoul 고정) 기반 계산과 키 생성 타임존이 어긋날 여지가 있습니다.
- Risk:
  - 저장 키 생성 기준이 실행 환경 타임존에 따라 달라져 데이터 조회/비교 불일치가 발생할 수 있습니다.
  - 정책 반영 키와 일반 키가 같은 `String` 타입으로 노출되어 잘못된 경계에서 오용될 수 있습니다.
- Target Layer:
  - `Domain` 타입으로 키 시맨틱 고정 (예: `ReadingDayKey`, `ReadingDate` value object/래퍼)
  - 키 생성 경로 단일화 (`ReadingDateProviding` 또는 정책 타입 경유)
- Trigger Condition:
  - 날짜 키 관련 버그 발생, 저장 포맷/정책 변경, cross-timezone 요구사항 반영 시
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Calendar+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
- Suggested Follow-up:
  1. 키 생성용 formatter 타임존을 `Calendar.app.timeZone`으로 명시
  2. 정책 키/일반 키를 분리하는 래퍼 타입 도입 (`Date` 상속 대신 value object)
  3. `toAdjustedYearMonthDayString`/`adjustedDate`의 호출 경계를 도메인 정책 계층으로 제한
