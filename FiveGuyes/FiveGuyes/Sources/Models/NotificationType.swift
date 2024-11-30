//
//  NotificationType.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/12/24.
//

import Foundation

enum NotificationType {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    case morning(readingBook: UserBook)
    case night(readingBook: UserBook)
    
    func descriptionContent() -> (title: String, body: String) {
        switch self {
        case .morning(let readingBook):
            // 랜덤 타이틀 선택
            let titleTemplate = NotificationType.morningTitles.randomElement() ?? "오늘 하루 목표는 %d쪽이에요."
            let body = NotificationType.morningBodies.randomElement() ?? "지혜는 독서를 통해 찾을 수 있어요."
            
            // 타이틀에 %d가 있으면 페이지 수 대입
            var title: String {
                if titleTemplate.contains("%d") {
                    let pages = readingBook.readingProgress.findNextReadingPagesPerDay(for: readingBook.userSettings)
                    return String(format: titleTemplate, pages)
                } else {
                    return titleTemplate
                }
            }
            return (title, body)
            
        case .night:
            // 랜덤 타이틀 선택
            let title = NotificationType.nightTitles.randomElement() ?? "아직 늦지 않았어요!"
            let body = NotificationType.nightBodies.randomElement() ?? "책은 항상 당신의 손길을 기다리고 있어요."

            return (title, body)
        }
    }
    
    func dateContent() -> Date? {
        switch self {
        case .morning(let readingBook), .night(let readingBook):
            return readingBook.readingProgress.findNextReadingDay()
        }
    }
    
    func timeContent() -> (hour: Int, minute: Int) {
        switch self {
        case .morning:
            return UserDefaultsManager.fetchNotificationReminderTime()
        case .night:
            return (24, 0)
        }
    }
    
    /// 고유 identifier 생성 메서드
    func identifier() -> String {
        switch self {
        case .morning(let readingBook):
            return "\(readingBook.id)-morning"
        case .night(let readingBook):
            return "\(readingBook.id)-night"
        }
    }
}

extension NotificationType {
    /// 알림 문구 데이터
    private static let morningTitles = [
        "오늘 목표는 %d쪽이에요!",
        "독서로 오늘 하루를 시작해 볼까요?",
        "%d쪽으로 오늘을 시작해요!"
    ]
    
    private static let morningBodies = [
        "“독서는 대화의 준비를 갖추게 한다.” - 프랜시스 베이컨",
        "지식은 강력한 무기이며, 독서는 그 무기를 얻는 방법입니다!",
        "지혜는 독서를 통해 찾을 수 있어요.",
        "“독서는 다른 세상으로 건너갈 방법을 알려준다.” - 허필선"
    ]
    
    private static let nightTitles = [
        "아직 늦지 않았어요!",
        "지금 시작해도 충분해요!",
        "한 장만 넘겨보는 건 어때요?",
        "하루의 끝, 독서로 마음을 정리해보세요",
        "한 페이지가 내일을 더 빛나게 해줄거에요"
    ]
    
    private static let nightBodies = [
        "오늘 읽은 책이 내일의 당신을 만들어요.",
        "지혜는 독서를 통해 찾을 수 있어요.",
        "“책을 읽지 않은 날은 영혼의 빈 공간과 같다.” - 칼 세이건",
        "“오늘 읽은 책이 내일의 성공을 이끈다.” - 워렌 버핏",
        "“한 페이지의 독서도 삶을 새롭게 한다.” - 헬렌 켈러",
        "책은 항상 당신의 손길을 기다리고 있어요.",
        "당신이 책을 읽는 데 들이는 시간은 절대 헛되지 않아요!"
    ]
}
