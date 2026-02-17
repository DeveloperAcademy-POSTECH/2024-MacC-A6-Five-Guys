# ADR-0003: Reading Record Key Compatibility Migration Policy

- Status: Accepted
- Date: 2026-02-15
- Owners: FiveGuyes team

## Decision

읽기 기록 저장 키(`[String: ReadingRecord]`)는 유지하되, 앱 시작 시 prewarm으로 우선 실행하고 조회(fetch) 경계에서 fallback으로 보완하는 1회(one-time) 호환 마이그레이션을 수행한다.

마이그레이션은 `SwiftDataBookRepository`에서 실행하며, 다음 규칙을 적용한다.

- 과거 저장 키를 `ReadingDateKey` 정책으로 정규화한다.
- `lastReadDate`를 anchor로 day shift(-1...1)만 허용해 키 이동을 추론한다.
- 충돌 키는 `targetPages/pagesRead` 최대값으로 병합한다.
- 성공 시 완료 플래그를 기록해 재실행하지 않는다.
- 완료 플래그는 앱/스토어/버전 스코프 키를 사용하고, 기존 단일 키는 1회 fallback으로 읽어 새 키로 승격한다.

## Context

도메인 날짜 키 정책은 `ReadingDateKey` + `Calendar.app(Asia/Seoul)`로 통일되었지만, 기존 사용자 데이터는 과거 로컬 타임존 기준으로 저장되었을 가능성이 있다.

이 상태를 그대로 두면 아래 현상이 발생할 수 있다.

- 실제 읽은 기록이 있는데 화면/알림에서 특정 날짜 기록이 비어 보임
- 날짜 경계(04:00) 전후에 조회 키와 저장 키가 하루씩 어긋남
- 도메인 계산은 정책 기준인데 저장 데이터만 legacy 기준으로 남아 비교 결과가 흔들림

## Why Migration Now

이번 시점은 키 생성/파싱 경로가 `ReadingDateKey` 중심으로 수렴한 직후라, legacy 저장 데이터만 보정하면 정책 일관성을 실제 런타임까지 닫을 수 있다.

즉, "정책 정의"와 "실제 저장 데이터"의 마지막 간극을 줄이기 위한 마감 작업이다.

## Options considered

### Option A: One-time write-back migration on fetch (selected)

- 장점:
  - 이후 조회 경로에서 fallback 분기가 줄어 런타임 복잡도/비용이 낮다.
  - 데이터가 한 번 정리되면 화면/알림/계산 결과가 안정적으로 수렴한다.
- 단점:
  - 초기 fetch 시 1회 저장 부하가 있다.

### Option B: Read-time fallback only

- 장점:
  - 저장 데이터를 직접 수정하지 않는다.
- 미선택 이유:
  - 조회 경로마다 fallback 분기를 계속 유지해야 하고, 중복/드리프트 위험이 남는다.

### Option C: Full schema migration

- 장점:
  - 타입 안정성을 저장 스키마 레벨에서 강제할 수 있다.
- 미선택 이유:
  - 현재 목표는 최소 리스크 호환 보정이며, 스키마 변경은 범위를 크게 확장한다.

## Guardrails

- shift 추론값은 `-1...1` 범위만 허용한다.
- 기본 추론값은 `0`(이동 없음)이며, 근거가 충분할 때만 `-1` 또는 `+1` 이동을 허용한다.
- 추론 근거가 부족하면 shift를 적용하지 않는다.
- 마이그레이션 실패 시 완료 플래그를 기록하지 않는다(다음 fetch에서 재시도 가능).
- 저장 포맷(`yyyy-MM-dd`)과 현재 도메인 타임존 정책(`Calendar.app`)은 유지한다.
- 완료 플래그는 앱/스토어/버전 스코프 기준이다.
- 기존 단일 키(`readingRecordKeyMigrationV1Completed`)가 이미 true인 환경은 새 스코프 키로 승격해 불필요한 재실행을 방지한다.
- 이후 외부 경로로 legacy 키가 새로 유입될 수 있다면, 마이그레이션 버전 업 또는 플래그 리셋 전략이 필요하다.

## Implementation Shape

실제 구현은 `SwiftDataBookRepository` 내부 전용 구조로 고정한다.

- 상태 저장은 별도 추상화 타입을 두지 않고 `UserDefaults`를 repository에서 직접 사용한다.
- 마이그레이션 알고리즘은 repository 파일 내부 `ReadingRecordKeyMigrationV1` 구조체로 캡슐화한다.
- 상용 앱 호출 안정성을 위해 기본 생성자(`init(modelContainer:)`)는 유지하고, 테스트/내부 검증을 위해 주입 생성자(`migrationUserDefaults`, `migrationCompletionKey`)를 분리한다.
- 앱 조립 경계(`AppDependencies`)에서 앱 스코프 completion key를 구성하고, 초기화 시 `prewarmReadingRecordKeyMigrationIfNeeded()`를 호출한다.
- prewarm 실패 시 앱 시작을 차단하지 않고, fetch 경계에서 동일 로직을 재시도한다.

이 구조를 선택한 이유:
- 런타임 동작은 유지하면서 코드 경로를 줄여 오버엔지니어링을 해소할 수 있다.
- 테스트 격리(`UserDefaults(suiteName:)`)를 유지할 수 있다.
- 추후 마이그레이션 제거 시 삭제 범위를 repository 내부로 국소화할 수 있다.

## Deletion Strategy

호환 마이그레이션이 더 이상 필요 없다고 판단되면 아래 순서로 제거한다.

1. `SwiftDataBookRepository`의 fetch 경계 마이그레이션 호출 제거
2. repository 내부 `ReadingRecordKeyMigrationV1` 구조체 제거
3. 완료 플래그 접근 코드 제거(`migrationUserDefaults`, `migrationCompletionKey`)
4. 관련 테스트/문서 정리

핵심 원칙은 "도메인 타입/저장 스키마를 건드리지 않고 repository 내부 구현만 삭제 가능" 상태를 유지하는 것이다.

## Consequences

긍정적 결과:
- legacy 데이터로 인한 "기록 누락처럼 보이는" 증상을 완화한다.
- 도메인 정책과 저장 데이터의 날짜 기준이 맞춰진다.

남는 과제:
- 글로벌 사용자 타임존 UX 확장 시 정책 전환 전략(재마이그레이션 포함)을 별도로 설계해야 한다.
- 백업 복원/외부 import 시 legacy 키 재유입 가능성이 있으면, 1회 플래그 정책을 버전드 마이그레이션으로 확장해야 한다.
