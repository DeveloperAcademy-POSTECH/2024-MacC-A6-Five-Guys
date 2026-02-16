# Main 대비 현재 차이 로그

이 문서는 `docs/product/main-feature-baseline.md`의 피처 ID를 기준으로,  
현재 리팩토링 기준(`1f402295`)에서 무엇이 달라졌는지 기록합니다.

비교 기준(main): `8f590c55c163266580bfe425477c76849a88feac`  
비교 대상(current): `1f402295`

## 공통 주의사항(동적 검증)

`xcodebuild test` 실행에서 양쪽 모두 테스트 러너가 부팅 전에 종료되어,  
기능별 런타임 동등성을 완전히 증명하지 못했습니다.

확인된 상태는 다음과 같습니다.  
`/tmp/fiveguyes-main-8f590c5-20260216040302-ios26.xcresult`와  
`/tmp/fiveguyes-head-1f40229-20260216102024-ios26-rerun.xcresult` 모두  
`Early unexpected exit ... before establishing connection` 시스템 실패가 기록되었습니다.

따라서 아래 판정은 정적 코드 계약 비교를 기준으로 작성했습니다.

## F-01 앱 시작 및 전역 네비게이션

판정: 구조 변경(동작 차이 미확인)  
변경점: 의존성 조립이 `NavigationRootView` 내부 직접 생성에서 `AppDependencies` 주입 방식으로 이동했습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/App/NavigationRootView.swift`  
`FiveGuyes/FiveGuyes/Sources/App/AppDependencies.swift`

## F-02 홈 대시보드

판정: 부분 동작 차이 있음(F-15와 연동)  
변경점: 홈 구조 자체는 ViewModel 분리 중심이지만, 삭제 동작의 부작용 정책이 바뀌었습니다(아래 F-15 참조).  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/MainHomeViewModel.swift`

## F-03 책 검색 및 선택

판정: 구조 변경(동작 차이 미확인)  
변경점: `APIStore` 직접 호출이 `BookSearchUseCase -> AladinBookSearchProvider`로 치환되었습니다. URL/파라미터/응답 매핑은 동일 의도입니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Store/APIStore.swift`  
`FiveGuyes/FiveGuyes/Sources/Platform/BookSearch/AladinBookSearchProvider.swift`

## F-04 완독 목표 설정 마법사

판정: 구조 변경(동작 차이 미확인)  
변경점: 단계 흐름은 유지되며, 의존성 생성 위치가 화면 내부에서 앱 조립 계층으로 이동했습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/BookSettingsManagerView.swift`

## F-05 기간/쉬는날 선택

판정: 구조 변경(동작 차이 미확인)  
변경점: 날짜/페이지 계산기가 `Util`에서 `Domain/Calculator`로 이동했고, 입력 모델의 `adjustedToday`가 `today` 주입 방식으로 바뀌었습니다. 규칙 자체는 동일합니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/ReadingDateSettingView.swift`

## F-06 등록 완료 및 책 생성

판정: 구조 변경(동작 차이 미확인)  
변경점: 저장 로직이 View의 SwiftData 직접 저장에서 `BookRegistrationUseCase` 호출로 이동했습니다. 등록 후 알림 설정은 유지됩니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookSetting/FinishGoalView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/FinishGoalViewModel.swift`

## F-07 일일 독서 기록 입력

판정: 구조 변경(동작 차이 미확인)  
변경점: 처리 주체가 View 직접 계산에서 `DailyProgressViewModel -> DailyReadingUseCase`로 이동했습니다. 주요 분기(초과/미달/완독)는 동일하게 유지됩니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/DailyProgressView.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/DailyAndPlanUseCases.swift`

## F-08 완독 축하 요약

판정: 동작 차이 있음  
main 동작: 요약 종료일 표시에 `Date()`를 사용합니다.  
current 동작: `todayProvider.today()`를 사용합니다(04:00 경계 정책 반영).  
영향: 00:00~03:59 구간에서 요약에 표시되는 완료 기준일이 하루 차이날 수 있습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionCelebrationView.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`

## F-09 완독 소감 저장 및 수정

