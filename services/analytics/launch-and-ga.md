# Analytics (Firebase / GA)

앱 시작 시 Firebase 초기화, GA 수집, ATT 요청을 정하는 규칙과 GA 확인 모드 사용법.

범위: GA 수집뿐 아니라 앱 시작 정책(`AppLaunchPolicy`) 전체를 다룬다. Firebase 초기화와 ATT 요청도 이 문서가 기준이다.

## 시작 동작

판단은 `FiveGuyes/FiveGuyes/Sources/App/AppLaunchPolicy.swift`의 `AppLaunchPolicy.decide(_:)`가 한다. `AppDelegate`는 환경 값을 모아 넘기고 결과대로 호출만 한다. 조합별 테스트는 `FiveGuyes/FiveGuyesTests/App/AppLaunchPolicyTests.swift`.

| 구성 | Firebase 초기화 | GA 수집 설정 | ATT 요청 |
|---|---|---|---|
| Release | 항상 | 건드리지 않음 (Info.plist 값 `YES`) | 한다 |
| Debug + 테스트 호스트 실행 | 안 함 | 건드리지 않음 | 안 함 |
| Debug + plist 없음 | 안 함 | 건드리지 않음 | 한다 |
| Debug + plist 있음 | 한다 | 확인 모드면 `true`, 아니면 `false` (매 실행 명시) | 한다 |

- 테스트 호스트 감지: `ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil`. 값은 빈 문자열로 들어오므로 존재 여부만 본다.
- plist 감지: 번들에 `GoogleService-Info.plist` 파일이 있는지만 본다. 견본을 복사한 값 틀린 plist는 `FirebaseApp.configure()`가 시작 중 크래시한다.
- `FIREBASE_ANALYTICS_COLLECTION_ENABLED`는 앱 타깃 빌드 설정(Debug `NO`, Release `YES`)을 `Info.plist`가 받는다. Firebase가 시작하자마자 보내는 자동 이벤트(`first_open` 등)까지 막기 위한 것이다. `Config.xcconfig`는 gitignore 대상이라 여기에 넣지 않는다.
- 수집 설정은 앱을 다시 실행해도 유지되므로, 코드가 Debug 실행마다 `true`/`false`를 명시한다.

## 진짜 plist가 필요할 때

plist 없이도 Debug 앱 실행과 테스트가 가능하다. Firebase 동작을 실제로 확인할 때만 넣는다. 넣는 방법은 `handbook/setup.md`를 본다.

## GA 확인 모드 켜기/끄기

Debug에서 GA 수집과 DebugView 표시를 켜는 스위치는 공유 스킴의 실행 인자 `-FIRDebugEnabled`다. 인자가 있으면 수집을 켜고, 없으면 끈다.

- 파일: `FiveGuyes/FiveGuyes.xcodeproj/xcshareddata/xcschemes/FiveGuyes.xcscheme`의 `LaunchAction > CommandLineArguments`
- 켜기: `-FIRDebugEnabled`의 `isEnabled`를 `"YES"`로 바꾼다.
- 끄기: `"NO"`로 되돌린다.
- 이 변경은 개인 확인용이다. **커밋하지 않는다.** 공유 스킴이라 `git status`에 변경으로 보이므로 커밋 전에 `"NO"`로 되돌린다.
- 진짜 plist가 있어야 실제로 이벤트가 나간다. 확인 중 이벤트는 실서비스 GA 속성으로 전송되며 DebugView 이벤트로 표시된다.
- 테스트는 이 인자와 상관없이 Firebase를 실행하지 않는다. Release는 항상 수집한다.

### DebugView 모드가 기기에 남는 경우

Firebase는 디버그 모드를 기기(시뮬레이터)에 저장한다. `-FIRDebugEnabled` 또는 `-FIRAnalyticsDebugEnabled`로 한 번 실행하면 이후 인자 없이 실행해도 `Debug mode is on`이 남는다(SDK 11.5.0 확인). 수집 자체는 코드가 매 실행마다 끄므로 데이터는 나가지 않는다. 확인이 끝난 뒤 디버그 모드를 해제하려면 `-FIRDebugDisabled` 인자로 한 번 실행한다(`-FIRAnalyticsDebugDisabled`는 효과 없음).

상세 로그만 보고 싶으면 `-FIRAnalyticsVerboseLoggingEnabled`를 쓴다.
