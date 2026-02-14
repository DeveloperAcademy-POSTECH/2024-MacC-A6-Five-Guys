//
//  SwiftDataBookRepositoryTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-01-08.
//

@testable import FiveGuyes
import Foundation
import SwiftData
import Testing

/// SwiftDataBookRepository에 대한 Swift Testing 기반 테스트
@Suite("SwiftDataBookRepository 테스트")
@MainActor
struct SwiftDataBookRepositoryTests {

    // MARK: - Helper Methods

    /// 테스트용 In-Memory ModelContainer 생성
    private func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([UserBookSchemaV2.UserBookV2.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
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

    // MARK: - Basic CRUD Tests

    /// addBook + fetchBook 테스트
    @Test("addBook 후 fetchBook으로 조회 성공")
    func testAddAndFetchBook() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        let testBook = createTestBook(title: "새로운 책", author: "새로운 작가")

        // 책 추가
        try await repository.addBook(testBook)

        // 책 조회
        let fetchedBook = try await repository.fetchBook(by: testBook.id)

        // 검증
        #expect(fetchedBook.id == testBook.id)
        #expect(fetchedBook.bookMetaData.title == "새로운 책")
        #expect(fetchedBook.bookMetaData.author == "새로운 작가")
    }

    /// fetchBooks 테스트: 여러 책 조회
    @Test("fetchBooks로 여러 책 조회")
    func testFetchBooks() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 3개의 책 추가
        let book1 = createTestBook(title: "책1", author: "작가1")
        let book2 = createTestBook(title: "책2", author: "작가2")
        let book3 = createTestBook(title: "책3", author: "작가3")

        try await repository.addBook(book1)
        try await repository.addBook(book2)
        try await repository.addBook(book3)

        // 모든 책 조회
        let books = try await repository.fetchBooks()

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
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 책 추가
        let originalBook = createTestBook(title: "원본 책")
        try await repository.addBook(originalBook)

        // 책 수정 (settings 변경)
        var updatedBook = originalBook
        updatedBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 400, // 변경
            startDate: makeDate("2025-02-01"), // 변경
            targetEndDate: makeDate("2025-02-28"), // 변경
            excludedReadingDays: [makeDate("2025-02-15")]
        )

        try await repository.updateBook(updatedBook)

        // 수정된 책 조회
        let fetchedBook = try await repository.fetchBook(by: originalBook.id)

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
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 책 추가
        let testBook = createTestBook(title: "삭제될 책")
        try await repository.addBook(testBook)

        // 책 삭제
        try await repository.deleteBook(by: testBook.id)

        // 삭제 검증: fetchBook이 에러를 던져야 함
        await #expect(throws: RepositoryError.self) {
            _ = try await repository.fetchBook(by: testBook.id)
        }
    }

    // MARK: - Filtering Tests

    /// getReadingBooks 테스트: 읽는 중인 책만 조회
    @Test("getReadingBooks로 읽는 중인 책만 조회")
    func testGetReadingBooks() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 읽는 중인 책 2개, 완료된 책 1개 추가
        let readingBook1 = createTestBook(title: "읽는 중1", isCompleted: false)
        let readingBook2 = createTestBook(title: "읽는 중2", isCompleted: false)
        let completedBook = createTestBook(title: "완료됨", isCompleted: true)

        try await repository.addBook(readingBook1)
        try await repository.addBook(readingBook2)
        try await repository.addBook(completedBook)

        // 읽는 중인 책만 조회
        let readingBooks = try await repository.getReadingBooks()

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
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 읽는 중인 책 1개, 완료된 책 2개 추가
        let readingBook = createTestBook(title: "읽는 중", isCompleted: false)
        let completedBook1 = createTestBook(title: "완료1", isCompleted: true)
        let completedBook2 = createTestBook(title: "완료2", isCompleted: true)

        try await repository.addBook(readingBook)
        try await repository.addBook(completedBook1)
        try await repository.addBook(completedBook2)

        // 완료된 책만 조회
        let completedBooks = try await repository.getCompletedBooks()

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
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 책 추가
        let testBook = createTestBook()
        try await repository.addBook(testBook)

        // 진행 상황 수정
        let newProgress = FGReadingProgress(
            dailyReadingRecords: ["2025-01-10": ReadingRecord(targetPages: 10, pagesRead: 10)],
            lastReadDate: makeDate("2025-01-10"),
            lastReadPage: 10
        )

        try await repository.updateReadingProgress(bookId: testBook.id, progress: newProgress)

        // 수정 확인
        let fetchedBook = try await repository.fetchBook(by: testBook.id)
        #expect(fetchedBook.readingProgress.lastReadPage == 10)
        #expect(fetchedBook.readingProgress.lastReadDate == makeDate("2025-01-10"))
        #expect(fetchedBook.readingProgress.dailyReadingRecords.count == 1)
    }

    /// updateSettings 테스트
    @Test("updateSettings로 설정만 수정")
    func testUpdateSettings() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 책 추가
        let testBook = createTestBook()
        try await repository.addBook(testBook)

        // 설정 수정
        let newSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 500,
            startDate: makeDate("2025-03-01"),
            targetEndDate: makeDate("2025-03-31"),
            excludedReadingDays: []
        )

        try await repository.updateSettings(bookId: testBook.id, settings: newSettings)

        // 수정 확인
        let fetchedBook = try await repository.fetchBook(by: testBook.id)
        #expect(fetchedBook.userSettings.targetEndPage == 500)
        #expect(fetchedBook.userSettings.startDate == makeDate("2025-03-01"))
        #expect(fetchedBook.userSettings.targetEndDate == makeDate("2025-03-31"))
    }

    /// updateCompletionStatus 테스트
    @Test("updateCompletionStatus로 완료 상태만 수정")
    func testUpdateCompletionStatus() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        // 책 추가 (읽는 중)
        let testBook = createTestBook(isCompleted: false)
        try await repository.addBook(testBook)

        // 완료 상태로 변경
        let newStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: "좋은 책이었습니다"
        )

        try await repository.updateCompletionStatus(bookId: testBook.id, status: newStatus)

        // 수정 확인
        let fetchedBook = try await repository.fetchBook(by: testBook.id)
        #expect(fetchedBook.completionStatus.isCompleted == true)
        #expect(fetchedBook.completionStatus.reviewAfterCompletion == "좋은 책이었습니다")
    }

    // MARK: - Error Tests

    /// 존재하지 않는 책 조회 시 에러
    @Test("존재하지 않는 책 조회 시 RepositoryError.notFound 발생")
    func testFetchNonexistentBook() async throws {
        let container = try createInMemoryContainer()
        let repository = SwiftDataBookRepository(modelContainer: container)

        let nonexistentId = UUID()

        // 존재하지 않는 ID로 조회 시 에러 발생
        await #expect(throws: RepositoryError.self) {
            _ = try await repository.fetchBook(by: nonexistentId)
        }
    }
}
