# ADR-0001: Presentation Architecture for Refactoring

- Status: Accepted
- Date: 2026-02-12
- Owners: FiveGuyes team

## Decision

아키텍처 리팩터링 1차 단계의 Presentation 패턴으로 **Feature 단위 MVVM**을 채택한다.
상태 흐름은 MVVM 내부에서 단방향 규칙(Action -> ViewModel -> State -> View)으로 강제한다.

## Context

현재 프로젝트는 View 내부에 SwiftData 접근, 비즈니스 로직, UI 로직이 혼재되어 있다.
동시에 아래 기반은 이미 구현되어 있다.

- Domain 서비스 경계: `BookManagementService`, `DefaultBookManagementService`
- Data 저장 경계: `BookRepository`, `SwiftDataBookRepository`
- 계산 로직 V2 + 테스트: `ReadingScheduleCalculatorV2`, `DateMathCalculator`, `PageMathCalculator`

따라서 핵심 과제는 새 패턴을 "처음부터 도입"하는 것이 아니라, 기존 코드를 **안전하게 경계화**하는 것이다.

## Options considered

### Option A: MVVM (선택)

- 장점:
  - 현재 View 중심 구조에서 점진 이행 비용이 가장 낮다.
  - 기존 Domain Service 경계를 즉시 활용할 수 있다.
  - 화면별 테스트(ViewModel 단위)를 빠르게 추가할 수 있다.
- 단점:
  - 화면 간 상태/이펙트가 커지면 ViewModel 비대화 위험이 있다.
  - 규칙 없이 쓰면 양방향 데이터 흐름으로 다시 무너질 수 있다.

### Option B: MVI/Reducer 기반 단방향 아키텍처

- 장점:
  - 상태/이펙트 추적성이 높고 복잡 화면에서 일관성이 좋다.
  - 액션 기반 로깅/디버깅에 유리하다.
- 이번 단계 미선택 이유:
  - Store/Reducer/Effect 인프라를 새로 깔아야 하며 초기 변경 폭이 크다.
  - 기존 문제(직접 저장/직접 계산) 해결보다 "프레임워크 전환" 비용이 먼저 발생한다.
  - 일정과 리스크 기준에서 첫 단계 목표와 맞지 않는다.

### Option C: MV 유지 + 부분 정리

- 장점:
  - 단기 코드 수정은 가장 빠르다.
- 미선택 이유:
  - 근본 문제(테스트 불가, 경계 붕괴, 로직 중복)를 구조적으로 해결하지 못한다.

## Rationale

이번 리팩터링의 목적은 "가장 이상적인 패턴 채택"보다 "운영 중 코드의 안정적 구조화"다.
MVVM은 기존 코드와 충돌이 적고, 이미 존재하는 Domain/Data 경계를 활용해 빠르게 테스트 가능한 구조로 전환할 수 있다.
즉, **현재 제약(코드 규모, 일정, 기존 자산)에 대한 최적해**로 MVVM을 선택했다.

## Guardrails

MVVM 채택 시 아래 규칙을 반드시 지킨다.

- View는 SwiftData를 직접 다루지 않는다.
- View는 계산기/Repository를 직접 호출하지 않는다.
- ViewModel만 Service 인터페이스를 호출한다.
- 화면 상태는 ViewModel의 단일 state에서 파생한다.
- 라우팅 payload는 SwiftData 모델 대신 `id` 또는 Domain DTO를 사용한다.

## Consequences

긍정적 결과:
- 화면 리팩터링을 단계적으로 수행해도 기능 리스크를 제어할 수 있다.
- 테스트 경계(ViewModel/Service/Repository)가 명확해진다.
- 신규 기능이 기존 화면 구조를 오염시키는 속도를 줄인다.

부정적 결과/비용:
- ViewModel 수와 보일러플레이트가 증가한다.
- 일부 복잡 플로우에서는 MVI 대비 상태 추적성이 떨어질 수 있다.

## Revisit criteria

아래 조건이 충족되면 MVI(또는 Reducer 기반) 전환을 재검토한다.

- 한 화면의 상태 케이스/사이드이펙트가 지속적으로 증가해 ViewModel 가독성이 악화되는 경우
- 동일한 상태 전이 버그가 여러 화면에서 반복되는 경우
- 액션 단위 로깅/리플레이가 제품 운영상 필수로 요구되는 경우

재검토 시에는 전체 전환 대신, 한 기능(예: 홈+일일기록)에서 파일럿 적용 후 확대 여부를 결정한다.
