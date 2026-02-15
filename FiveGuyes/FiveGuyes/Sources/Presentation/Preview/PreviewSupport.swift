//
//  PreviewSupport.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/13/26.
//

#if DEBUG
import Foundation
import SwiftData

// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
enum PreviewSupport {
    // 프리뷰는 실제 DB 파일을 쓰지 않고 메모리에서만 동작하게 만듭니다.
    // 그래야 화면을 안전하게 여러 번 열어도 실제 데이터가 오염되지 않습니다.
    static func makeDependencies() -> AppDependencies {
        // 이 설정은 데이터를 파일로 저장하지 않게 만듭니다.
        // 프리뷰를 닫으면 데이터가 사라져서 실데이터를 건드리지 않습니다.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            // 프리뷰 전용 저장 상자를 여기서 만듭니다.
            // 이후 서비스와 화면은 이 상자를 받아 같은 가짜 데이터를 함께 씁니다.
            let container = try ModelContainer(
                for: UserBookSchemaV2.UserBookV2.self,
                configurations: config
            )
            return AppDependencies(modelContainer: container)
        } catch {
            // 프리뷰 저장소 생성이 실패하면 이후 화면은 정상 동작할 수 없습니다.
            // 즉시 멈춰서 문제를 빨리 보이게 합니다.
            fatalError("Preview ModelContainer 생성 실패: \(error)")
        }
    }

    // 프리뷰에서도 실제 앱처럼 화면 이동을 테스트하려고 코디네이터를 만듭니다.
    // 이걸 같은 방식으로 써야 이동 버그를 미리 찾을 수 있습니다.
    static func makeCoordinator() -> NavigationCoordinator {
        NavigationCoordinator(appDependencies: makeDependencies())
    }
}

// Preview conformance는 nonisolated 프로토콜 계약과 맞추기 위해 @MainActor를 붙이지 않습니다.
final class PreviewBookManagementService: BookManagementService {
    // 프리뷰에서 읽는 중 책 목록을 임시로 들고 있는 변수입니다.
    // 목록 값을 바꾸며 화면 분기가 맞는지 바로 확인할 수 있습니다.
    private var readingBooks: [FGUserBook]
    // 프리뷰에서 완독 책 목록을 임시로 들고 있는 변수입니다.
    // 완독 이동 로직이 맞는지 눈으로 바로 검증할 때 씁니다.
    private var completedBooks: [FGUserBook]
    private let todayProvider: any ReadingDateProviding
    var previewRecordReadingResult: RecordReadingResult?

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
    init(
        readingBooks: [FGUserBook],
        completedBooks: [FGUserBook],
        todayProvider: any ReadingDateProviding = DefaultReadingDateProvider()
    ) {
        self.readingBooks = readingBooks
        self.completedBooks = completedBooks
        self.todayProvider = todayProvider
    }

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
    init(todayProvider: any ReadingDateProviding = DefaultReadingDateProvider()) {
        self.readingBooks = [
            PreviewBookFixtureFactory.makeBook(title: "읽는 중인 샘플 도서", isCompleted: false)
        ]
        self.completedBooks = [
            PreviewBookFixtureFactory.makeBook(title: "완독한 샘플 도서", isCompleted: true)
        ]
        self.todayProvider = todayProvider
    }

