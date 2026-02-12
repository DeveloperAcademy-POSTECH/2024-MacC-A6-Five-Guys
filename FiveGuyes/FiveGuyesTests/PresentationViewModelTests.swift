//
//  PresentationViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/13/26.
//

@testable import FiveGuyes
import Foundation
import Testing

@Suite("Presentation ViewModel 테스트")
@MainActor
struct PresentationViewModelTests {
    @Test("DailyProgressViewModel: 목표 초과 입력 시 제출 차단")
    func dailyProgress_overTarget_preventsSubmit() {
        let service = BookManagementServiceStub()
        let viewModel = DailyProgressViewModel(bookManagementService: service)
        viewModel.pagesToReadToday = 101

        let canSubmit = viewModel.requestSubmit(targetEndPage: 100)

        #expect(!canSubmit)
        #expect(viewModel.showTargetExceededAlert)
    }

    @Test("DailyProgressViewModel: 완독 결과일 때 완독 화면 이동 결과 반환")
    func dailyProgress_completedOutcome() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.recordReadingResult = .completed(updatedBook: book)

        let viewModel = DailyProgressViewModel(bookManagementService: service)
        viewModel.pagesToReadToday = 300

        let outcome = await viewModel.submit(bookId: book.id, readDate: makeDate("2025-01-03"))

