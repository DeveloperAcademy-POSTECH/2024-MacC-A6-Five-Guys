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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`
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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Resources/Extensions/Date+Extension.swift`
- Suggested Follow-up:
  1. `ReadingProgress`의 `DayBoundary.shared.adjustedDayKey/adjustedNow` 직접 호출을 provider 경유로 전환
  2. `Date` extension의 `toAdjustedYearMonthDayString/adjustedDate` 경유 정책을 provider 또는 domain policy로 단일화
