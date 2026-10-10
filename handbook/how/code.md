# Code

Swift 코드를 쓸 때의 관례. lint(`FiveGuyes/.swiftlint.yml`)가 잡는 것은 여기 적지 않는다. `scripts/verify.sh`를 통과시키면 된다. 아래는 lint가 못 잡는 것이다.

## import

공식 프레임워크를 위에, 한 줄 띄고 외부 프레임워크(로컬 패키지 포함). 각 블록은 알파벳순(순서는 lint가 잡는다).

```swift
import Foundation
import SwiftUI

import FGNetwork
```

- 앱 테스트의 `@testable import FiveGuyes`는 테스트 대상이므로 첫 블록에 둔다.
- 패키지 테스트(`FiveGuyes/Packages/*/Tests`)는 패키지 자신과 공식 프레임워크를 한 블록에 알파벳순으로 둔다. 예: `import FGNetwork`, `import Foundation`, `import Testing`.

## 파일

- 파일 하나에 주요 타입 하나. 파일 이름은 타입 이름.
- 헤더 주석은 Xcode 기본 형식(파일 이름, 타깃, `Created by 이름 on 날짜`). 이름은 사람 또는 에이전트.
- 소스·테스트 폴더에는 코드만 둔다.

## 이름

- 타입 `UpperCamelCase`, 프로퍼티·함수 `lowerCamelCase`. 약어도 camel(`isbn13`, `apiKey`). 길이·형식은 lint가 보지 않는다.
- 테스트 대역은 `...Stub`(고정 응답), `...Spy`(호출 기록).
- 기능 요구사항을 검증하는 테스트 이름에는 `spec.md`의 요구사항 ID를 넣는다. 예: `notiSetting_c6_returnWithNotDetermined_hidesBanner`.

## 테스트

- Swift Testing. `struct`, `@Suite`, `@Test`, `#expect`/`#require`. `@MainActor`가 필요한 ViewModel 테스트는 타입에 붙인다.
- 공통 픽스처는 `*TestSupport.swift`.
- 동작 기준이 있는 코드(계산기, 정책, UseCase, ViewModel 상태 전이)를 바꾸면 테스트를 같이 바꾼다.

## 그 밖에

- 엔드포인트의 `URL(string:)`은 `guard`로 받는다. 강제 언래핑은 lint가 경고한다.
