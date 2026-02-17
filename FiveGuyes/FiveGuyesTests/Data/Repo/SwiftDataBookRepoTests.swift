//
//  SwiftDataBookRepoTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-01-08.
//

@testable import FiveGuyes
import Foundation
import SwiftData
import Testing

/// SwiftDataBookRepo에 대한 Swift Testing 기반 테스트
@Suite("SwiftDataBookRepo 테스트")
@MainActor
struct SwiftDataBookRepoTests {
    private let legacyMigrationCompletionKey = SwiftDataBookRepo.migrationCompletionVersionKey

    // MARK: - Helper Methods

    /// 테스트용 In-Memory ModelContainer 생성
    private func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([UserBookSchemaV2.UserBookV2.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// 테스트용 FGUserBook 생성 헬퍼
    private func createTestBook(
        id: UUID = UUID(),
        title: String = "테스트 책",
        author: String = "테스트 작가",
        totalPages: Int = 300,
        isCompleted: Bool = false
    ) -> FGUserBook {
        return FGUserBook(
            id: id,
            bookMetaData: FGBookMetaData(
                title: title,
                author: author,
                coverImageURL: "https://example.com/cover.jpg",
                totalPages: totalPages
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: totalPages,
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

    /// 테스트용 날짜 생성 헬퍼 (yyyy-MM-dd 형식)
    private func makeDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.app.timeZone
        guard let date = formatter.date(from: dateString) else {
            fatalError("Invalid date string: \(dateString)")
        }
        return date.onlyDate
    }

    /// UTC 기준 절대 시각 fixture 생성
    private func makeUTCDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = calendar.timeZone

        guard let date = calendar.date(from: components) else {
            fatalError("Invalid UTC date fixture")
        }
        return date
    }

    private func createMigrationStorage() -> (userDefaults: UserDefaults, completionKey: String) {
        let suiteName = "SwiftDataBookRepoTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create UserDefaults suite for migration tests")
        }
        userDefaults.removePersistentDomain(forName: suiteName)

        let completionKey = "\(SwiftDataBookRepo.migrationCompletionVersionKey).\(UUID().uuidString)"
        return (userDefaults: userDefaults, completionKey: completionKey)
    }

    private func makeSettingsMigrationCompletionKey(_ completionKey: String) -> String {
        "\(completionKey).settingsDateKeyMigrationV1Completed"
    }

    // MARK: - Mapping Tests

    /// 매핑 테스트: FGUserBook → UserBookV2 → FGUserBook 왕복 변환
    @Test("매핑 테스트: FGUserBook ↔ UserBookV2 왕복 변환")
    func testRoundTripMapping() throws {
        let originalBook = createTestBook(
            id: UUID(),
            title: "원본 책",
            author: "원본 작가",
            totalPages: 500
        )

        // FGUserBook → UserBookV2
        let swiftDataBook = originalBook.toUserBookV2()

        // UserBookV2 → FGUserBook
        let convertedBook = swiftDataBook.toFGUserBook()

        // 검증: 모든 필드가 일치해야 함
        #expect(convertedBook.id
                == originalBook.id)
        #expect(convertedBook.bookMetaData.title
                == originalBook.bookMetaData.title)
        #expect(convertedBook.bookMetaData.author
                == originalBook.bookMetaData.author)
        #expect(convertedBook.bookMetaData.coverImageURL
                == originalBook.bookMetaData.coverImageURL)
        #expect(convertedBook.bookMetaData.totalPages
                == originalBook.bookMetaData.totalPages)
        #expect(convertedBook.userSettings.startPage
                == originalBook.userSettings.startPage)
        #expect(convertedBook.userSettings.targetEndPage
                == originalBook.userSettings.targetEndPage)
        #expect(convertedBook.readingProgress.lastReadPage
                == originalBook.readingProgress.lastReadPage)
        #expect(convertedBook.completionStatus.isCompleted
                == originalBook.completionStatus.isCompleted)
    }

    @Test("UserSettings 매핑은 저장된 DateKey를 우선 사용한다")
    func testUserSettingsMappingPrefersStoredDateKeys() throws {
        let settings = UserSettings(
            startPage: 1,
            targetEndPage: 200,
            startDate: makeUTCDate(year: 2026, month: 2, day: 10, hour: 18),
            targetEndDate: makeUTCDate(year: 2026, month: 2, day: 20, hour: 18),
            nonReadingDays: [makeUTCDate(year: 2026, month: 2, day: 12, hour: 18)],
            startDateKey: "2026-03-01",
            targetEndDateKey: "2026-03-31",
            nonReadingDayKeys: ["2026-03-10"]
        )

        let converted = settings.toFGUserSetting()

        #expect(converted.startDateKey.rawValue == "2026-03-01")
        #expect(converted.targetEndDateKey.rawValue == "2026-03-31")
        #expect(converted.excludedReadingDayKeys.map(\.rawValue) == ["2026-03-10"])
    }

    @Test("UserSettings 매핑은 invalid DateKey를 legacy Date(Asia/Seoul) 기준으로 보정한다")
    func testUserSettingsMappingFallsBackToLegacyDateForInvalidKey() throws {
        let settings = UserSettings(
            startPage: 1,
            targetEndPage: 200,
            startDate: makeUTCDate(year: 2026, month: 2, day: 10, hour: 18, minute: 0),
            targetEndDate: makeUTCDate(year: 2026, month: 2, day: 20, hour: 18, minute: 0),
            nonReadingDays: [],
            startDateKey: "invalid",
            targetEndDateKey: nil,
            nonReadingDayKeys: nil
        )

        let converted = settings.toFGUserSetting()

        #expect(converted.startDateKey.rawValue == "2026-02-11")
        #expect(converted.targetEndDateKey.rawValue == "2026-02-21")
    }

    // MARK: - Basic CRUD Tests

    /// addBook + fetchBook 테스트
    @Test("addBook 후 fetchBook으로 조회 성공")
    func testAddAndFetchBook() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        let testBook = createTestBook(title: "새로운 책", author: "새로운 작가")

        // 책 추가
        try await repo.addBook(testBook)

        // 책 조회
        let fetchedBook = try await repo.fetchBook(by: testBook.id)

        // 검증
        #expect(fetchedBook.id == testBook.id)
        #expect(fetchedBook.bookMetaData.title == "새로운 책")
        #expect(fetchedBook.bookMetaData.author == "새로운 작가")
    }

    /// fetchBooks 테스트: 여러 책 조회
    @Test("fetchBooks로 여러 책 조회")
    func testFetchBooks() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 3개의 책 추가
        let book1 = createTestBook(title: "책1", author: "작가1")
        let book2 = createTestBook(title: "책2", author: "작가2")
        let book3 = createTestBook(title: "책3", author: "작가3")

        try await repo.addBook(book1)
        try await repo.addBook(book2)
        try await repo.addBook(book3)

        // 모든 책 조회
        let books = try await repo.fetchBooks()

        // 검증
        #expect(books.count == 3)
        #expect(books.contains(where: { $0.bookMetaData.title == "책1" }))
        #expect(books.contains(where: { $0.bookMetaData.title == "책2" }))
        #expect(books.contains(where: { $0.bookMetaData.title == "책3" }))
    }

    /// updateBook 테스트
    @Test("updateBook으로 책 정보 수정")
    func testUpdateBook() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 책 추가
        let originalBook = createTestBook(title: "원본 책")
        try await repo.addBook(originalBook)

        // 책 수정 (settings 변경)
        var updatedBook = originalBook
        updatedBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 400, // 변경
            startDate: makeDate("2025-02-01"), // 변경
            targetEndDate: makeDate("2025-02-28"), // 변경
            excludedReadingDays: [makeDate("2025-02-15")]
        )

        try await repo.updateBook(updatedBook)

        // 수정된 책 조회
        let fetchedBook = try await repo.fetchBook(by: originalBook.id)

        // 검증
        #expect(fetchedBook.userSettings.targetEndPage == 400)
        #expect(fetchedBook.userSettings.startDate == makeDate("2025-02-01"))
        #expect(fetchedBook.userSettings.targetEndDate == makeDate("2025-02-28"))
        #expect(fetchedBook.userSettings.excludedReadingDays.count == 1)
    }

    /// deleteBook 테스트
    @Test("deleteBook으로 책 삭제")
    func testDeleteBook() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 책 추가
        let testBook = createTestBook(title: "삭제될 책")
        try await repo.addBook(testBook)

        // 책 삭제
        try await repo.deleteBook(by: testBook.id)

        // 삭제 검증: fetchBook이 에러를 던져야 함
        await #expect(throws: RepoError.self) {
            _ = try await repo.fetchBook(by: testBook.id)
        }
    }

    // MARK: - Filtering Tests

    /// getReadingBooks 테스트: 읽는 중인 책만 조회
    @Test("getReadingBooks로 읽는 중인 책만 조회")
    func testGetReadingBooks() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 읽는 중인 책 2개, 완료된 책 1개 추가
        let readingBook1 = createTestBook(title: "읽는 중1", isCompleted: false)
        let readingBook2 = createTestBook(title: "읽는 중2", isCompleted: false)
        let completedBook = createTestBook(title: "완료됨", isCompleted: true)

        try await repo.addBook(readingBook1)
        try await repo.addBook(readingBook2)
        try await repo.addBook(completedBook)

        // 읽는 중인 책만 조회
        let readingBooks = try await repo.getReadingBooks()

        // 검증
        #expect(readingBooks.count == 2)
        #expect(readingBooks.contains(where: { $0.bookMetaData.title == "읽는 중1" }))
        #expect(readingBooks.contains(where: { $0.bookMetaData.title == "읽는 중2" }))
        #expect(!readingBooks.contains(where: { $0.bookMetaData.title == "완료됨" }))
    }

    /// getCompletedBooks 테스트: 완료된 책만 조회
    @Test("getCompletedBooks로 완료된 책만 조회")
    func testGetCompletedBooks() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 읽는 중인 책 1개, 완료된 책 2개 추가
        let readingBook = createTestBook(title: "읽는 중", isCompleted: false)
        let completedBook1 = createTestBook(title: "완료1", isCompleted: true)
        let completedBook2 = createTestBook(title: "완료2", isCompleted: true)

        try await repo.addBook(readingBook)
        try await repo.addBook(completedBook1)
        try await repo.addBook(completedBook2)

        // 완료된 책만 조회
        let completedBooks = try await repo.getCompletedBooks()

        // 검증
        #expect(completedBooks.count == 2)
        #expect(completedBooks.contains(where: { $0.bookMetaData.title == "완료1" }))
        #expect(completedBooks.contains(where: { $0.bookMetaData.title == "완료2" }))
        #expect(!completedBooks.contains(where: { $0.bookMetaData.title == "읽는 중" }))
    }

    // MARK: - Partial Update Tests

    /// updateReadingProgress 테스트
    @Test("updateReadingProgress로 진행 상황만 수정")
    func testUpdateReadingProgress() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 책 추가
        let testBook = createTestBook()
        try await repo.addBook(testBook)

        // 진행 상황 수정
        let newProgress = FGReadingProgress(
            dailyReadingRecords: ["2025-01-10": ReadingRecord(targetPages: 10, pagesRead: 10)],
            lastReadDate: makeDate("2025-01-10"),
            lastReadPage: 10
        )

        try await repo.updateReadingProgress(bookId: testBook.id, progress: newProgress)

        // 수정 확인
        let fetchedBook = try await repo.fetchBook(by: testBook.id)
        #expect(fetchedBook.readingProgress.lastReadPage == 10)
        #expect(fetchedBook.readingProgress.lastReadDate == makeDate("2025-01-10"))
        #expect(fetchedBook.readingProgress.dailyReadingRecords.count == 1)
    }

    /// updateSettings 테스트
    @Test("updateSettings로 설정만 수정")
    func testUpdateSettings() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 책 추가
        let testBook = createTestBook()
        try await repo.addBook(testBook)

        // 설정 수정
        let newSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 500,
            startDate: makeDate("2025-03-01"),
            targetEndDate: makeDate("2025-03-31"),
            excludedReadingDays: []
        )

        try await repo.updateSettings(bookId: testBook.id, settings: newSettings)

        // 수정 확인
        let fetchedBook = try await repo.fetchBook(by: testBook.id)
        #expect(fetchedBook.userSettings.targetEndPage == 500)
        #expect(fetchedBook.userSettings.startDate == makeDate("2025-03-01"))
        #expect(fetchedBook.userSettings.targetEndDate == makeDate("2025-03-31"))
    }

    /// updateCompletionStatus 테스트
    @Test("updateCompletionStatus로 완료 상태만 수정")
    func testUpdateCompletionStatus() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        // 책 추가 (읽는 중)
        let testBook = createTestBook(isCompleted: false)
        try await repo.addBook(testBook)

        // 완료 상태로 변경
        let newStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: "좋은 책이었습니다"
        )

        try await repo.updateCompletionStatus(bookId: testBook.id, status: newStatus)

        // 수정 확인
        let fetchedBook = try await repo.fetchBook(by: testBook.id)
        #expect(fetchedBook.completionStatus.isCompleted == true)
        #expect(fetchedBook.completionStatus.reviewAfterCompletion == "좋은 책이었습니다")
    }

    // MARK: - Migration Tests

    @Test("fetch 시 legacy 읽기 키를 현재 정책 키로 1회 마이그레이션한다")
    func testFetchMigratesLegacyReadingRecordKeys() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 10

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        let migratedBook = try await repo.fetchBook(by: legacyBook.id)

        #expect(migratedBook.readingProgress.dailyReadingRecords["2025-01-09"] == nil)
        #expect(migratedBook.readingProgress.dailyReadingRecords["2025-01-10"] != nil)
        #expect(migrationStorage.userDefaults.bool(forKey: migrationStorage.completionKey) == true)
    }

    @Test("prewarm은 fetch 이전에 legacy 키 마이그레이션을 수행한다")
    func testPrewarmMigratesBeforeFetchBoundary() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 10
        let legacyBookID = legacyBook.id

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        try repo.prewarmReadingRecordKeyMigrationIfNeeded()

        var fetchDescriptor: FetchDescriptor<UserBookSchemaV2.UserBookV2> = .init(
            predicate: #Predicate { book in
                book.id == legacyBookID
            }
        )
        fetchDescriptor.fetchLimit = 1
        let storedBook = try container.mainContext.fetch(fetchDescriptor).first

        #expect(storedBook?.readingProgress.readingRecords["2025-01-09"] == nil)
        #expect(storedBook?.readingProgress.readingRecords["2025-01-10"] != nil)
        #expect(migrationStorage.userDefaults.bool(forKey: migrationStorage.completionKey) == true)

        let fetchedBook = try await repo.fetchBook(by: legacyBookID)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-09"] == nil)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"] != nil)
    }

    @Test("legacy 완료 키가 true여도 재보정 신호가 없으면 마이그레이션을 건너뛴다")
    func testLegacyCompletionKeyPromotesScopedKeyAndSkipsWhenNoSignal() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        migrationStorage.userDefaults.set(true, forKey: legacyMigrationCompletionKey)

        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-10": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 10

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        let fetchedBook = try await repo.fetchBook(by: legacyBook.id)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-09"] == nil)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"] != nil)
        #expect(migrationStorage.userDefaults.bool(forKey: migrationStorage.completionKey) == true)
    }

    @Test("마이그레이션 완료 플래그가 true여도 legacy 읽기 키 재유입 시 자동 재보정한다")
    func testMigrationRemediatesReintroducedLegacyRecordWhenFlagAlreadyTrue() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let firstLegacyBook = createTestBook().toUserBookV2()
        firstLegacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        firstLegacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        firstLegacyBook.readingProgress.lastPagesRead = 10

        container.mainContext.insert(firstLegacyBook)
        try container.mainContext.save()

        _ = try await repo.fetchBooks()
        #expect(migrationStorage.userDefaults.bool(forKey: migrationStorage.completionKey) == true)

        let reintroducedLegacyBook = createTestBook().toUserBookV2()
        reintroducedLegacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 20, pagesRead: 20)
        ]
        reintroducedLegacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        reintroducedLegacyBook.readingProgress.lastPagesRead = 20

        container.mainContext.insert(reintroducedLegacyBook)
        try container.mainContext.save()

        let fetchedSecondBook = try await repo.fetchBook(by: reintroducedLegacyBook.id)

        #expect(fetchedSecondBook.readingProgress.dailyReadingRecords["2025-01-09"] == nil)
        #expect(fetchedSecondBook.readingProgress.dailyReadingRecords["2025-01-10"] != nil)
    }

    @Test("day shift 추론이 ±1 범위를 벗어나면 이동하지 않는다")
    func testMigrationDoesNotShiftWhenDiffExceedsGuardRange() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-07": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 10

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        let fetchedBook = try await repo.fetchBook(by: legacyBook.id)

        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-07"] != nil)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"] == nil)
    }

    @Test("마이그레이션은 레코드를 정규화한다")
    func testMigrationNormalizesInvalidReadingRecords() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 3, pagesRead: -4),
            "2025-01-10": ReadingRecord(targetPages: 5, pagesRead: 10)
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 0

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        let fetchedBook = try await repo.fetchBook(by: legacyBook.id)
        guard let sanitizedNegative = fetchedBook.readingProgress.dailyReadingRecords["2025-01-09"],
              let sanitizedTarget = fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"] else {
            Issue.record("Expected normalized record")
            return
        }

        #expect(sanitizedNegative.pagesRead == 0)
        #expect(sanitizedNegative.targetPages == 3)
        #expect(sanitizedTarget.pagesRead == 10)
        #expect(sanitizedTarget.targetPages == 10)
    }

    @Test("마이그레이션은 timeZoneID를 정규화하고 유효 값은 보존한다")
    func testMigrationNormalizesAndPreservesTimeZoneID() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.readingProgress.readingRecords = [
            "2025-01-09": ReadingRecord(targetPages: 10, pagesRead: 10, timeZoneID: " "),
            "2025-01-10": ReadingRecord(targetPages: 20, pagesRead: 20, timeZoneID: "America/New_York")
        ]
        legacyBook.readingProgress.lastReadDate = makeDate("2025-01-10")
        legacyBook.readingProgress.lastPagesRead = 20

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        let fetchedBook = try await repo.fetchBook(by: legacyBook.id)

        #expect(
            fetchedBook.readingProgress.dailyReadingRecords["2025-01-09"]?.timeZoneID
                == ReadingRecord.legacyDefaultTimeZoneID
        )
        #expect(
            fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"]?.timeZoneID
                == "America/New_York"
        )
    }

    @Test("fetch 시 legacy UserSettings Date를 DateKey로 1회 백필한다")
    func testFetchBackfillsLegacyUserSettingsDateKeys() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.userSettings.startDate = makeUTCDate(year: 2026, month: 2, day: 10, hour: 18)
        legacyBook.userSettings.targetEndDate = makeUTCDate(year: 2026, month: 2, day: 20, hour: 18)
        legacyBook.userSettings.nonReadingDays = [makeUTCDate(year: 2026, month: 2, day: 15, hour: 18)]
        legacyBook.userSettings.startDateKey = nil
        legacyBook.userSettings.targetEndDateKey = nil
        legacyBook.userSettings.nonReadingDayKeys = nil
        let legacyBookID = legacyBook.id

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        _ = try await repo.fetchBook(by: legacyBookID)

        var fetchDescriptor: FetchDescriptor<UserBookSchemaV2.UserBookV2> = .init(
            predicate: #Predicate { book in
                book.id == legacyBookID
            }
        )
        fetchDescriptor.fetchLimit = 1
        let storedBook = try container.mainContext.fetch(fetchDescriptor).first

        #expect(storedBook?.userSettings.startDateKey == "2026-02-11")
        #expect(storedBook?.userSettings.targetEndDateKey == "2026-02-21")
        #expect(storedBook?.userSettings.nonReadingDayKeys == ["2026-02-16"])
    }

    @Test("완료 플래그가 true여도 legacy settings key 재유입 시 자동 재보정한다")
    func testMigrationRemediatesReintroducedLegacySettingsWhenFlagAlreadyTrue() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        migrationStorage.userDefaults.set(true, forKey: migrationStorage.completionKey)
        migrationStorage.userDefaults.set(
            true,
            forKey: makeSettingsMigrationCompletionKey(migrationStorage.completionKey)
        )

        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let legacyBook = createTestBook().toUserBookV2()
        legacyBook.userSettings.startDate = makeUTCDate(year: 2026, month: 2, day: 10, hour: 18)
        legacyBook.userSettings.targetEndDate = makeUTCDate(year: 2026, month: 2, day: 20, hour: 18)
        legacyBook.userSettings.nonReadingDays = [makeUTCDate(year: 2026, month: 2, day: 15, hour: 18)]
        legacyBook.userSettings.startDateKey = nil
        legacyBook.userSettings.targetEndDateKey = "invalid"
        legacyBook.userSettings.nonReadingDayKeys = ["invalid"]
        let legacyBookID = legacyBook.id

        container.mainContext.insert(legacyBook)
        try container.mainContext.save()

        _ = try await repo.fetchBook(by: legacyBookID)

        var fetchDescriptor: FetchDescriptor<UserBookSchemaV2.UserBookV2> = .init(
            predicate: #Predicate { book in
                book.id == legacyBookID
            }
        )
        fetchDescriptor.fetchLimit = 1
        let storedBook = try container.mainContext.fetch(fetchDescriptor).first

        #expect(storedBook?.userSettings.startDateKey == "2026-02-11")
        #expect(storedBook?.userSettings.targetEndDateKey == "2026-02-21")
        #expect(storedBook?.userSettings.nonReadingDayKeys == ["2026-02-16"])
    }

    @Test("마이그레이션 변경이 없어도 완료 플래그는 기록된다")
    func testMigrationMarksCompletedWhenNoMutation() async throws {
        let container = try createInMemoryContainer()
        let migrationStorage = createMigrationStorage()
        let repo = SwiftDataBookRepo(
            modelContainer: container,
            migrationUserDefaults: migrationStorage.userDefaults,
            migrationCompletionKey: migrationStorage.completionKey
        )

        let alreadyNormalized = createTestBook().toUserBookV2()
        alreadyNormalized.readingProgress.readingRecords = [
            "2025-01-10": ReadingRecord(targetPages: 10, pagesRead: 10)
        ]
        alreadyNormalized.readingProgress.lastReadDate = makeDate("2025-01-10")
        alreadyNormalized.readingProgress.lastPagesRead = 10

        container.mainContext.insert(alreadyNormalized)
        try container.mainContext.save()

        let fetchedBook = try await repo.fetchBook(by: alreadyNormalized.id)
        #expect(fetchedBook.readingProgress.dailyReadingRecords["2025-01-10"] != nil)
        #expect(migrationStorage.userDefaults.bool(forKey: migrationStorage.completionKey) == true)
    }

    // MARK: - Error Tests

    /// 존재하지 않는 책 조회 시 에러
    @Test("존재하지 않는 책 조회 시 RepoError.notFound 발생")
    func testFetchNonexistentBook() async throws {
        let container = try createInMemoryContainer()
        let repo = SwiftDataBookRepo(modelContainer: container)

        let nonexistentId = UUID()

        // 존재하지 않는 ID로 조회 시 에러 발생
        await #expect(throws: RepoError.self) {
            _ = try await repo.fetchBook(by: nonexistentId)
        }
    }
}