    // 입력으로 받은 책 정보를 실제 앱처럼 새 도서 객체로 만듭니다.
    // 그리고 목록에 넣어, 등록 직후 화면 변화를 프리뷰에서도 보이게 합니다.
    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        let newBook = FGUserBook(
            id: UUID(),
            bookMetaData: input.bookMetaData,
            userSettings: input.userSettings,
            readingProgress: FGReadingProgress(
                dailyReadingRecords: [:],
                lastReadDate: nil,
                lastReadPage: input.userSettings.startPage
            ),
            completionStatus: FGCompletionStatus(isCompleted: false, reviewAfterCompletion: "")
        )
        readingBooks.append(newBook)
        return newBook
    }

    // 오늘 읽은 양을 처리한 뒤, 어떤 결과 화면을 띄울지 타입으로 돌려줍니다.
    // 결과 타입이 정확해야 다음 화면 분기가 어긋나지 않습니다.
    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        // 프리뷰에서 특정 결과를 강제로 보고 싶을 때 이 값을 우선 사용합니다.
        // 덕분에 희귀 예외 화면도 바로 열어 확인할 수 있습니다.
        if let previewRecordReadingResult {
            return previewRecordReadingResult
        }
        let book = try await fetchBookDetail(id: bookId)
        return .recorded(updatedBook: book)
    }

    // 삭제된 책을 읽는 목록/완독 목록에서 함께 지웁니다.
    // 둘 중 하나만 지우면 화면과 데이터가 어긋날 수 있습니다.
    func deleteBook(id: UUID) async throws {
        readingBooks.removeAll { $0.id == id }
        completedBooks.removeAll { $0.id == id }
    }

    // 읽는 목록의 책을 완독 목록으로 옮기고 소감까지 같이 저장합니다.
    // 이 순서가 맞아야 완독 직후 화면이 자연스럽게 이어집니다.
    func completeBook(id: UUID, review: String) async throws {
        if let readingIndex = readingBooks.firstIndex(where: { $0.id == id }) {
            var book = readingBooks.remove(at: readingIndex)
            book.completionStatus = FGCompletionStatus(isCompleted: true, reviewAfterCompletion: review)
            completedBooks.append(book)
            return
        }

        if let completedIndex = completedBooks.firstIndex(where: { $0.id == id }) {
            completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: true,
                reviewAfterCompletion: review
            )
            return
        }

        // 해당 책을 못 찾으면 여기서 억지로 진행하지 않고 에러를 올립니다.
        // 위 단계가 이 에러를 받아 사용자에게 올바른 안내를 보여줍니다.
        throw RepoError.notFound
    }

    // 완독 소감만 바꿔서 다시 저장하는 함수입니다.
    // 다른 필드는 건드리지 않아야 사용자가 본 값이 갑자기 바뀌지 않습니다.
    func updateCompletionReview(id: UUID, review: String) async throws {
        if let readingIndex = readingBooks.firstIndex(where: { $0.id == id }) {
            readingBooks[readingIndex].completionStatus = FGCompletionStatus(
                isCompleted: readingBooks[readingIndex].completionStatus.isCompleted,
                reviewAfterCompletion: review
            )
            return
        }

        if let completedIndex = completedBooks.firstIndex(where: { $0.id == id }) {
            completedBooks[completedIndex].completionStatus = FGCompletionStatus(
                isCompleted: completedBooks[completedIndex].completionStatus.isCompleted,
                reviewAfterCompletion: review
            )
            return
        }

        // 해당 책을 못 찾으면 여기서 억지로 진행하지 않고 에러를 올립니다.
        // 위 단계가 이 에러를 받아 사용자에게 올바른 안내를 보여줍니다.
        throw RepoError.notFound
    }

    // 사용자가 고른 새 기간/쉬는 날을 설정에 반영합니다.
    // 이 단계가 끝나야 다음 재계산이 새 규칙으로 동작합니다.
    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        // 꼭 필요한 값이 없으면 여기서 바로 멈춥니다.
        // 그대로 진행하면 잘못된 저장이나 계산이 생길 수 있습니다.
        guard let index = readingBooks.firstIndex(where: { $0.id == bookId }) else {
            // 해당 책을 못 찾으면 여기서 억지로 진행하지 않고 에러를 올립니다.
            // 위 단계가 이 에러를 받아 사용자에게 올바른 안내를 보여줍니다.
            throw RepoError.notFound
        }

        // 페이지 시작/끝 값은 유지하고 날짜만 바꾸려고 기존 설정을 잠깐 꺼내 둡니다.
        // 이 과정을 빼면 페이지 값이 의도치 않게 바뀔 수 있습니다.
        let currentSettings = readingBooks[index].userSettings
        readingBooks[index].userSettings = FGUserSetting(
            startPage: currentSettings.startPage,
            targetEndPage: currentSettings.targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    // 읽는 중 목록을 그대로 돌려주는 함수입니다.
    // 홈 화면은 이 값을 기준으로 카드와 버튼 상태를 정합니다.
    func fetchReadingBooks() async throws -> [FGUserBook] {
        readingBooks
    }

    // 완독 목록을 화면에 넘겨주는 함수입니다.
    // 이 값이 비어 있으면 빈 상태 UI를 보여줍니다.
    func fetchCompletedBooks() async throws -> [FGUserBook] {
        completedBooks
    }

    // 전달받은 id로 책 하나를 찾아 돌려줍니다.
    // 상세 화면은 이 결과로 제목/진행률 같은 값을 채웁니다.
    func fetchBookDetail(id: UUID) async throws -> FGUserBook {
        if let readingBook = readingBooks.first(where: { $0.id == id }) {
            return readingBook
        }

        if let completedBook = completedBooks.first(where: { $0.id == id }) {
            return completedBook
        }

        // 해당 책을 못 찾으면 여기서 억지로 진행하지 않고 에러를 올립니다.
        // 위 단계가 이 에러를 받아 사용자에게 올바른 안내를 보여줍니다.
        throw RepoError.notFound
    }

    // 앱을 다시 열었을 때 계획을 다시 맞춰야 하는지 확인하는 함수입니다.
    // 이 검사가 없으면 오래된 목표가 그대로 남아 사용자에게 잘못 보일 수 있습니다.
    func rescheduleOnAppOpen(bookId: UUID) async throws {
        // 꼭 필요한 값이 없으면 여기서 바로 멈춥니다.
        // 그대로 진행하면 잘못된 저장이나 계산이 생길 수 있습니다.
        guard readingBooks.contains(where: { $0.id == bookId }) else {
            // 해당 책을 못 찾으면 여기서 억지로 진행하지 않고 에러를 올립니다.
            // 위 단계가 이 에러를 받아 사용자에게 올바른 안내를 보여줍니다.
            throw RepoError.notFound
        }
    }

    func today() -> Date {
        todayProvider.today()
    }
}

