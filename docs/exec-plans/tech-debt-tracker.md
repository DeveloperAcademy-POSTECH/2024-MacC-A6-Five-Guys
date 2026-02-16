# Tech Debt Tracker

이 문서는 아키텍처/도메인 경계 정리 과정에서 당장 전면 수정하지 못한 기술 부채를 추적하기 위한 기록입니다.

## TD-001: 하루 경계(04:00~03:59) 규칙의 전역 강제 부족

- Status: Open (Production path aligned; preview/sample paths remain)
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
  1. `Date` extension의 `toAdjustedYearMonthDayString` 경유 정책을 provider 또는 domain policy로 단일화

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
  - `SwiftDataBookRepo` fetch 경계에 1회 호환 마이그레이션을 도입해 legacy 저장 키를 정책 키로 정리했습니다.
  - 마이그레이션 구현은 repository 내부 구조체(`ReadingRecordKeyMigrationV1`) + `UserDefaults` 직접 접근으로 경량화해 추후 삭제 경계를 repository 내부로 고정했습니다.
  - 완료 플래그는 앱/스토어/버전 스코프 키를 기본으로 사용하고, 기존 단일 키는 fallback 읽기 후 승격합니다.
  - 앱 시작 시 prewarm을 선실행하고 fetch 경계 호출은 fallback 재시도 경계로 유지합니다.
  - 남은 범위는 raw string 저장 경계 축소, `toAdjustedYearMonthDayString` 호출 경계 제한, 글로벌 타임존 UX 확장입니다.
- Context:
  - 저장/조회 키 생성/파싱은 `ReadingDateKey` 타입으로 통일했습니다.
  - `DayBoundaryProviding.adjustedDayKey(from:)`는 `ReadingDateKey`를 반환하도록 변경해 정책 키 경계를 타입화했습니다.
  - 저장 호환성은 repository 레이어 1회 마이그레이션으로 보정합니다(`lastReadDate` anchor + safe shift).
  - `toAdjustedYearMonthDayString()`는 여전히 `Date` 확장 API로 남아 있어, 장기적으로는 도메인 정책 경계로 더 수렴할 필요가 있습니다.
  - 글로벌 사용자 UX를 위해서는 한국 고정 정책을 설정 가능 정책으로 확장해야 하지만, 이번 범위에서는 의도적으로 제외했습니다.
- Risk:
  - 현재 런타임 키 불일치 리스크는 감소했지만, 저장 모델이 문자열 키를 직접 보유하므로 호출부에서 `.rawValue` 남용이 재발할 수 있습니다.
  - 정책 반영 날짜 API(`toAdjustedYearMonthDayString`)가 범용 확장에 남아 있어 경계 우회 가능성이 있습니다.
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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Calendar+Extension.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
- Suggested Follow-up:
  1. 저장 모델(`[String: ReadingRecord]`) 호출부에 typed key adapter를 추가해 raw string 직접 접근을 축소
  2. `toAdjustedYearMonthDayString` 호출 경계를 `ReadingDateProviding`/`DayBoundaryProviding`로 제한
  3. 글로벌 UX 확장 시 day-boundary 타임존 정책을 사용자/지역 기반으로 분리하고 전환 전략(마이그레이션 포함)을 별도 설계
  4. legacy 데이터 재유입 가능성이 생기면 전역 1회 플래그를 버전드/조건부 마이그레이션으로 전환

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
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
- Suggested Follow-up:
  1. 홈 진입 오케스트레이션 전용 `...Using` 경계 분리 검토
  2. ReadingLibrary 경계는 조회/삭제/재스케줄 도메인 책임으로 다시 축소

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

- Status: Open
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

- Status: Open
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

## Recommended Execution Order

1. TD-015: 야간 알림 시간 상수 유효 범위 이탈 (P1)
2. TD-010: 알림 일괄 등록 권한 체크 중복 제거 (P2)
3. TD-011: ReadingLibraryUseCase 책임 재분리 (P2)
4. TD-017: 페이지 설정 화면 복원 로직 결함 (P2)
5. TD-016: 도서 검색 URL 조합의 인코딩/응답 검증 부족 (P2)
6. TD-001: 하루 경계 규칙 프리뷰/샘플 경계 정리 (P2)
7. TD-004: DayBoundary 직접 참조 제거 (P2)
8. TD-007: 날짜 키 시맨틱/타입 경계 후속 정리 (P2, Partial)
9. TD-006: ViewModel 조립 책임 상향 (P3)
10. TD-003: 프레젠테이션 계산 로직 수렴 (P3)