        switch outcome {
        case .completionCelebration(let updatedBook):
            #expect(updatedBook.id == book.id)
        default:
            Issue.record("Expected .completionCelebration, got \(outcome)")
        }
        #expect(service.recordReadingCallCount == 1)
        #expect(!viewModel.isSubmitting)
    }

    @Test("DailyProgressViewModel: 실패 시 none 반환 및 submitting 해제")
    func dailyProgress_failure_returnsNone() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.recordReadingError = TestError.forced

        let viewModel = DailyProgressViewModel(bookManagementService: service)
        viewModel.pagesToReadToday = 120

        let outcome = await viewModel.submit(bookId: book.id, readDate: makeDate("2025-01-03"))

        if case .none = outcome {
            #expect(service.recordReadingCallCount == 1)
            #expect(!viewModel.isSubmitting)
        } else {
            Issue.record("Expected .none on failure")
        }
    }

    @Test("DailyProgressViewModel: 중복 제출 시 두 번째 요청 무시")
    func dailyProgress_duplicateSubmit_ignored() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.recordReadingDelayNanoseconds = 80_000_000
        service.recordReadingResult = .recorded(updatedBook: book)

        let viewModel = DailyProgressViewModel(bookManagementService: service)
        viewModel.pagesToReadToday = 10

        async let first = viewModel.submit(bookId: book.id, readDate: makeDate("2025-01-03"))
        await Task.yield()
        let second = await viewModel.submit(bookId: book.id, readDate: makeDate("2025-01-03"))
        _ = await first

        if case .none = second {
            #expect(service.recordReadingCallCount == 1)
        } else {
            Issue.record("Expected second submit to return .none while submitting")
        }
    }

    @Test("CompletionReviewViewModel: 빈 입력이면 경고 표시")
    func completionReview_emptyReview_showsAlert() async {
        let service = BookManagementServiceStub()
        let viewModel = CompletionReviewViewModel(bookManagementService: service)
        viewModel.preloadReview("   ")

        let outcome = await viewModel.submit(
            userBookId: UUID(),
            isUpdateMode: false,
            completionDate: makeDate("2025-01-10")
        )

        if case .none = outcome {
            #expect(viewModel.showEmptyReviewAlert)
        } else {
            Issue.record("Expected .none for empty review")
        }
        #expect(service.completeBookCallCount == 0)
    }

    @Test("CompletionReviewViewModel: 수정 모드에서 updateCompletionReview 호출")
    func completionReview_updateMode_callsUpdateCommand() async {
        let book = makeBook(isCompleted: true)
        let service = BookManagementServiceStub(book: book)
        let viewModel = CompletionReviewViewModel(bookManagementService: service)
        viewModel.preloadReview("수정된 소감")

        let outcome = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: true,
            completionDate: makeDate("2025-01-10")
        )

        if case .popToRoot = outcome {
            #expect(service.updateCompletionReviewCallCount == 1)
            #expect(service.completeBookCallCount == 0)
        } else {
            Issue.record("Expected .popToRoot for update mode")
        }
    }

    @Test("CompletionReviewViewModel: 저장 실패 시 none 반환")
    func completionReview_failure_returnsNone() async {
        let book = makeBook(isCompleted: false)
        let service = BookManagementServiceStub(book: book)
        service.completeBookError = TestError.forced

        let viewModel = CompletionReviewViewModel(bookManagementService: service)
        viewModel.preloadReview("완독 소감")

        let outcome = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: false,
            completionDate: makeDate("2025-01-10")
        )

        if case .none = outcome {
            #expect(service.completeBookCallCount == 1)
            #expect(!viewModel.isSubmitting)
        } else {
            Issue.record("Expected .none on completion review failure")
        }
    }

    @Test("CompletionReviewViewModel: 중복 제출 시 두 번째 요청 무시")
    func completionReview_duplicateSubmit_ignored() async {
        let book = makeBook(isCompleted: false)
        let service = BookManagementServiceStub(book: book)
        service.completeBookDelayNanoseconds = 80_000_000

        let viewModel = CompletionReviewViewModel(bookManagementService: service)
        viewModel.preloadReview("완독 소감")

        async let first = viewModel.submit(
            userBookId: book.id,
            isUpdateMode: false,
            completionDate: makeDate("2025-01-10")
        )
        await Task.yield()
        let second = await viewModel.submit(
            userBookId: book.id,
            isUpdateMode: false,
            completionDate: makeDate("2025-01-10")
        )
        _ = await first

        if case .none = second {
            #expect(service.completeBookCallCount == 1)
        } else {
            Issue.record("Expected second submit to return .none while submitting")
        }
    }

    @Test("ReadingDateEditViewModel: updateReadingPlan 성공 시 true 반환")
    func readingDateEdit_success() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        let viewModel = ReadingDateEditViewModel(bookManagementService: service)

        let isUpdated = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: [],
            today: makeDate("2025-01-02")
        )

        #expect(isUpdated)
        #expect(service.updateReadingPlanCallCount == 1)
    }

    @Test("ReadingDateEditViewModel: 실패 시 false 반환")
    func readingDateEdit_failure() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.updateReadingPlanError = TestError.forced
        let viewModel = ReadingDateEditViewModel(bookManagementService: service)

        let isUpdated = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: [],
            today: makeDate("2025-01-02")
        )

        #expect(!isUpdated)
        #expect(service.updateReadingPlanCallCount == 1)
    }

    @Test("ReadingDateEditViewModel: 중복 제출 시 두 번째 요청 무시")
    func readingDateEdit_duplicateSubmit_ignored() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.updateReadingPlanDelayNanoseconds = 200_000_000

        let viewModel = ReadingDateEditViewModel(bookManagementService: service)

        let firstTask = Task {
            await viewModel.submitReadingPlanUpdate(
                bookId: book.id,
                startDate: makeDate("2025-01-01"),
                endDate: makeDate("2025-01-31"),
                excludedReadingDays: [],
                today: makeDate("2025-01-02")
            )
        }
        for _ in 0..<20 where service.updateReadingPlanCallCount == 0 {
            await Task.yield()
        }
        let second = await viewModel.submitReadingPlanUpdate(
            bookId: book.id,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: [],
            today: makeDate("2025-01-02")
        )
        _ = await firstTask.value

        #expect(!second)
        #expect(service.updateReadingPlanCallCount == 1)
    }

    @Test("FinishGoalViewModel: registerBook 성공 시 true 반환")
    func finishGoal_registerBook_success() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        let viewModel = FinishGoalViewModel(bookManagementService: service)

        let apiBook = Book(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let isRegistered = await viewModel.registerBook(
            selectedBook: apiBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(isRegistered)
        #expect(service.registerBookCallCount == 1)
    }

    @Test("FinishGoalViewModel: 등록 실패 시 false 반환")
    func finishGoal_registerBook_failure() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.registerBookError = TestError.forced
        let viewModel = FinishGoalViewModel(bookManagementService: service)

        let apiBook = Book(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let isRegistered = await viewModel.registerBook(
            selectedBook: apiBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )

        #expect(!isRegistered)
        #expect(service.registerBookCallCount == 1)
    }

    @Test("FinishGoalViewModel: 중복 등록 시 두 번째 요청 무시")
    func finishGoal_registerBook_duplicateSubmit_ignored() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.registerBookDelayNanoseconds = 200_000_000
        let viewModel = FinishGoalViewModel(bookManagementService: service)

        let apiBook = Book(
            title: "테스트 도서",
            author: "작가",
            cover: nil,
            publisher: "출판사",
            isbn13: "1234567890123",
            pubDate: "20250101"
        )

        let firstTask = Task {
            await viewModel.registerBook(
                selectedBook: apiBook,
                startPage: 1,
                targetEndPage: 300,
                startDate: makeDate("2025-01-01"),
                endDate: makeDate("2025-01-31"),
                excludedReadingDays: []
            )
        }
        for _ in 0..<20 where service.registerBookCallCount == 0 {
            await Task.yield()
        }
        let second = await viewModel.registerBook(
            selectedBook: apiBook,
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        _ = await firstTask.value

        #expect(!second)
        #expect(service.registerBookCallCount == 1)
    }

    @Test("UnfinishReadingViewModel: completeBook 성공 시 true 반환")
    func unfinishReading_completeBook_success() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        let viewModel = UnfinishReadingViewModel(bookManagementService: service)

        let completed = await viewModel.completeBook(book)

        #expect(completed)
        #expect(service.completeBookCallCount == 1)
    }

    @Test("UnfinishReadingViewModel: 실패 시 false 반환")
    func unfinishReading_completeBook_failure() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.completeBookError = TestError.forced
        let viewModel = UnfinishReadingViewModel(bookManagementService: service)

        let completed = await viewModel.completeBook(book)

        #expect(!completed)
        #expect(service.completeBookCallCount == 1)
    }

    @Test("UnfinishReadingViewModel: 중복 완료 요청 시 두 번째 요청 무시")
    func unfinishReading_duplicateSubmit_ignored() async {
        let book = makeBook()
        let service = BookManagementServiceStub(book: book)
        service.completeBookDelayNanoseconds = 80_000_000
        let viewModel = UnfinishReadingViewModel(bookManagementService: service)

        async let first = viewModel.completeBook(book)
        await Task.yield()
        let second = await viewModel.completeBook(book)
        _ = await first

        #expect(!second)
        #expect(service.completeBookCallCount == 1)
    }

    @Test("MainHomeViewModel: 현재 읽는 책 기준으로 알림 재설정")
    func mainHome_setupNotificationsForCurrentBook() async {
        let firstBook = makeBook()
        let secondBook = makeBook()
        let service = BookManagementServiceStub(book: firstBook)
        service.fetchReadingBooksResult = [firstBook, secondBook]
        service.fetchCompletedBooksResult = []
        let notificationManager = NotificationManagerStub()
        let viewModel = MainHomeViewModel(
            bookManagementService: service,
            notificationManager: notificationManager
        )

        await viewModel.loadBooks()
        await viewModel.setupNotificationsForCurrentBook()

        #expect(notificationManager.setupAllNotificationsCallCount == 1)
        #expect(notificationManager.setupAllNotificationsBookIDs == [firstBook.id])
    }

    @Test("MainHomeViewModel: 읽는 책이 없으면 알림 재설정 생략")
    func mainHome_setupNotificationsWithoutReadingBook() async {
        let service = BookManagementServiceStub()
        service.fetchReadingBooksResult = []
        service.fetchCompletedBooksResult = []
        let notificationManager = NotificationManagerStub()
        let viewModel = MainHomeViewModel(
            bookManagementService: service,
            notificationManager: notificationManager
        )

        await viewModel.loadBooks()
        await viewModel.setupNotificationsForCurrentBook()

        #expect(notificationManager.setupAllNotificationsCallCount == 0)
    }

    @Test("MainHomeViewModel: 목표일 초과 책을 재스케줄 결과로 반환")
    func mainHome_reschedule_returnsOverdueBooks() async {
        let overdueBook = makeBook()
        let service = BookManagementServiceStub(book: overdueBook)
        service.fetchReadingBooksResult = [overdueBook]
        service.fetchCompletedBooksResult = []
        service.rescheduleOnAppOpenError = ScheduleCalculationError.targetDatePassed
        let notificationManager = NotificationManagerStub()
        let viewModel = MainHomeViewModel(
            bookManagementService: service,
            notificationManager: notificationManager
        )

        await viewModel.loadBooks()
        let overdueBooks = await viewModel.rescheduleOnAppOpen(today: makeDate("2025-01-15"))

        #expect(overdueBooks.count == 1)
        #expect(overdueBooks.first?.id == overdueBook.id)
        #expect(service.rescheduleOnAppOpenCallCount == 1)
    }

    @Test("NotiSettingViewModel: 저장된 설정 로드")
    func notiSetting_loadPersistedSettings() {
        let notificationManager = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: true,
            reminderHour: 8,
            reminderMinute: 30
        )
        let viewModel = NotiSettingViewModel(
            notificationManager: notificationManager,
            settingsStore: settingsStore,
            nowProvider: { self.makeDate("2025-01-01") }
        )

        viewModel.loadPersistedSettings()

        #expect(viewModel.isNotificationDisabled)
        let timeComponents = Calendar.app.dateComponents([.hour, .minute], from: viewModel.selectedTime)
        #expect(timeComponents.hour == 8)
        #expect(timeComponents.minute == 30)
    }

    @Test("NotiSettingViewModel: 알림 비활성화 시 요청 삭제 호출")
    func notiSetting_disable_clearsRequests() async {
        let notificationManager = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 9,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationManager: notificationManager,
            settingsStore: settingsStore
        )

        viewModel.isNotificationDisabled = true
        viewModel.handleNotificationStatusChange(userBook: makeBook())

        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(settingsStore.savedNotificationDisabled == true)
        #expect(notificationManager.clearRequestsCallCount == 1)
        #expect(notificationManager.setupAllNotificationsCallCount == 0)
    }

    @Test("NotiSettingViewModel: 시간 변경 시 설정 저장 및 알림 업데이트")
    func notiSetting_timeChange_updatesSettingsAndNotification() async {
        let notificationManager = NotificationManagerStub()
        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationManager: notificationManager,
            settingsStore: settingsStore,
            nowProvider: { self.makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        viewModel.selectedTime = Calendar.app.date(
            bySettingHour: 21,
            minute: 15,
            second: 0,
            of: baseDate
        ) ?? baseDate
        viewModel.handleNotificationTimeChange(userBook: makeBook())

        await Task.yield()
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(settingsStore.savedReminderHour == 21)
        #expect(settingsStore.savedReminderMinute == 15)
        #expect(notificationManager.updateNotificationCallCount == 1)
    }

    @Test("NotiSettingViewModel: 빠른 연속 시간 변경 시 마지막 요청만 처리")
    func notiSetting_timeChange_cancelsPreviousTask() async {
        let notificationManager = NotificationManagerStub()
        notificationManager.updateNotificationDelayNanoseconds = 80_000_000
        notificationManager.ignoreCancelledCalls = true

        let settingsStore = NotificationSettingsStoreStub(
            disabled: false,
            reminderHour: 7,
            reminderMinute: 0
        )
        let viewModel = NotiSettingViewModel(
            notificationManager: notificationManager,
            settingsStore: settingsStore,
            nowProvider: { self.makeDate("2025-01-01") }
        )

        let baseDate = makeDate("2025-01-01")
        let firstTime = Calendar.app.date(bySettingHour: 8, minute: 10, second: 0, of: baseDate) ?? baseDate
        let secondTime = Calendar.app.date(bySettingHour: 9, minute: 20, second: 0, of: baseDate) ?? baseDate

        viewModel.selectedTime = firstTime
        viewModel.handleNotificationTimeChange(userBook: makeBook())
        viewModel.selectedTime = secondTime
        viewModel.handleNotificationTimeChange(userBook: makeBook())

        try? await Task.sleep(nanoseconds: 140_000_000)

        #expect(settingsStore.savedReminderHour == 9)
        #expect(settingsStore.savedReminderMinute == 20)
        #expect(notificationManager.updateNotificationCallCount == 1)
    }

    private func makeBook(id: UUID = UUID(), isCompleted: Bool = false) -> FGUserBook {
        FGUserBook(
            id: id,
            bookMetaData: FGBookMetaData(
                title: "테스트 책",
                author: "테스트 작가",
                coverImageURL: nil,
                totalPages: 300
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 300,
                startDate: makeDate("2025-01-01"),
                targetEndDate: makeDate("2025-01-31"),
                excludedReadingDays: []
            ),
            readingProgress: FGReadingProgress(
                dailyReadingRecords: [:],
                lastReadDate: nil,
                lastReadPage: 0
            ),
            completionStatus: FGCompletionStatus(
                isCompleted: isCompleted,
                reviewAfterCompletion: ""
            )
        )
    }

    private func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }
}