// 화면 값은 메인 스레드에서만 바꿔야 안전합니다.
// 이 표시를 붙여, 다른 스레드가 끼어들어 상태가 꼬이는 일을 막습니다.
@MainActor
final class PreviewNotificationManager: NotificationManaging {
    var isAuthorized = true

    // 프리뷰에서는 권한 결과를 고정해서 돌려줍니다.
    // 이렇게 해야 권한 허용/거부 UI를 각각 빠르게 확인할 수 있습니다.
    func requestAuthorization() async -> Bool {
        isAuthorized
    }

    // 프리뷰에서는 실제 알림센터를 건드리지 않고 아무 일도 하지 않습니다.
    // 외부 부작용 없이도 화면 흐름만 안전하게 확인하려는 목적입니다.
    func clearRequests() async {}

    // 알림 등록 함수는 호출 위치만 유지하고 실제 등록은 하지 않습니다.
    // 그래야 흐름은 검증하면서 기기 알림 상태는 바꾸지 않습니다.
    func setupAllNotifications(_ readingBook: FGUserBook) async {}

    // 시간 변경 후에도 호출 경로가 끊기지 않게 빈 구현을 둡니다.
    // 이 함수가 없으면 프리뷰에서 변경 흐름 자체를 테스트하기 어렵습니다.
    func updateNotification(notificationType: NotificationType) async {}
}

// Preview conformance는 nonisolated 프로토콜 계약과 맞추기 위해 @MainActor를 붙이지 않습니다.
struct PreviewReadingLibraryUseCaseAdapter: ReadingLibraryUsing {
    let service: any BookManagementService

