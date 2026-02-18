# Main 대비 현재 피처 비교 및 최종 확정 (3자 비교)

이 문서는 `docs/product/past/main-feature-baseline.md`(main 계약)를 기준으로,  
`이전 리팩토링 기준`과 `현재 HEAD`를 함께 비교해 피처 확정 결과를 기록합니다.

> 과거 기록 안내: 이 문서의 `현재 HEAD` 표기는 작성 당시 기준(역사 기록)이며 현재 운영 기준이 아닙니다. 현재 운영 계약은 `/Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/docs/product/current-feature-spec.md`를 기준으로 하며, 현재 프로덕트 버전은 `2026.02.18+e9084df`입니다.

기준 커밋:
- `main`: `8f590c55c163266580bfe425477c76849a88feac`
- `이전 기준`: `1f402295081417fd19f0269b1ea279deca8afae3`
- `현재 HEAD`: `bugfix/no-ticket-prestart-redistribution-docs` (`origin/develop@6a01e21` 기반 워킹트리)

문서 목적:
- `main`의 사용자 동작을 기준선으로 유지
- 리팩토링 중 개선/수정된 동작은 명시적으로 승인 후 확정
- 아키텍처 변경으로 기능 회귀가 없도록 검증 근거를 남김

최종 확정 결정:
- 결정 일시: `2026-02-17`
- 확정 원칙: `권고안(현재 HEAD 기준) 전부 채택`
- 적용 대상: `F-01` ~ `F-17`

---

## 동적 검증 현황 (2026-02-17 재검증)

### 1) 현재 HEAD (`a27dccb5`) 검증

실행 명령:
```bash
xcodebuild test \
  -project /Users/zaehorang/Documents/Projects/2024-MacC-A6-Five-Guys/FiveGuyes/FiveGuyes.xcodeproj \
  -scheme FiveGuyes \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -resultBundlePath /tmp/fiveguyes-head-a27-feature-verify.xcresult \
  -only-testing:FiveGuyesTests/Platform/BookSearch/AladinBookSearchProviderTests \
  -only-testing:FiveGuyesTests/Presentation/ViewModel/BookSearchViewModelTests \
  -only-testing:FiveGuyesTests/Presentation/ViewModel/NotiSettingViewModelTests \
  -only-testing:FiveGuyesTests/Presentation/ViewModel/MainHomeViewModelTests \
  -only-testing:FiveGuyesTests/Presentation/ViewModel/CompletionReviewViewModelTests \
  -only-testing:FiveGuyesTests/Presentation/ViewModel/UnfinishReadingViewModelTests \
  -only-testing:FiveGuyesTests/Domain/UseCase/BookManagementUseCasesCompletionAndPlanTests \
  -only-testing:FiveGuyesTests/Domain/UseCase/BookManagementUseCasesQueryAndRegistrationTests \
  -only-testing:FiveGuyesTests/Domain/Entity/FGReadingProgressNotificationTests
```

결과:
- `** TEST SUCCEEDED **`
- 결과 번들: `/tmp/fiveguyes-head-a27-feature-verify.xcresult`

### 2) main (`8f590c55`) 검증

실행 명령:
```bash
xcodebuild test \
  -project /tmp/fiveguyes-main-verify/FiveGuyes/FiveGuyes.xcodeproj \
  -scheme FiveGuyes \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -resultBundlePath /tmp/fiveguyes-main-8f590c5-verify-20260217.xcresult \
  -only-testing:FiveGuyesTests/DefaultBookManagementServiceTests
```

결과:
- 빌드 스크립트 환경 실패로 테스트 미완료
- 오류: `Could not get GOOGLE_APP_ID in Google Services file from build environment`
- 결과 번들: `/tmp/fiveguyes-main-8f590c5-verify-20260217.xcresult`

해석:
- 현재 HEAD는 핵심 리스크 구간에 대해 동적 검증 완료
- main은 환경 의존 스크립트 문제로 동일 조건 런타임 동등성 비교가 제한됨
- 따라서 아래 확정 결과는 `정적 계약 비교 + HEAD 동적 검증`을 근거로 함

---

## 기능별 비교 및 확정 결과

표기:
- `동일`: main 대비 사용자 관찰 동작 동일
- `개선`: main의 잠재 오류/설계 취약점 보완
- `구조`: 아키텍처만 변경, 동작은 동일 의도

### F-01 앱 시작 및 전역 네비게이션

- main: `NavigationRootView` 중심 조립
- 이전 기준: `AppDependencies` 주입 구조로 전환
- 현재 HEAD: 동일
- 판정: `구조`
- 권고안: 현재 구조 유지 (조립 책임 분리)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-02 홈 대시보드

- main: 홈 상태 분기/선택 인덱스 보정/재분배 및 알림 트리거
- 이전 기준: ViewModel 분리 + 삭제 부작용 정책 변경(F-15)
- 현재 HEAD: 동일
- 판정: `구조 + F-15 연동`
- 권고안: 홈 표시 계약은 main 유지, 삭제/알림 정책은 F-15에서 별도 확정
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-03 책 검색 및 선택