private enum TestError: Error {
    case forced
}

private final class BookManagementServiceStub: BookManagementService {
    var registerBookResult: FGUserBook
    var recordReadingResult: RecordReadingResult
    var fetchReadingBooksResult: [FGUserBook]
    var fetchCompletedBooksResult: [FGUserBook]
    var fetchBookDetailResult: FGUserBook

    var registerBookError: Error?
    var recordReadingError: Error?
    var deleteBookError: Error?
    var completeBookError: Error?
    var updateCompletionReviewError: Error?
    var updateReadingPlanError: Error?
    var fetchReadingBooksError: Error?
    var fetchCompletedBooksError: Error?
    var fetchBookDetailError: Error?
    var rescheduleOnAppOpenError: Error?

    var registerBookDelayNanoseconds: UInt64 = 0
    var recordReadingDelayNanoseconds: UInt64 = 0
    var completeBookDelayNanoseconds: UInt64 = 0
    var updateCompletionReviewDelayNanoseconds: UInt64 = 0
    var updateReadingPlanDelayNanoseconds: UInt64 = 0

    var registerBookCallCount = 0
    var recordReadingCallCount = 0
    var deleteBookCallCount = 0
    var completeBookCallCount = 0
    var updateCompletionReviewCallCount = 0
    var updateReadingPlanCallCount = 0
    var fetchReadingBooksCallCount = 0
    var fetchCompletedBooksCallCount = 0
    var fetchBookDetailCallCount = 0
    var rescheduleOnAppOpenCallCount = 0

