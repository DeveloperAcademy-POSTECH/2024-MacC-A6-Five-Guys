# Tech Debt Tracker

이 문서는 아키텍처/도메인 경계 정리 과정에서 아직 해결되지 않은 기술 부채를 추적합니다.
현재 기준으로 `Open`/`Partial` 항목만 유지하며, `Closed` 항목 상세는 제거했습니다.
완료 이력은 Git 히스토리와 기존 커밋 기록으로 추적합니다.

## Active Review Sync (2026-02-18)

- 본 문서는 Active Debt 기준으로 재정리되었습니다.
- 최근 반영 매핑:
  - Presentation 경쟁 조건 후속 -> `TD-025`, `TD-026`
  - Date 정책 후속 잔여 -> `TD-007 (Partial)`
  - 독서 UseCase 흐름 리팩토링 유예 -> `TD-031`
  - UI 알럿 인지 E2E 검증 유예 -> `TD-032`
  - Navigation back 버튼 UI 회귀 자동화 유예 -> `TD-033`
- 코드 재검증 기준:
  - 본 문서에 남은 항목은 2026-02-18 코드 리뷰 기준 미해결(`Open`/`Partial`)만 포함합니다.
  - 해결 완료 항목은 본 문서에서 제거했고, 이력은 Git 히스토리로 추적합니다.

## TD-007: 날짜 키 시맨틱/타입 분리 부족 + 키 포맷 타임존 명시 누락

- Status: Partial (2026-02-17)
- Fix Required: Remaining
- Context:
  - `ReadingRecord.timeZoneID` 저장과 settings LocalDate key 전환까지는 반영되었으나, 호출부 typed key 수렴과 legacy `Date` 제거 마이그레이션이 남아 있습니다.
  - 저장 딕셔너리(`[String: ReadingRecord]`) 호환 경로를 유지 중이라 raw string 직접 접근 재유입 위험이 남아 있습니다.
- Risk:
  - key 접근 경계가 분산되면 정책 변경 시 회귀 위험이 증가합니다.
  - `Date`/`DateKey` 병행 필드 유지로 dual-write drift 가능성이 남습니다.
- Target Layer:
  - `Domain` value object(`ReadingDateKey`) 기반 key 경계 단일화
  - settings legacy `Date` 제거 마이그레이션
- Trigger Condition:
  - 날짜 키 버그 재발, 저장 포맷 정책 변경, cross-timezone 요구사항 반영
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingRecord.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/UserSettings.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0005-settings-localdate-source-of-truth.md`
- Suggested Follow-up:
  1. `[String: ReadingRecord]` 호출부에 typed key adapter 추가
  2. `UserSettings` legacy `Date` 필드 제거용 후속 스키마 마이그레이션 분리
  3. 조건부 재보정 스캔 비용/빈도 운영 로그 기반 재평가

## TD-010: 알림 일괄 등록 시 권한 체크 중복 호출

- Status: Open
- Context:
  - `NotificationManager.setupAllNotifications`에서 morning/night 경로가 각각 권한 확인을 수행합니다.
- Risk:
  - 권한 상태 조회 중복으로 성능/결정성 저하 가능성이 있습니다.
- Target Layer:
  - `Platform/Notification` 권한 체크 단일화
- Trigger Condition:
  - 알림 등록 정책 변경, 성능 점검
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift`
- Suggested Follow-up:
  1. `setupAllNotifications` 진입 시 권한 체크 1회 수행
  2. 권한 실패 조기 반환 계약 테스트 추가

## TD-015: 야간 알림 시간 상수 유효 범위 이탈

- Status: Open
- Context:
  - `.night` 시간 상수가 `(24, 0)`으로 설정되어 `DateComponents.hour` 유효 범위(0...23)를 벗어납니다.
- Risk:
  - 야간 알림이 다음날로 밀리거나 무효 처리될 수 있습니다.
- Target Layer:
  - `Platform/Notification` 시간 정책 상수
- Trigger Condition:
  - 알림 정책 변경, 야간 알림 회귀 제보