- main: `APIStore` URL 문자열 직접 결합, HTTP 상태코드 검증 없음
- 이전 기준: `BookSearchUseCase -> AladinBookSearchProvider`로 경계 분리, 동작은 main과 유사
- 현재 HEAD:
  - `URLComponents` 기반 쿼리 인코딩
  - 비정상 HTTP 상태를 `BookSearchNetworkError`로 명시 처리
  - 테스트 주입 가능한 `apiKey` 생성자 추가
- 판정: `개선`
- 권고안: 현재 HEAD 동작 확정 (검색어/ISBN 특수문자, 비정상 응답 처리 안정성 향상)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-04 완독 목표 설정 마법사

- main: 단계형 입력 수집
- 이전 기준: 조립 위치만 변경
- 현재 HEAD: 동일
- 판정: `구조`
- 권고안: 현재 구조 유지
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-05 기간/쉬는날 선택

- main: 기간/쉬는날 규칙 및 일일 목표 계산
- 이전 기준: 계산기/입력 경계 정리
- 현재 HEAD: `ReadingGoalMetricsUseCase`로 계산 위임 + 날짜 해석은 `Calendar.app(현재 기기 time zone)` 기준
- 판정: `구조 + 정책 명시`
- 권고안: 현재 구조/정책 유지
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-06 등록 완료 및 책 생성

- main: 등록 시 초기 스케줄 + 알림 설정
- 이전 기준: `BookRegistrationUseCase`로 이동
- 현재 HEAD: 동일
- 판정: `구조`
- 권고안: 현재 구조 유지
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-07 일일 독서 기록 입력

- main: 기록 결과 분기 + 재분배 + 알림 재설정
- 이전 기준: `DailyReadingUseCase` 경계로 이동
- 현재 HEAD:
  - 시작일 이전 기록은 저장한다.
  - 시작일 이전 기록으로 재계산이 필요한 경우, 재분배 기준일을 `startDate - 1`로 고정해 시작일부터 목표를 재분배한다.
  - 시작일 이전 구간의 자동 스케줄은 생성하지 않는다.
  - today 해석은 현재 기기 time zone + 04:00 경계 기준을 유지한다.
- 판정: `개선`
- 권고안: 현재 HEAD 확정 (시작일 이전 입력 시 사용자 기대와 재분배 시작점을 일치)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-08 완독 축하 요약

- main: 요약 종료일 `Date()` 사용
- 이전 기준: `todayProvider.today()` 사용 (04:00 경계 정책 반영)
- 현재 HEAD: 동일
- 판정: `개선`(정책 일관성) + `표시 변경 가능`
- 영향: 00:00~03:59 구간에서 main과 날짜 표기가 다를 수 있음
- 권고안: 현재 HEAD 확정 (앱 전체 날짜 경계 정책 일관)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-09 완독 소감 저장 및 수정

- main:
  - `isEmpty`만 검사 (공백/개행만 입력 허용)
  - 완료일 `Date()` 기반
- 이전 기준:
  - trim 후 빈값 차단
  - 완료일 `todayProvider.today()` 기반
- 현재 HEAD: 동일
- 판정: `개선`(실행일 완료 정책 확정)
- 권고안: 현재 HEAD 확정 (무의미한 입력 방지 + 완료일은 실행일(today) 고정)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-10 기존 책 목표기간 수정

- main: 기간/쉬는날 수정 후 재분배
- 이전 기준: `ReadingPlanUseCase` 경계화
- 현재 HEAD: 동일 + 재분배 기준일(today)은 현재 기기 time zone + 04:00 경계
- 판정: `구조 + 정책 명시`
- 권고안: 현재 구조/정책 유지
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-11 앱 재진입 자동 재분배

- main: 홈 재진입 시 재분배
- 이전 기준: `RescheduleOnAppOpenUseCase` 분리
- 현재 HEAD: 동일 + 재분배 기준일(today)은 현재 기기 time zone + 04:00 경계
- 판정: `구조 + 정책 명시`
- 권고안: 현재 구조/정책 유지
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-12 미완독 종료 플로우

- main: 닫기/뒤로 시 `completionStatus`만 완료 처리 후 저장
- 이전 기준: `completeBook(id:review:)` 경로 사용
  - 완료 상태 저장
  - 완료일/시작일 보정(완료일은 실행일 today 기준)
  - 알림 전체 해제
- 현재 HEAD: 동일
- 판정: `개선`(도메인 일관성 강화 + 실행일 완료 정책)
- 권고안: 현재 HEAD 확정
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-13 알림 설정 화면

- main:
  - OFF 상태에서도 시간 변경 시 아침 알림 재등록 시도
  - 설정 앱 이동 버튼은 `SystemSettingsManager` 직접 호출