    init(book: FGUserBook = .dummy) {
        self.registerBookResult = book
        self.recordReadingResult = .recorded(updatedBook: book)
        self.fetchReadingBooksResult = [book]
        self.fetchCompletedBooksResult = []
        self.fetchBookDetailResult = book
    }

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        registerBookCallCount += 1
        if registerBookDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: registerBookDelayNanoseconds)
        }
        if let registerBookError { throw registerBookError }
        return registerBookResult
    }

    func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult {
        recordReadingCallCount += 1
        if recordReadingDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: recordReadingDelayNanoseconds)
        }
        if let recordReadingError { throw recordReadingError }
        return recordReadingResult
    }

    func deleteBook(id: UUID) async throws {
        deleteBookCallCount += 1
        if let deleteBookError { throw deleteBookError }
    }

    func completeBook(id: UUID, completionDate: Date, review: String) async throws {
        completeBookCallCount += 1
        if completeBookDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: completeBookDelayNanoseconds)
        }
        if let completeBookError { throw completeBookError }
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        updateCompletionReviewCallCount += 1
        if updateCompletionReviewDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateCompletionReviewDelayNanoseconds)
        }
        if let updateCompletionReviewError { throw updateCompletionReviewError }
    }

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async throws {
        updateReadingPlanCallCount += 1
        if updateReadingPlanDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateReadingPlanDelayNanoseconds)
        }
        if let updateReadingPlanError { throw updateReadingPlanError }
    }

    func fetchReadingBooks() async throws -> [FGUserBook] {
        fetchReadingBooksCallCount += 1
        if let fetchReadingBooksError { throw fetchReadingBooksError }
        return fetchReadingBooksResult
    }

    func fetchCompletedBooks() async throws -> [FGUserBook] {
        fetchCompletedBooksCallCount += 1
        if let fetchCompletedBooksError { throw fetchCompletedBooksError }
        return fetchCompletedBooksResult
    }

    func fetchBookDetail(id: UUID) async throws -> FGUserBook {
        fetchBookDetailCallCount += 1
        if let fetchBookDetailError { throw fetchBookDetailError }
        return fetchBookDetailResult
    }

    func rescheduleOnAppOpen(bookId: UUID, today: Date) async throws {
        rescheduleOnAppOpenCallCount += 1
        if let rescheduleOnAppOpenError { throw rescheduleOnAppOpenError }
    }
}

