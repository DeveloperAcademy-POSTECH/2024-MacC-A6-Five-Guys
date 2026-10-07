# Backlog

문서(SoT)와 다른 코드 중 아직 착수하지 않은 것. 해결 방법은 착수할 때 정한다.

- 문서와 다른 코드를 발견하면 한 줄 추가한다.
- 착수하면 GitHub 이슈를 만들고 상태에 번호를 적는다.
- 고치면 줄을 지운다.

경로는 `FiveGuyes/FiveGuyes/Sources/` 기준이다.

| 위반 | 어긋난 규칙 (architecture) | 위치 | 상태 |
|---|---|---|---|
| Presentation의 `NavigationCoordinator`가 `AppDependencies`를 보유하고 화면과 ViewModel을 만든다 | Dependency Direction: 다이어그램에 없는 방향의 참조는 허용하지 않는다<br>Presentation: `NavigationCoordinator`는 화면 이동 상태만 관리하고 의존성을 갖지 않는다 | `Presentation/ViewModel/NavigationCoordinator.swift:174,189,354`, `App/NavigationRootView.swift:16,23,25` | 대기 |
| `Presentation/Preview/PreviewSupport.swift`가 App의 `AppDependencies`를 만든다 | Dependency Direction: 다이어그램에 없는 방향의 참조는 허용하지 않는다 | `Presentation/Preview/PreviewSupport.swift:14-28` | 대기 |
| View가 Platform의 `Tracking`을 직접 호출한다 | Dependency Direction: layer를 넘어 기능(UseCase, Repository, Service)에 의존할 때는 Domain의 protocol을 거친다 | `MainHomeView.swift:341,343`, `MultiBookProgressView.swift:55`, `DailyProgressView.swift:114`, `BookSearchView.swift:66`, `BookPageSettingView.swift:133`, `ReadingDateSettingView.swift:62`, `FinishGoalView.swift:172` (모두 `Presentation/View/` 아래) | 대기 |
| Domain이 Data의 저장 모델을 만든다 | Dependency Direction: Data·Platform의 외부 표현 타입(저장 모델, API DTO)은 그 layer 밖으로 노출하지 않는다 | `Domain/Entity/Extension/FGUserBook+toUserBookV2.swift:9-61` | 대기 |
| Shared가 Domain의 `ReadingDateKey`를 참조한다 | Dependency Direction: 다이어그램에 없는 방향의 참조는 허용하지 않는다 | `Shared/Extensions/Foundation/Date+Extension.swift:56-57`, `Shared/Extensions/Foundation/String+Extension.swift:48,64-65` | 대기 |
| 조립 코드 밖에서 기본 인자나 전역 인스턴스로 구체 타입을 만든다 | Dependency Direction: 구체 타입을 알고 생성·연결하는 곳은 조립 코드(App, `Presentation/Preview/`)뿐이다 | `Platform/Notification/NotificationManager.swift:16-18`, `Data/RepoImpl/SwiftDataBookRepo.swift:28-42`, `Domain/Service/ReadingDateProviding.swift:19` | 대기 |
| View 파일의 `#Preview`가 구체 타입(`DefaultReadingDateProvider`, `ReadingGoalMetricsUseCase`)을 만든다 | Dependency Direction: 구체 타입을 알고 생성·연결하는 곳은 조립 코드(App, `Presentation/Preview/`)뿐이다 | `Presentation/View/` 아래 `FinishGoalView.swift:219,235`, `ReadingDateEditView.swift:195,203,223`, `CalendarGridView.swift:159,169`, `ReadingDatePickerView.swift:52,61`, `MultiBookProgressView.swift:138,149`, `ReadingBookProgressCell.swift:116`, `WeeklyProgressCalendar.swift:283`, `ReadingBooksCarousel.swift:37` | 대기 |
| Domain이 `os`를 import하고 `Bundle.main`을 쓴다 | Domain: Foundation 외 프레임워크(`os` 포함)는 import하지 않는다<br>Domain: 저장·네트워크·앱 환경 API는 Repository나 Service로 요구한다 | `Domain/Service/MigrationDiagnosticLogging.swift:9,28,31-34` | 대기 |
| 여러 Preview가 함께 쓰는 지원 코드가 `Presentation/Preview/` 밖에 있다 | Presentation: 여러 Preview가 함께 쓰는 조립·대역·샘플 데이터는 `Presentation/Preview/`에 둔다 | `Presentation/View/Main/MainPreviewSupport.swift`, `Presentation/View/BookSetting/BookSettingPreviewSupport.swift`, `Presentation/View/Shared/Preview/PreviewBookFixtureFactory.swift`, `Domain/Entity/Extension/FGUserBook+PreviewDummy.swift` | 대기 |
| 테스트 전용 대역이 앱 타깃에 있다 | Dependency Direction: 테스트 전용 대역은 테스트 타깃에 둔다 | `Data/RepoImpl/MockBookRepo.swift` | 대기 |
| ViewModel이 화면에 그릴 결과를 메서드 반환값으로 넘긴다 | Presentation: 화면에 그릴 결과는 상태 프로퍼티로 드러낸다 | `MainHomeViewModel.today`, `.deleteBook`; `DailyProgressViewModel.today`, `.requestSubmit`; `BookSettingsManagerViewModel.today`; `BookSearchViewModel.completeSelection`; `ReadingDateEditViewModel.today`; `CompletionCelebrationViewModel.summary`; `ReadingDateSettingViewModel.dayCount`, `.pagesPerDay` | 대기 |
| 화면 이동용 반환값이 성공 여부나 행선지 enum이 아니다 | Presentation: 이동 여부나 행선지에 판단이 필요하면 ViewModel이 메서드 반환값(성공 여부, 행선지 enum)으로 돌려준다 | `MainHomeViewModel.rescheduleOnAppOpen() -> [FGUserBook]` | 대기 |
| ViewModel이 `...Using` 외의 의존성을 주입받는다 | Presentation: ViewModel은 `...Using`만 주입받는다 | `Presentation/ViewModel/NotiSettingViewModel.swift:24-32` (`nowProvider`) | 대기 |
