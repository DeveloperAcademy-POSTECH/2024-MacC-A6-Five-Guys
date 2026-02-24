# Architecture Debt Remediation Wave Plan (Architecture-first Rebase)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/.codex/PLANS.md` and uses `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/exec-plans/tech-debt-tracker.md` as the debt status source of truth.

## Purpose / Big Picture

이번 사이클의 목표는 기능 버그 우선 순서가 아니라 아키텍처 경계 우선 순서로 리베이스하는 것입니다. 완료 후에는 Presentation이 UseCase-first 경계를 따르고, 홈/알림/날짜 정책 책임이 명확히 분리되며, 경계 위반이 정적 검사 단계에서 차단됩니다.

이 결과는 다음으로 관찰할 수 있습니다.

1. `NotiSettingViewModel`이 단일 UseCase(`NotificationSettingUsing`)만 의존한다.
2. `ReadingLibraryUsing`에서 홈 알림 오케스트레이션이 제거되고 `HomeNotificationUsing`으로 분리된다.
3. `BookSettingsManagerView`가 `@Environment(AppDependencies.self)` 없이 Coordinator 조립만 사용한다.
4. `Date+Extension`이 `DayBoundary.shared`를 직접 참조하지 않는다.
5. `.swiftlint.yml` custom rule과 검색 검증으로 경계 위반 패턴이 0건이다.

## Progress

- [x] (2026-02-16 23:20Z) ExecPlan 실행 순서를 architecture-first(Milestone A~E)로 리베이스.
- [x] (2026-02-16 23:40Z) Milestone A 완료: `NotificationSettingUsing`/`NotificationSettingSnapshot` 도입, `NotiSettingViewModel` 단일 UseCase 의존화, DI 조립 갱신.
- [x] (2026-02-16 23:55Z) Milestone B 완료: `HomeNotificationUsing` 도입, `ReadingLibraryUsing.setupNotifications(for:)` 제거, `MainHomeViewModel` 2-UseCase 구조 적용.
- [x] (2026-02-17 00:05Z) Milestone C 완료: `ReadingDateSettingViewModel` 도입, `ReadingDateSettingView`/`ReadingDateEditView` ViewModel 경유 계산 전환, `BookSettingsManagerView` Composition Root 정렬.
- [x] (2026-02-17 00:10Z) Milestone D 완료: `DayBoundary.shared` 직접 경로 제거, preview/sample `today: Date()` 입력을 `DefaultReadingDateProvider().today()`로 통일.
- [x] (2026-02-17 00:12Z) Milestone E 완료: `.swiftlint.yml` custom rule 3종 추가 및 acceptance 검색 검증(3패턴 0건) 완료.
- [x] (2026-02-17 00:12Z) 대상 테스트 실행 완료:
  `xcodebuild test -quiet -parallel-testing-enabled NO -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/NotiSettingViewModelTests -only-testing:FiveGuyesTests/MainHomeViewModelTests -only-testing:FiveGuyesTests/ReadingDateEditViewModelTests -only-testing:FiveGuyesTests/ReadingDateSettingViewModelTests -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests -only-testing:FiveGuyesTests/DayBoundaryPolicyTests`
- [ ] Remaining: TD-015/TD-010(알림 스케줄 안정화), TD-022 Stage 2(실제 모듈 분리 스파이크).

## Surprises & Discoveries

- Observation: custom rule의 `included: Presentation/View`는 `Presentation/ViewModel` 경로까지 매칭될 수 있었습니다.
  Evidence: 첫 테스트 실행에서 `no_usecase_dependency_in_view`가 ViewModel 파일에 오탐으로 적용됨.

- Observation: `xcodebuild -only-testing`를 사용해도 테스트 타깃 컴파일은 전체 테스트 소스를 대상으로 수행됩니다.
  Evidence: `ViewModelTestSupport.swift`의 반환 누락이 대상 테스트 외 영역에서도 빌드를 중단시켰습니다.

## Decision Log

- Decision: 기능 버그 wave 순서를 유지하지 않고 아키텍처 경계 정리(A~E)를 선행한다.
  Rationale: 이후 기능 수정의 재발 방지력을 높이려면 경계 구조와 조립 책임을 먼저 고정해야 한다.
  Date/Author: 2026-02-16 / Codex

- Decision: TD-022는 단일 타깃 해체 대신 Stage 1 정적 가드룰부터 적용한다.
  Rationale: 단기적으로 재발 차단 효과가 크고, 대규모 모듈 분리 리스크를 분리해 관리할 수 있다.
  Date/Author: 2026-02-16 / Codex

- Decision: BookSettings 조립 책임은 `NavigationCoordinator`로 집중하고 View는 주입받은 ViewModel만 사용한다.
  Rationale: View별 ad-hoc 조립을 줄여 테스트 대역 주입과 경계 일관성을 확보한다.
  Date/Author: 2026-02-17 / Codex

## Outcomes & Retrospective

Architecture-first rebase는 계획한 A~E 범위를 모두 완료했습니다. 핵심 결과는 다음과 같습니다.

1. 알림 설정 경계가 `NotiSettingViewModel -> NotificationSettingUsing`로 고정되어 service/store/opener 직접 의존이 제거되었습니다.
2. 홈 알림 오케스트레이션이 `HomeNotificationUsing`으로 분리되어 `ReadingLibraryUsing` API 응집도가 회복되었습니다.
3. BookSettings 흐름의 Composition Root가 Coordinator로 올라가고 View direct dependency 패턴이 제거되었습니다.
4. 날짜 경계 정책 경로가 provider 기반으로 통일되고 preview/sample today 입력도 동일 정책으로 정렬되었습니다.
5. SwiftLint custom rule + 검색 검증으로 Presentation 경계 위반 3패턴을 빌드 단계에서 차단할 수 있게 되었습니다.

