# Repository Guidelines

FiveGuyes(한입독서)는 iOS SwiftUI 앱이다. `FiveGuyes/FiveGuyes.xcodeproj`와 공유 스킴 `FiveGuyes`로 빌드한다.

## Getting Started

1. `FiveGuyes/Config.xcconfig`가 없으면 `cp FiveGuyes/Config.xcconfig.example FiveGuyes/Config.xcconfig`를 실행한다. 없으면 빌드가 실패한다.
2. `scripts/verify.sh`로 lint와 테스트를 확인한다.

그 밖의 명령과 설정은 `handbook/where/setup.md`를 본다.

## Code Map

- `FiveGuyes/FiveGuyes/Sources/`: App · Presentation · Domain · Data · Platform · Shared (layer별 폴더)
- `FiveGuyes/FiveGuyesTests/`: 소스와 같은 layer 구조
- `FiveGuyes/Packages/`: 앱을 모르는 공통 기반의 로컬 Swift Package (Swift 6 언어 모드). 현재 `FGNetwork`
- 의존은 Domain 쪽으로만 향하고, 구체 타입 조립은 App이 한다. 규칙은 `services/_common/architecture.md`를 본다.

## Rules

- PR 전에 `scripts/verify.sh`를 통과시킨다.
- 문서가 SoT다. 동작이 바뀌면 `services/<서비스>/`의 문서를, 구조가 바뀌면 `services/_common/architecture.md`를 같은 PR에서 먼저 고친다. 코드가 문서와 다르면 `history/backlog.md`에 적는다.
- layer 경계의 일부는 lint가 error로 막지만 전부는 아니다. 새 타입의 위치는 architecture를 따른다.
- 테스트는 Swift Testing으로 작성한다(XCTest 아님).
- 비밀값(`Config.xcconfig`의 API 키(이름은 `services/book-search/sources.md`), plist 값)은 출력하거나 커밋하지 않는다. `DEVELOPMENT_TEAM`과 공유 스킴의 디버그 인자 변경도 커밋하지 않는다.
- 소스·테스트 폴더에는 코드만 둔다. 이 폴더의 파일은 자동으로 타깃에 들어간다. 문서는 아래 Docs Map의 폴더에 두고, 그 밖의 비코드 파일이 꼭 필요하면 해당 타깃의 `membershipExceptions`에 추가한다.
- 레포 안에 `CLAUDE.md`·`.claude/CLAUDE.md`·`CLAUDE.local.md`를 만들지 않는다. 만들면 그 폴더와 하위에서 Claude Code가 `AGENTS.md` 대신 그 파일을 읽는다.

## Docs Map

문서는 루트의 `handbook/`(팀 지식), `services/`(이 코드의 지식), `history/`(기록)에 있다. 무엇을 어디에 두는지는 `handbook/how/documentation.md`를 본다.

| 작업 | 먼저 읽을 문서 |
|---|---|
| 환경 설정, 빌드·테스트·lint 명령 | `handbook/where/setup.md` |
| 브랜치, 커밋 | `handbook/how/workflow.md` |
| 코드 작성 관례(import 순서, 이름, 테스트) | `handbook/how/code.md` |
| PR 작성 | `.github/pull_request_template.md` |
| 고칠 위치 정하기, 새 타입의 위치, layer 경계, View·ViewModel 구조 | `services/_common/architecture.md` |
| 날짜·시간 값의 종류와 처리 방식 | `services/_common/dates.md` |
| 알림 동작 | `services/notification/spec.md` |
| 도서 검색, 페이지 자동 채움 | `services/book-search/spec.md` |
| 도서 검색 외부 API(카카오·국립중앙도서관) 연동 | `services/book-search/sources.md` |
| HTTP 호출, API 키 읽기 (`FGNetwork` 패키지) | `services/network/module.md` |
| 앱 시작, Firebase·GA·ATT | `services/analytics/launch-and-ga.md` |
| 독서 기록·진행·홈 | 명세 없음. 날짜 규칙은 `services/_common/dates.md` |
| 버그 수정 전 확인: 문서와 다른 코드 목록 | `history/backlog.md` |
| 결정의 이유(현재 규칙 아님. Status 줄로 대체 여부 확인) | `history/decisions/` |