- 이전 기준:
  - 화면 책임이 ViewModel로 이동했지만 OFF 상태 시간 변경 시 재등록 시도는 동일
- 현재 HEAD:
  - OFF 상태 시간 변경 시 `시간 저장만` 수행, 재등록 미실행
  - 설정 앱 이동도 UseCase 경계로 위임
- 판정: `개선`
- 권고안: 현재 HEAD 확정 (OFF 상태 의미와 알림 동작 일치)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-14 알림 스케줄 계산 및 발송

- main:
  - 다음 읽기일 하한 `lastReadDate ?? Date()`
  - 페이지 계산 `lastPagesRead` 중심
  - `updateNotification` 경로에서 재등록 전 권한/앱토글 재검증 없음
- 이전 기준:
  - 하한 `max(lastReadDate ?? today, today)` 강화
  - `records 기반 max pagesRead + 1` 우선 + 범위 clamp
- 현재 HEAD:
  - 위 개선 유지
  - `updateMorningNotification`에서 재등록 전 `canSendNotifications()` 재검증
- 판정: `개선`
- 권고안: 현재 HEAD 확정
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-15 읽는 책/완독 책 목록 및 삭제

- main: 삭제 후 알림 후처리 없음
- 이전 기준: 삭제 후 남은 읽는 책이 있으면 해당 책으로 알림 재설정, 없으면 전체 해제
- 현재 HEAD: 동일
- 판정: `개선`
- 권고안: 현재 HEAD 확정 (삭제 후 stale 알림 방지)
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-16 전체 캘린더/주간 진행률 표시

- main: 문자열 키 기반 조회(`toYearMonthDayString`)
- 이전 기준: `ReadingDateKey` 중심으로 정규화
- 현재 HEAD: 동일 + 키 해석 타임존은 `Calendar.app(현재 기기 time zone)` 사용
- 판정: `개선`(키 일관성 + 현지 날짜 경험)
- 권고안: 현재 HEAD 확정
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

### F-17 저장소 및 도메인 서비스 경계

- main:
  - 조회(fetch/get) 경로는 read-only
  - 조회 중 write-back 없음
- 이전 기준:
  - 조회 전 1회 `reading record key migration` 실행
  - 필요 시 write-back(save) 발생 가능
- 현재 HEAD:
  - 읽기 기록 key migration 1회 정책 유지
  - 설정일 key(`startDateKey`, `targetEndDateKey`, `nonReadingDayKeys`) 1회 backfill 추가
  - 사용되지 않는 partial update API 정리
- 판정: `개선`(데이터 정합성 보정)
- 권고안: 현재 HEAD 확정  
  단, 제품 명세에는 `조회 시 1회 마이그레이션 write-back 가능`과 `settings legacy Date 필드 제거는 후속 분리`를 명시
- 승인 상태: `CONFIRMED (2026-02-17, 현재 HEAD 기준)`

---

## 최종 확정 결과 (2026-02-17)

main 대비 사용자 관찰 동작 차이가 있던 항목의 확정 결과:

1. `F-08` 완독 축하 종료일 기준: `todayProvider.today()` 확정
2. `F-09` 완독 소감 입력 검증: trim 기준 빈값 차단 확정
3. `F-12` 미완독 종료: 완료상태 + 실행일(today) 완료처리 + 시작일 보정 + 알림 해제 확정
4. `F-05/F-10/F-11/F-16` 날짜 정책: 현재 기기 time zone + 04:00 경계 기준 + 설정일 LocalDate key source-of-truth 확정
5. `F-13` 알림 OFF 상태 시간 변경: 시간 저장만 수행, 재등록 미실행 확정
6. `F-14` 알림 계산/재등록: 강화된 하한/페이지 계산 + 재등록 전 권한 재검증 확정
7. `F-15` 삭제 후 알림 정책: 남은 읽는 책 재설정/없으면 전체 해제 확정
8. `F-17` 조회 경계: 읽기 기록/설정일 key 1회 마이그레이션 write-back 허용 확정
9. `F-07` 시작일 이전 기록 정책: 기록 저장은 허용하되 시작일 이전 자동 스케줄은 만들지 않고 시작일부터 재분배 확정

최종 제품 명세 적용 규칙:

1. 기본 계약은 `docs/product/past/main-feature-baseline.md`를 따른다.
2. 위 확정 항목(`F-05`, `F-07`, `F-08`, `F-09`, `F-10`, `F-11`, `F-12`, `F-13`, `F-14`, `F-15`, `F-16`, `F-17`)은 main 계약보다 우선한다.
3. 구현 적합성 평가는 `main-feature-baseline + 본 문서 확정 오버라이드` 조합으로 판정한다.

---

## 운영 규칙

- `main` 기준 피처 계약은 `docs/product/past/main-feature-baseline.md`만 수정
- 현재/이전/HEAD 비교와 확정 사항은 이 문서에만 기록
- 피처 ID(`F-xx`)는 고정