판정: 동작 차이 있음  
main 동작: 공백만 입력된 문자열은 저장 가능합니다(`isEmpty`만 검사). 완료일은 `Date()` 기반입니다.  
current 동작: 공백/개행은 trim 후 차단됩니다. 완료일은 `todayProvider.today()` 기반입니다.  
영향: 입력 허용 범위와 완료일 산정 결과가 달라집니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookCompletion/CompletionReviewView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/CompletionReviewViewModel.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`

## F-10 기존 책의 목표기간 수정

판정: 구조 변경(동작 차이 미확인)  
변경점: 기간 수정 저장이 화면 내부 계산/변경에서 `ReadingPlanUseCase` 호출로 이동했습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/ReadingCalendar/ReadingDateEditView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/ReadingDateEditViewModel.swift`

## F-11 앱 재진입 자동 재분배

판정: 구조 변경(동작 차이 미확인)  
변경점: 홈 진입 시 재분배 호출은 유지되며, 구현이 `RescheduleOnAppOpenUseCase`로 분리되었습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`

## F-12 미완독 종료 플로우

판정: 동작 차이 있음  
main 동작: 닫기/뒤로는 완료 플래그 저장만 수행합니다.  
current 동작: `completeBook` 유스케이스를 통해 완료상태 + 설정 보정 + 알림 제거까지 수행합니다.  
영향: 종료 시점의 데이터/알림 부작용이 확대되었습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/BookProgress/UnfinishReadingView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/UnfinishReadingViewModel.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/CompletionUseCases.swift`

## F-13 알림 설정 화면

판정: 구조 변경(동작 차이 미확인)  
변경점: UserDefaults 직접 접근이 `NotificationSettingsStoring` 추상화로 이동했고, 비동기 처리 위치가 ViewModel로 이동했습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/NotiSetting/NotiSettingView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/ViewModel/NotiSettingViewModel.swift`

## F-14 알림 스케줄 계산 및 발송

판정: 동작 차이 있음  
main 동작: 다음 읽기일 계산 하한이 `lastReadDate ?? Date()`이고, 다음 목표 페이지 계산이 `lastPagesRead` 기준입니다.  
current 동작: 하한이 `max(lastReadDate ?? today, today)`로 강화되고, 시작 페이지 계산이 `max read + 1` 및 범위 clamp 로직으로 변경됐습니다.  
영향: 같은 데이터에서도 알림 날짜/문구 페이지가 달라질 수 있습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Data/SwiftData/Model/UserBookModelV2/ReadingProgress.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/Entity/Extension/FGReadingProgress+Notification.swift`

## F-15 읽는 책/완독 책 목록 및 삭제

판정: 동작 차이 있음  
main 동작: 화면에서 직접 삭제/저장하며 알림 후처리를 호출하지 않습니다.  
current 동작: 삭제 후 남은 읽는 책이 있으면 해당 책으로 알림 재설정, 없으면 알림 전체 제거를 수행합니다.  
영향: 삭제 시 알림 부작용 정책이 main과 다릅니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/MainHomeView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/View/Main/Components/CompletedBooksView.swift`  
`FiveGuyes/FiveGuyes/Sources/Domain/UseCase/BookManagement/LibraryAndRegistrationUseCases.swift`

## F-16 전체 캘린더/주간 진행률 표시

판정: 구조 변경(동작 차이 미확인)  
변경점: 날짜 키 표현이 `toYearMonthDayString`에서 `ReadingDateKey`로 치환되었습니다. 시각화 분기 자체는 동일합니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Presentation/Component/TotalCalendarView.swift`  
`FiveGuyes/FiveGuyes/Sources/Presentation/Component/TotalCalendarView.swift`

## F-17 저장소 및 도메인 서비스 경계

판정: 동작 차이 있음  
main 동작: 저장소 조회는 read-only 동작입니다.  
current 동작: 조회 전 `reading record key` 마이그레이션을 수행하고 필요 시 write-back(저장) 및 완료 플래그 저장을 수행합니다.  
영향: 조회 경로에서 데이터 변경이 발생할 수 있습니다.  
근거:  
`FiveGuyes/FiveGuyes/Sources/Data/RepositoryImpl/SwiftDataBookRepository.swift`  
`FiveGuyes/FiveGuyes/Sources/Data/RepoImpl/SwiftDataBookRepo.swift`

## 유지 규칙

`main` 기준 기능 정의는 `docs/product/main-feature-baseline.md`에만 추가합니다.  
현재 차이는 반드시 이 파일에만 추가하고, 피처 ID(`F-xx`)를 변경하지 않습니다.
