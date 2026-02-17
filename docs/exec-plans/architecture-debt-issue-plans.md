# Architecture Debt Issue Plans (Architecture-first Execution Sync)

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `/Users/zaehorang/.codex/PLANS.md` and is executed with `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/exec-plans/architecture-debt-remediation-wave-plan.md`.

## Purpose / Big Picture

이 문서는 2026-02-16 리뷰 항목과 기존 debt를 이슈 단위로 분해해, 어떤 항목이 코드/테스트/문서 기준으로 완료되었고 어떤 항목이 남았는지 즉시 파악할 수 있게 유지합니다.

목표는 “이슈 단위 상태 + 근거 파일 + 다음 액션”을 단일 문서에서 제공하는 것입니다.

## Progress

- [x] (2026-02-16 12:40Z) 초기 이슈별 실행 계획 작성.
- [x] (2026-02-16 13:45Z) 기존 리뷰 항목 완료 동기화: TD-018, TD-017, TD-003, TD-019, TD-016, TD-020, TD-021.
- [x] (2026-02-17 00:10Z) architecture-first 묶음 완료: TD-011, TD-006, TD-004, TD-001.
- [x] (2026-02-17 00:12Z) TD-022 Stage 1 완료: `.swiftlint.yml` custom guard rules + acceptance 검색 0건.
- [x] (2026-02-17 14:52Z) TD-007 후속 1차 완료: record-level `timeZoneID` 저장 + forward-only 정책 + ADR-0004 문서화.
- [x] (2026-02-17 18:20Z) F1~F5 후속 반영: `Calendar.app` 현지 time zone 정책 전환, TD-027 Closed, TD-028 Partial, TD-029 신규 등록.
- [x] (2026-02-17 17:20Z) TD-007 후속 2차 완료: 설정일 LocalDate key source-of-truth + SwiftData 병행 key 필드 + legacy backfill + ADR-0005 문서화.
- [ ] Remaining: TD-015, TD-010, TD-007 잔여(typed key adapter + settings legacy Date 제거 마이그레이션), TD-022 Stage 2(모듈화 스파이크/분리 로드맵), TD-028 구조적 로깅, TD-029 analytics 경계 분리.

## Surprises & Discoveries

- Observation: custom lint rule의 경로 지정이 느슨하면 의도한 계층 외 파일까지 위반으로 탐지됩니다.
  Evidence: `Presentation/View` 룰이 `Presentation/ViewModel`까지 매칭되어 rule `excluded`를 추가해 수정.

- Observation: 선택 테스트 실행에서도 테스트 타깃 컴파일 에러는 전체 테스트 소스에 영향을 줍니다.
  Evidence: `ViewModelTestSupport.swift` 반환 누락으로 대상 테스트와 무관하게 빌드 실패.

## Decision Log

- Decision: 아키텍처 경계 부채는 기능 버그 잔여 항목보다 먼저 처리한다.
  Rationale: 경계 고정이 선행되어야 이후 수정의 재발을 줄일 수 있다.
  Date/Author: 2026-02-16 / Codex

- Decision: TD-022는 Stage 1(정적 가드룰)과 Stage 2(모듈 분리)로 분할한다.
  Rationale: 즉시 차단 가능한 범위와 고비용 구조 변경을 분리해 위험을 낮춘다.
  Date/Author: 2026-02-16 / Codex

- Decision: TD-007 후속은 key 포맷 변경 없이 record value(`timeZoneID`) 스냅샷 + forward-only로 처리한다.
  Rationale: ADR-0003 key 호환성을 유지하면서 해외 이동 시 과거 날짜 경험 보존 요구를 만족하기 위해서다.
  Date/Author: 2026-02-17 / Codex

- Decision: 날짜 버킷팅 정책은 `Calendar.app(현재 기기 time zone + 04:00 경계)`로 통일한다.
  Rationale: write-only timezone 저장으로는 현지 날짜 UX 요구를 충족하지 못해 save/read/reschedule 기준 타임존을 단일화해야 한다.
  Date/Author: 2026-02-17 / Codex

- Decision: 설정일(start/end/non-reading)은 `Date`가 아닌 `ReadingDateKey`를 source-of-truth로 사용하고 SwiftData는 병행 필드 전략으로 점진 전환한다.
  Rationale: 설정일 day drift를 막으면서 운영 데이터 안전성과 롤백 가능성을 함께 확보하기 위함.
  Date/Author: 2026-02-17 / Codex

## Outcomes & Retrospective

이번 사이클에서 이슈 상태는 다음과 같이 업데이트되었습니다.

1. 새로 닫힌 항목: TD-001, TD-004, TD-006, TD-011.
2. Partial로 전환된 항목: TD-022(Stage 1 완료), TD-007(record timezone snapshot + settings LocalDate key 전환), TD-028(print 관측성 1차 보강).
3. 기존 닫힘 유지: TD-018, TD-017, TD-003, TD-019, TD-016, TD-020, TD-021.
4. 이번 사이클에서 TD-027은 실행일 완료 정책 확정으로 Closed 처리했다.
5. 잔여 우선순위: TD-015(P1) -> TD-010(P2) -> TD-007 잔여(P2 Partial, Date 필드 제거 포함) -> TD-022 Stage 2(P3) -> TD-028 구조화(P3) -> TD-029(P3).

검증 명령:

