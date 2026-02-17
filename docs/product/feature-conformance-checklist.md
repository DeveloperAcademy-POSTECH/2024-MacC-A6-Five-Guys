# 확정 명세 기준 코드 적합성 체크리스트 (2026-02-18)

## 판정 기준

본 체크리스트는 아래 2개 문서를 조합한 계약을 기준으로 판정한다.

1. 기본 계약: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/product/past/main-feature-baseline.md`
2. 확정 오버라이드: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/product/past/current-diff-from-main.md` 의 `최종 확정 결과 (2026-02-17)`

검증 대상 코드:
- 커밋/브랜치: `origin/develop@6a01e21` + `bugfix/no-ticket-prestart-redistribution-docs` working tree
- 시뮬레이터: `iPhone 17 (iOS 26.2)`

## 실행 증거

1. 1차 핵심 세트  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/tmp/fiveguyes-conformance-phase1-20260217.xcresult`
2. 1차 보강 세트 (F-03/F-05/F-06/F-07/F-10 근거 강화)  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/tmp/fiveguyes-conformance-phase1b-20260217.xcresult`
3. 1차 보강 세트 (F-16 날짜 키 정책)  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/tmp/fiveguyes-conformance-phase1c-readingdatekey-20260217.xcresult`
4. 2차 세트 (F-17 저장소 마이그레이션 전체)  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/tmp/fiveguyes-conformance-phase2-swiftdata-20260217.xcresult`
5. 시작일 이전 기록 정책 선택 검증 (계산기/UseCase)  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.18_00-51-22-+0900.xcresult`
6. 전체 회귀 검증  
   - 결과: `TEST SUCCEEDED`  
   - 번들: `/Users/zaehorang/Library/Developer/Xcode/DerivedData/FiveGuyes-bznqavdsjsxffbaoiasvqswdmngq/Logs/Test/Test-FiveGuyes-2026.02.18_00-52-24-+0900.xcresult`

## 공용 인터페이스/API 계약 점검

| 항목 | 계약 | 코드 근거 | 판정 |
| --- | --- | --- | --- |
| `NotificationManaging` | `updateMorningNotification(for:)` 계약 유지 | `FiveGuyes/FiveGuyes/Sources/Domain/Service/NotificationManaging.swift`, `FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift` | PASS |
| `NotificationSettingUsing` | `setNotificationDisabled` / `updateReminderTime` 책임 분리 유지 | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Notification/NotificationSettingUseCase.swift` | PASS |
| `BookCompletionUsing` | `completeBook(id:review:)`가 완료/날짜보정/알림해제 포함 | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift` | PASS |
| `ReadingLibraryUsing` 삭제 정책 | `deleteBook(id:)` 후 남은 책 재설정/없으면 clear | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift` | PASS |
| `BookRepo` 조회 경계 | fetch/get 경로 1회 migration write-back 허용 | `FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift` | PASS |

## 기능 적합성 매트릭스

### 우선 확정 정책 (F-05/F-07/F-08/F-09/F-10/F-11/F-12/F-13/F-14/F-15/F-16/F-17)

| F-ID | 확정 정책 | 코드 위치 | 테스트 케이스 | 판정 | 조치 |
| --- | --- | --- | --- | --- | --- |
| F-08 | 완독 축하 종료일은 `todayProvider.today()` 기준 | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift` | `BookManagementUseCasesCompletionAndPlanTests.testCompletionCelebrationSummary`, `BookManagementUseCasesCompletionAndPlanTests.testCompletionCelebrationSummaryAdjustsBeforeBoundary` | PASS | 없음 |
| F-09 | 완독 소감 trim 후 빈값 차단 + 완료일은 실행일(today) 고정 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/CompletionReviewViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift` | `CompletionReviewViewModelTests.completionReview_emptyReview_showsAlert`, `CompletionReviewViewModelTests.completionReview_newlineOnlyReview_showsAlert`, `BookManagementUseCasesCompletionAndPlanTests.testCompleteBookStoresExecutionDateWhenTargetEndDateIsPast` | PASS | 없음 |
| F-12 | 미완독 종료 시 완료 상태 + 실행일 완료처리(today) + 알림 해제 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/UnfinishReadingViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift` | `UnfinishReadingViewModelTests.unfinishReading_completeBook_success`, `UnfinishReadingViewModelTests.unfinishReading_completeBook_failure`, `BookManagementUseCasesCompletionAndPlanTests.testCompleteBookWithEmptyReviewClearsNotifications`, `BookManagementUseCasesCompletionAndPlanTests.testCompleteBookStoresExecutionDateWhenTargetEndDateIsPast` | PASS | 없음 |
| F-13 | OFF 상태 시간 변경 시 시간 저장만 수행, 재등록 미실행 | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Notification/NotificationSettingUseCase.swift`, `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift` | `NotiSettingViewModelTests.notiSetting_timeChange_whenDisabled_doesNotUpdateNotification` | PASS | 없음 |
| F-14 | 강화된 알림 계산 + 재등록 전 권한/앱토글 재검증 | `FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGReadingProgress+Notification.swift`, `FiveGuyes/FiveGuyes/Sources/Platform/Notification/NotificationManager.swift` | `FGReadingProgressNotificationTests.*`, `NotificationManagerTests.updateMorningNotification_whenCannotSend_doesNotAddRequest` | PASS | 없음 |
| F-15 | 삭제 후 남은 읽는 책 재설정, 없으면 전체 해제 | `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift` | `BookManagementUseCasesQueryAndRegistrationTests.testDeleteBook`, `BookManagementUseCasesQueryAndRegistrationTests.testDeleteBookWithRemainingReadingBookResetsNotification` | PASS | 없음 |
| F-17 | 조회 경로 1회 migration write-back 허용(ReadingRecord key + UserSettings DateKey backfill) | `FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`, `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/UserSettings.swift` | `SwiftDataBookRepoTests.testFetchMigratesLegacyReadingRecordKeys`, `SwiftDataBookRepoTests.testPrewarmMigratesBeforeFetchBoundary`, `SwiftDataBookRepoTests.testMigrationRunsOnlyOnce`, `SwiftDataBookRepoTests.testFetchBackfillsLegacyUserSettingsDateKeys` | PASS | settings legacy `Date` 필드 제거는 별도 마이그레이션 TD로 분리 |