- Priority:
  - P1
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationType.swift`
- Suggested Follow-up:
  1. `.night`를 유효 범위 값으로 교체(예: `23:00`)
  2. 야간 시간 유효성 테스트 추가

## TD-022: 계층 경계가 컴파일 단에서 강제되지 않음(단일 앱 타깃)

- Status: Partial (2026-02-17, Stage 1 complete)
- Context:
  - Stage 1(custom swiftlint guard)은 완료됐지만, 실제 모듈 분리 기반 컴파일 경계 강제는 미완료입니다.
- Risk:
  - 경계 위반 통제가 리뷰/규약에 과의존합니다.
- Target Layer:
  - 빌드 타깃/모듈 경계(`Domain/Data/Platform` 분리) 설계
- Trigger Condition:
  - 모듈화 예산 확보, 경계 누수 반복
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/.swiftlint.yml`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj/project.pbxproj`
- Suggested Follow-up:
  1. Domain 모듈 분리 가능성 스파이크
  2. 단계별 모듈화 로드맵 문서화

## TD-025: 검색 응답 경쟁으로 최신 검색 결과가 이전 질의로 역전될 수 있음

- Status: Open
- Context:
  - `BookListView` 요청이 이전 Task 취소 없이 누적되고, `BookSearchViewModel`이 완료 순서 검증 없이 결과를 반영합니다.
- Risk:
  - 이전 질의 응답이 최신 결과를 덮어써 UI 불일치가 발생할 수 있습니다.
- Target Layer:
  - `Presentation/ViewModel` 검색 동시성 제어 경계
- Trigger Condition:
  - 검색 지연/결과 불일치 제보
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookListView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
- Suggested Follow-up:
  1. Task 취소 또는 request-id 기반 latest-only 반영
  2. out-of-order 응답 회귀 테스트 추가

## TD-026: 완료 처리 진행 중 선택 변경 허용으로 전달 값 불일치 가능

- Status: Open
- Context:
  - `completeSelection()` 실행 중에도 `selectedBook`이 변경될 수 있습니다.
- Risk:
  - 사용자 인지 선택값과 다음 단계 전달값이 어긋날 수 있습니다.
- Target Layer:
  - `Presentation/View/BookSetting` 선택 잠금 정책
- Trigger Condition:
  - 완료 액션 지연, 값 불일치 제보
- Priority:
  - P2
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookRowView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookSearchView.swift`
- Suggested Follow-up:
  1. 완료 in-flight 중 선택 변경 잠금
  2. 선택값 정합성 회귀 테스트 추가

## TD-029: Presentation의 Firebase Tracking 직접 호출 경계 분리 필요

- Status: Open
- Context:
  - 다수 View가 `Tracking`을 직접 호출하고 Firebase 구현과 결합돼 있습니다.
- Risk:
  - SDK/이벤트 스키마 변경 시 영향이 화면 코드로 확산됩니다.
- Target Layer:
  - `Domain/Service` 추상 이벤트 계약 + `Platform/Analytics` 구현 분리
- Trigger Condition:
  - Analytics SDK 교체, 이벤트 테스트 자동화 요구
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Platform/Analytics/Tracking.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/TotalCalendar/MultiBookProgressView.swift`
- Suggested Follow-up:
  1. UseCase/ViewModel 경유 이벤트 계약 정의
  2. Firebase 결합을 Platform 구현체 내부로 제한
  3. 핵심 이벤트 회귀 테스트 경로 추가

## TD-031: 독서 UseCase 내부 분기 집중으로 흐름 추적 난이도가 높음

- Status: Open
- Context:
  - `UseCase-First` 경계는 유지되고 있으나, `RecordReadingUseCase.execute`와 `ReadingScheduleCalculator.applyTodayReading/adjustFutureTargets` 내부 분기 집중도가 높습니다.
  - 이번 릴리스는 구조 리팩토링을 유예하고 behavior를 유지합니다.
- Risk:
  - F-07 정책 확장 시 분기 누적으로 회귀 위험이 커질 수 있습니다.
- Target Layer:
  - `Domain/UseCase/BookManagement` + `Domain/Calculator` 내부 메서드 책임 분리
- Trigger Condition:
  - F-07 정책 변경, 분기 버그 재발, 추가 정책 분기 도입
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/decisions/adr-0002-usecase-first-boundary.md`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/product/current-feature-spec.md`
- Deferred Decision (2026-02-18):
  - 이번 릴리스에서는 공개 인터페이스와 동작을 유지하고 구조 분리는 후속으로 수행
- Suggested Follow-up:
  1. `RecordReadingUseCase.execute`를 단계별 private helper로 분리
  2. `applyTodayReading`를 단계별 private helper로 분리
  3. `adjustFutureTargets`를 완독/미완독 내부 경로로 분리
  4. 리팩토링 전후 `BookManagementUseCasesDailyReadingTests`와 `ReadingScheduleCalculator*Tests` 동등 통과로 behavior-preserving 검증
  5. 공개 인터페이스(`DailyReadingUsing`, `ReadingPlanUsing`, `ReadingLibraryUsing`, `BookCompletionUsing`, `RecordReadingResult`) 유지

## TD-032: BookSearch 설정 Alert 사용자 인지 경로의 UITest 부재

- Status: Open
- Context:
  - BookSearch 설정 누락(`missingAPIKey`) 인지 경로는 ViewModel/Domain/Provider 테스트로 검증되지만, 화면 단 사용자 가시 흐름(E2E UI)은 자동화되지 않았습니다.
  - 이번 사이클은 UITest 타깃 신설 없이 Swift Testing 도메인 회귀를 우선 적용합니다.
- Risk:
  - Alert 바인딩/프레젠테이션 회귀가 발생해도 현재 테스트 세트로는 UI 표시 실패를 즉시 감지하지 못할 수 있습니다.
- Target Layer:
  - `Presentation/View` 사용자 인지 흐름(UI Alert 노출) E2E 검증 경계
- Trigger Condition:
  - 릴리스 전 UI 회귀 점검 강화가 필요하거나 UITest 인프라가 준비될 때
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSearch/BookSearchView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Domain/UseCase/BookSearchUseCaseTests.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Presentation/ViewModel/BookSearchViewModelTests.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Platform/BookSearch/AladinBookSearchProviderTests.swift`
- Deferred Decision (2026-02-18):
  - 이번 사이클은 Swift Testing 도메인/뷰모델 회귀로 유지하고 UITest는 후속으로 분리합니다.