- `xcodebuild test -quiet -parallel-testing-enabled NO -project FiveGuyes/FiveGuyes.xcodeproj -scheme FiveGuyes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:FiveGuyesTests/NotiSettingViewModelTests -only-testing:FiveGuyesTests/MainHomeViewModelTests -only-testing:FiveGuyesTests/ReadingDateEditViewModelTests -only-testing:FiveGuyesTests/ReadingDateSettingViewModelTests -only-testing:FiveGuyesTests/BookManagementUseCasesQueryAndRegistrationTests -only-testing:FiveGuyesTests/BookManagementUseCasesDailyReadingTests -only-testing:FiveGuyesTests/BookManagementUseCasesCompletionAndPlanTests -only-testing:FiveGuyesTests/DayBoundaryPolicyTests`

## Context and Orientation

architecture-first 리베이스에서 반영한 이슈-코드 매핑은 아래와 같습니다.

- TD-011 (Home 알림 오케스트레이션 분리):
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/Home/HomeNotificationUseCase.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`

- TD-006 (Composition Root 상향):
  - `FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`
  - `FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NavigationCoordinator.swift`

- TD-004/TD-001 (DayBoundary/provider 경계 정리):
  - `FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingDateProviding.swift`
  - `FiveGuyes/FiveGuyes/Sources/Shared/Extensions/Foundation/Date+Extension.swift`
  - Preview/sample today 입력이 있는 `Presentation/View/**` 프리뷰 블록

- TD-022 Stage 1 (정적 가드룰):
  - `FiveGuyes/.swiftlint.yml`

- TD-007 후속 1차 (record timezone snapshot):
  - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/ReadingRecord.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/Service/ReadingTimeZoneProviding.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/Calculator/ReadingScheduleCalculator.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`
  - `FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`
  - `docs/decisions/adr-0004-reading-record-timezone-forward-only-policy.md`

- TD-007 후속 2차 (settings LocalDate stability):
  - `FiveGuyes/FiveGuyes/Sources/Domain/Entity/FGUserBook.swift`
  - `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/UserSettings.swift`
  - `FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Extensions/UserBookV2+toFGUserBook.swift`
  - `FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`
  - `docs/decisions/adr-0005-settings-localdate-source-of-truth.md`
  - `docs/exec-plans/td-007-settings-localdate-stability-execplan.md`

## Plan of Work

이 문서는 실행 완료 이슈와 잔여 이슈를 함께 유지합니다.

- 완료된 이슈는 `tech-debt-tracker.md`의 `Status: Closed` 또는 `Partial`로 동기화하고 근거 파일을 보강합니다.
- 잔여 이슈는 아래 순서로 수행합니다.

1. TD-015: 야간 알림 시간 상수 유효 범위 수정 + 테스트 고정.
2. TD-010: 알림 일괄 등록 권한 체크 1회화 + 테스트 고정.
3. TD-007 잔여: typed key adapter 확장 + 글로벌 정책 UX 분리 설계.
4. TD-022 Stage 2: Domain 분리 스파이크와 모듈화 로드맵 문서화.
5. TD-028 잔여: prewarm 실패 구조적 로깅 경계 도입.
6. TD-029: Presentation analytics 호출 경계 분리 로드맵 문서화/착수.

## Concrete Steps

작업 루트: `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys`

1. 코드 변경

    이슈별 대상 파일만 수정하고 out-of-scope 변경을 금지

2. 경계 감사

    `rg -n "\b(any\s+)?\w+(Managing|Providing|Storing|Opening)\b" FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel -g'*.swift'`

    `rg -n "\b(any\s+)?\w+Using\b" FiveGuyes/FiveGuyes/Sources/Presentation/View -g'*.swift'`

    `rg -n "@Environment\(AppDependencies\.self\)" FiveGuyes/FiveGuyes/Sources/Presentation/View -g'*.swift'`

3. 회귀 테스트

    `xcodebuild test ... -only-testing:<대상 테스트들>`

4. 문서 동기화

    `docs/exec-plans/tech-debt-tracker.md` + 본 문서 `Progress/Decision Log/Outcomes` 갱신

## Validation and Acceptance

완료로 판정하려면 아래를 모두 만족해야 합니다.

1. 이슈별 코드 경계가 목표 레이어로 수렴됨.
2. 최소 1개 이상의 회귀 검증(테스트 또는 명시적 테스트 갭 문서화).
3. tracker 상태와 근거 파일이 최신화됨.
4. architecture acceptance 검색 3패턴이 0건.

## Idempotence and Recovery

이슈 단위로 독립 적용되므로 실패 시 해당 이슈 범위 파일만 되돌려 재시도할 수 있습니다. Stage 분리 항목(TD-022)은 Stage 1 완료 상태를 유지한 채 Stage 2를 별도 커밋으로 진행합니다.

## Artifacts and Notes

현재까지 추가된 주요 아키텍처 산출물:

1. `NotificationSettingUseCase.swift`
2. `HomeNotificationUseCase.swift`
3. `ReadingDateSettingViewModel.swift`
4. `ReadingDateSettingViewModelTests.swift`
5. `.swiftlint.yml` custom rule 3종
6. `adr-0004-reading-record-timezone-forward-only-policy.md`
7. `adr-0005-settings-localdate-source-of-truth.md`

## Interfaces and Dependencies

이번 sync에서 새로 확정된 인터페이스는 다음과 같습니다.

1. `NotificationSettingUsing`
2. `HomeNotificationUsing`
3. 축소된 `ReadingLibraryUsing` (알림 오케스트레이션 책임 제거)
4. `ReadingDateSettingViewModel` (View 계산 경계)

Plan revision note (2026-02-17): Rebased from bug-first 기록 to architecture-first execution status and synced issue states with tracker.
Plan revision note (2026-02-17): Added TD-007 settings LocalDate stabilization sync (parallel DateKey fields, legacy backfill, ADR-0005).