    func fetchLibrarySnapshot() async throws -> ReadingLibrarySnapshot {
        let readingBooks = try await service.fetchReadingBooks()
        let completedBooks = try await service.fetchCompletedBooks()
        return ReadingLibrarySnapshot(readingBooks: readingBooks, completedBooks: completedBooks)
    }

    func deleteBook(id: UUID) async throws {
        try await service.deleteBook(id: id)
    }

    func rescheduleOnAppOpen(bookId: UUID) async throws {
        try await service.rescheduleOnAppOpen(bookId: bookId)
    }

    func setupNotifications(for readingBook: FGUserBook) async {
        // 프리뷰에서는 실제 알림 스케줄링을 수행하지 않습니다.
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewDailyReadingUseCaseAdapter: DailyReadingUsing {
    let service: any BookManagementService

    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult {
        try await service.recordReading(bookId: bookId, pagesRead: pagesRead)
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewBookCompletionUseCaseAdapter: BookCompletionUsing {
    let service: any BookManagementService

    func completeBook(id: UUID, review: String) async throws {
        try await service.completeBook(id: id, review: review)
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        try await service.updateCompletionReview(id: id, review: review)
    }

    func completionCelebrationSummary(for book: FGUserBook) -> CompletionCelebrationSummary {
        CompletionCelebrationSummary.make(for: book, endDate: service.today())
    }
}

struct PreviewReadingPlanUseCaseAdapter: ReadingPlanUsing {
    let service: any BookManagementService

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws {
        try await service.updateReadingPlan(
            bookId: bookId,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )
    }

    func today() -> Date {
        service.today()
    }
}

struct PreviewBookRegistrationUseCaseAdapter: BookRegistrationUsing {
    let service: any BookManagementService

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        try await service.registerBook(input)
    }
}

final class PreviewNotificationSettingsStore: NotificationSettingsStoring {
    // 알림 끔 여부를 메모리에 들고 있는 값입니다.
    // 토글을 눌렀을 때 저장/조회 결과가 같은지 확인할 때 씁니다.
    private var isDisabled: Bool
    // 알림 시각의 시(hour) 값을 저장해 두는 변수입니다.
    // 저장 후 다시 읽었을 때 같은 값이 나오는지 검증합니다.
    private var reminderHour: Int
    // 알림 시각의 분(minute) 값을 저장해 두는 변수입니다.
    // 저장 후 다시 읽었을 때 같은 값이 나오는지 검증합니다.
    private var reminderMinute: Int

    // 필요한 값을 밖에서 받아 시작할 수 있게 만든 생성자입니다.
    // 이렇게 해야 프리뷰/테스트에서 원하는 상황을 정확히 다시 만들 수 있습니다.
    init(isDisabled: Bool = false, reminderHour: Int = 9, reminderMinute: Int = 0) {
        self.isDisabled = isDisabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    // 토글을 바꾸면 이 메모리 값도 바로 바꿉니다.
    // 바로 반영해야 같은 화면에서 저장 결과를 즉시 확인할 수 있습니다.
    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        isDisabled = isNotificationDisabled
    }

    // 화면이 다시 열릴 때, 저장된 토글 값을 다시 돌려줍니다.
    // 이 동작이 맞아야 사용자가 마지막 설정을 그대로 보게 됩니다.
    func fetchNotificationDisabled() -> Bool {
        isDisabled
    }

    // 시간 피커에서 선택한 시/분을 저장합니다.
    // 다시 들어왔을 때 같은 시간이 보여야 사용자 경험이 끊기지 않습니다.
    func saveNotificationTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
    }

    // 저장된 알림 시각을 꺼내 시간 피커 초기값으로 씁니다.
    // 초기값이 틀리면 사용자가 방금 저장한 시간을 믿기 어렵습니다.
    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        (reminderHour, reminderMinute)
    }
}

#endif