private final class NotificationManagerStub: NotificationManaging {
    var isAuthorized = true
    var requestAuthorizationCallCount = 0
    var clearRequestsCallCount = 0
    var setupAllNotificationsCallCount = 0
    var setupAllNotificationsBookIDs: [UUID] = []
    var updateNotificationCallCount = 0
    var updateNotificationDelayNanoseconds: UInt64 = 0
    var ignoreCancelledCalls = false

    func requestAuthorization() async -> Bool {
        requestAuthorizationCallCount += 1
        return isAuthorized
    }

    func clearRequests() async {
        clearRequestsCallCount += 1
    }

    func setupAllNotifications(_ readingBook: FGUserBook) async {
        setupAllNotificationsCallCount += 1
        setupAllNotificationsBookIDs.append(readingBook.id)
    }

    func updateNotification(notificationType: NotificationType) async {
        if updateNotificationDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: updateNotificationDelayNanoseconds)
        }
        if ignoreCancelledCalls && Task.isCancelled {
            return
        }
        updateNotificationCallCount += 1
    }
}

private final class NotificationSettingsStoreStub: NotificationSettingsStoring {
    private let storedDisabled: Bool
    private let storedReminderHour: Int
    private let storedReminderMinute: Int

    var savedNotificationDisabled: Bool?
    var savedReminderHour: Int?
    var savedReminderMinute: Int?

    init(disabled: Bool, reminderHour: Int, reminderMinute: Int) {
        self.storedDisabled = disabled
        self.storedReminderHour = reminderHour
        self.storedReminderMinute = reminderMinute
    }

    func saveNotificationDisabled(_ isNotificationDisabled: Bool) {
        savedNotificationDisabled = isNotificationDisabled
    }

    func fetchNotificationDisabled() -> Bool {
        storedDisabled
    }

    func saveNotificationTime(hour: Int, minute: Int) {
        savedReminderHour = hour
        savedReminderMinute = minute
    }

    func fetchNotificationReminderTime() -> (hour: Int, minute: Int) {
        (storedReminderHour, storedReminderMinute)
    }
}