### 나머지 기능 (F-01~F-07/F-10/F-11/F-16)

| F-ID | 기준 요약 | 코드 위치 | 테스트 케이스 | 판정 | 조치 |
| --- | --- | --- | --- | --- | --- |
| F-01 | 앱 시작 시 컨테이너/루트 네비게이션 초기화 | `FiveGuyes/FiveGuyes/Sources/App/FiveGuyesApp.swift`, `FiveGuyes/FiveGuyes/Sources/App/NavigationRootView.swift` | 전용 자동화 테스트 없음 (정적 확인) | PASS(정적) | UI 스모크 테스트 추가 권장 |
| F-02 | 홈 대시보드 상태 분기/재분배/알림 트리거 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift` | `MainHomeViewModelTests.*`, `BookManagementUseCasesQueryAndRegistrationTests.testFetchLibrarySnapshot` | PASS | 없음 |
| F-03 | 검색/선택/총페이지 조회 경로 | `FiveGuyes/FiveGuyes/Sources/Platform/BookSearch/AladinBookSearchProvider.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookSearch/BookSearchUseCase.swift`, `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSearchViewModel.swift` | `AladinBookSearchProviderTests.*`, `BookSearchUseCaseTests.*`, `BookSearchViewModelTests.*` | PASS | 없음 |
| F-04 | 등록 마법사 단계/입력 상태 관리 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSettingPageModel.swift`, `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/BookSettingInputModel.swift` | 전용 자동화 테스트 없음 (정적 확인) | PASS(정적) | 단계 전이/입력 초기화 회귀 테스트 추가 권장 |
| F-05 | 기간/쉬는날 규칙 및 일일 분량 계산(현재 기기 time zone + 04:00 경계, 설정일 LocalDate key source-of-truth) | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/CalendarCellModel.swift`, `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/ReadingDateSettingViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift` | `ReadingDateSettingViewModelTests.*`, `DayBoundaryPolicyTests.dayBoundary_respectsInjectedCalendarTimeZone`, `SwiftDataBookRepoTests.testFetchBackfillsLegacyUserSettingsDateKeys` | PASS | 캘린더 셀 상호작용(UI) 회귀 테스트 추가 권장 |
| F-06 | 등록 완료 시 초기 스케줄/알림 생성 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/FinishGoalViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift` | `FinishGoalViewModelTests.*`, `BookManagementUseCasesQueryAndRegistrationTests.testRegisterBook`, `BookManagementUseCasesQueryAndRegistrationTests.testRegisterBookWithScheduleCalculation` | PASS | 없음 |
| F-07 | 일일 독서 기록 분기/재분배/알림 반영(현재 기기 time zone + 04:00 경계). 시작일 이전 기록은 저장하되, 시작일 이전 자동 스케줄을 만들지 않고 시작일부터 재분배 | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/DailyProgressViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift` | `DailyProgressViewModelTests.*`, `BookManagementUseCasesDailyReadingTests.testRecordReadingBeforeStartDateRecalculateFromStartDate`, `BookManagementUseCasesDailyReadingTests.testRecordReadingRecalculationFailurePropagatesError`, `ReadingScheduleCalculatorApplyTodayReadingTests.applyTodayReading_beforeStartDate_recalculateFromStartDate`, `ReadingScheduleCalculatorRescheduleTests.adjustFutureTargets_noValidDays_throwsCalculationFailed` | PASS | 없음 |
| F-10 | 기존 책 목표기간 수정 및 재분배(현재 기기 time zone today 기준, 설정일 비교는 DateKey 기준) | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/ReadingDateEditViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift` | `ReadingDateEditViewModelTests.*`, `BookManagementUseCasesCompletionAndPlanTests.testUpdateReadingPlan`, `BookManagementUseCasesCompletionAndPlanTests.testUpdateReadingPlanUsesTodayProvider` | PASS | 없음 |
| F-11 | 앱 재진입 시 자동 재분배(현재 기기 time zone today 기준) | `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`, `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift` | `MainHomeViewModelTests.mainHome_overdueBooks_detectedOnReschedule`, `BookManagementUseCasesQueryAndRegistrationTests.testRescheduleOnAppOpenUsesTodayProvider` | PASS | 없음 |
| F-16 | 전체 캘린더/주간 진행률 날짜키 정규화(현재 기기 time zone 기반) | `FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingDateKey.swift`, `FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`, `FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/String+Extension.swift` | `ReadingDateKeyTests.*`, `DayBoundaryPolicyTests.dayBoundary_respectsInjectedCalendarTimeZone` | PASS | 없음 |

## 남은 리스크

1. F-01, F-04는 전용 자동화 테스트가 없어 정적 점검 근거 비중이 높다.
2. F-05의 캘린더 셀 상호작용(시작/종료일 제외 금지, 범위 외 제외일 정리)은 모델 코드 정적 검증을 수행했으나 UI 레벨 회귀 테스트는 추가 여지가 있다.
3. 그 외 확정 오버라이드 항목(F-08/09/12/13/14/15/17)은 코드 경로 + 자동화 테스트 + 실행 결과 번들로 동적 근거를 확보했다.