- Suggested Follow-up:
  1. `FiveGuyesUITests` 타깃 신설 후 BookSearch 설정 누락 시 Alert 노출 시나리오 E2E 추가
  2. E2E에서 설정 누락/일반 오류 경로를 분리 검증
  3. CI 파이프라인에 UITest 스모크 경로를 선택적으로 연결

## TD-033: customNavigationBackButton backBehavior UI 회귀 자동화 부재

- Status: Open
- Context:
  - `customNavigationBackButton`의 `backBehavior(.pop/.none)` 분기는 코드와 coordinator 단위 테스트로는 검증되지만, 실제 버튼 탭 기반 UI 시나리오 자동화는 없습니다.
  - 이번 사이클은 UITest 타깃 신설 없이 문서/단위 테스트 경계 정렬을 우선 적용합니다.
- Risk:
  - 버튼 바인딩/화면 이동 분기 회귀가 발생해도 단위 테스트만으로는 실제 UI 탭 동작 실패를 즉시 감지하지 못할 수 있습니다.
- Target Layer:
  - `Presentation/View` back 탭 사용자 흐름 E2E 검증 경계
- Trigger Condition:
  - back 동작 회귀 제보, 릴리스 전 UI 회귀 점검 강화 필요, UITest 인프라 준비 시
- Priority:
  - P3
- Current Evidence:
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/Shared/CustomBackButton.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionReviewView.swift`
  - `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyesTests/Presentation/ViewModel/NavigationCoordinatorTests.swift`
- Deferred Decision (2026-02-18):
  - 이번 사이클은 UITest를 범위에서 제외하고 문서화 + 단위 테스트 경계로 유지한다.
- Suggested Follow-up:
  1. `popToRootOnBack=true` 경로에서 back 1회 탭 시 root 1회 복귀를 E2E로 검증
  2. 일반 경로에서 back 1회 탭 시 one-step pop을 E2E로 검증
  3. 더블 탭 시 동일 화면 중복 진입 차단을 E2E로 검증

## Recommended Execution Order

1. TD-015: 야간 알림 시간 상수 유효 범위 이탈 (P1)
2. TD-010: 알림 일괄 등록 권한 체크 중복 제거 (P2)
3. TD-025: 검색 응답 경쟁으로 최신 결과 역전 (P2)
4. TD-026: 완료 in-flight 중 선택 변경 불일치 (P2)
5. TD-007: 날짜 키 시맨틱/타입 경계 잔여 정리 (P2, Partial)
6. TD-022: 컴파일 단 경계 강제 2단계(모듈화) (P3, Partial)
7. TD-031: 독서 UseCase 내부 흐름 리팩토링 유예 항목 (P3)
8. TD-029: Analytics 경계 분리 (P3)
9. TD-032: BookSearch 설정 Alert 사용자 인지 경로 UITest 보강 (P3)
10. TD-033: Navigation back 버튼 분기 UI 회귀 자동화 보강 (P3)