잔여 범위는 TD-015/TD-010, TD-022 Stage 2(모듈 분리)입니다.

## Context and Orientation

이번 리베이스에서 직접 수정한 핵심 경계 파일은 아래와 같습니다.

- 알림 설정 UseCase 경계:
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Notification/NotificationSettingUseCase.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift`
  - `FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`
- 홈 알림 오케스트레이션 경계:
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Home/HomeNotificationUseCase.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`
- BookSettings Composition Root/계산 경계:
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDateEditView.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/ReadingDateSettingViewModel.swift`
- DayBoundary/provider 정렬 + 정적 가드룰:
  - `FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
  - `FiveGuyes/.swiftlint.yml`

## Plan of Work

Milestone A~E는 다음 순서로 구현했습니다.

- Milestone A: Noti UseCase-first 정렬
  `NotificationSettingUseCase`를 도입하고 Noti 화면 경계를 단일 UseCase 의존으로 축소했습니다.

- Milestone B: 홈 UseCase 응집도 정리
  `HomeNotificationUseCase`를 분리해 `ReadingLibraryUsing`에서 홈 부작용 책임을 제거했습니다.

- Milestone C: BookSettings Composition Root 정렬
  View 내부 조립을 제거하고 Coordinator 조립으로 이동했으며 날짜 계산은 `ReadingDateSettingViewModel` 경유로 통일했습니다.

- Milestone D: DayBoundary 우회 정리
  `Date+Extension`의 direct singleton 경로를 provider 경유로 바꾸고 preview/sample today 입력을 provider 기준으로 통일했습니다.

- Milestone E: 컴파일 전 가드룰(TD-022 Stage 1)
  SwiftLint custom rule을 추가해 Presentation 경계 위반을 정적 검사에서 차단했습니다.

## Concrete Steps

작업 루트: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 코드 적용

    `apply_patch`로 A~E 범위 파일 수정 및 신규 파일 추가

2. Acceptance 검색 검증

    `rg -n "\b(any\s+)?\w+(Managing|Providing|Storing|Opening)\b" FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel -g'*.swift'`

    `rg -n "\b(any\s+)?\w+Using\b" FiveGuyes/FiveGuyes/Sources/Presentation/View -g'*.swift'`

    `rg -n "@Environment\(AppDependencies\.self\)" FiveGuyes/FiveGuyes/Sources/Presentation/View -g'*.swift'`

3. 대상 테스트 실행

    `xcodebuild test -quiet -parallel-testing-enabled NO -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/NotiSettingViewModelTests -only-testing:FiveGuyesTests/MainHomeViewModelTests -only-testing:FiveGuyesTests/ReadingDateEditViewModelTests -only-testing:FiveGuyesTests/ReadingDateSettingViewModelTests -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests -only-testing:FiveGuyesTests/DayBoundaryPolicyTests`

## Validation and Acceptance

아래 acceptance 조건을 모두 만족합니다.

1. `Presentation/ViewModel` 내 `...Managing/...Providing/...Storing/...Opening` 직접 의존 검색 결과 0건.
2. `Presentation/View` 내 `any ...Using` 직접 의존 검색 결과 0건.
3. `Presentation/View` 내 `@Environment(AppDependencies.self)` 검색 결과 0건.
4. 지정된 Presentation/Domain/Policy 테스트 세트가 통과.

## Idempotence and Recovery

모든 수정은 additive 또는 local replacement 방식으로 적용되어 동일 패치 재적용 시 충돌 지점만 해결하면 됩니다. lint rule 오탐이 발생하면 rule의 `included/excluded` 경로를 먼저 점검한 뒤 테스트를 재실행합니다.

## Artifacts and Notes

이번 사이클의 주요 산출물:

1. 신규 UseCase: `NotificationSettingUseCase`, `HomeNotificationUseCase`
2. 신규 ViewModel: `ReadingDateSettingViewModel`
3. 신규 테스트: `ReadingDateSettingViewModelTests`
4. 정적 경계 가드룰: `FiveGuyes/.swiftlint.yml` custom rules
5. debt status 동기화: `docs/exec-plans/tech-debt-tracker.md`

## Interfaces and Dependencies

이번 리베이스 후 핵심 인터페이스는 다음과 같습니다.

1. `NotificationSettingUsing`
   - `loadSnapshot(now:)`
   - `refreshSystemAuthorization()`
   - `setNotificationDisabled(_:userBook:)`
   - `updateReminderTime(_:isNotificationDisabled:userBook:)`
   - `openSystemSettings()`

2. `HomeNotificationUsing`
   - `setupNotifications(for:)`

3. `ReadingLibraryUsing`
   - `fetchLibrarySnapshot()` / `deleteBook(id:)` / `rescheduleOnAppOpen(bookId:)` / `today()`

4. `ReadingDateSettingViewModel`
   - `dayCount(startDate:endDate:)`
   - `pagesPerDay(startPage:targetEndPage:startDate:endDate:)`

Plan revision note (2026-02-17): Execution order and outcomes were rebased to architecture-first milestones (A~E) and synced with implemented code/tests.
