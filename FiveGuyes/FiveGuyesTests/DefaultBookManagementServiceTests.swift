//
//  DefaultBookManagementServiceTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2025-11-01.
//

@testable import FiveGuyes
import Foundation
import Testing

/// DefaultBookManagementService의 조회 기능에 대한 테스트
@Suite("DefaultBookManagementService 테스트")
struct DefaultBookManagementServiceTests {
    // MARK: - Helper Methods

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

    // MARK: - Query Tests

    /// fetchReadingBooks 테스트: 읽는 중인 책만 조회
    @Test("fetchReadingBooks로 읽는 중인 책만 조회")
    func testFetchReadingBooks() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // Mock 데이터 설정: 읽는 중 2개, 완료 1개
        let readingBook1 = createTestBook(title: "읽는 중1", isCompleted: false)
        let readingBook2 = createTestBook(title: "읽는 중2", isCompleted: false)
        let completedBook = createTestBook(title: "완료됨", isCompleted: true)
        await mockRepository.setBooks([readingBook1, readingBook2, completedBook])

        // 테스트 실행
        let result = try await service.fetchReadingBooks()

        // 검증
        #expect(result.count == 2)
        #expect(result.contains(where: { $0.bookMetaData.title == "읽는 중1" }))
        #expect(result.contains(where: { $0.bookMetaData.title == "읽는 중2" }))
        #expect(!result.contains(where: { $0.bookMetaData.title == "완료됨" }))
    }

    /// fetchCompletedBooks 테스트: 완독한 책만 조회
    @Test("fetchCompletedBooks로 완독한 책만 조회")
    func testFetchCompletedBooks() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // Mock 데이터 설정: 읽는 중 1개, 완료 2개
        let readingBook = createTestBook(title: "읽는 중", isCompleted: false)
        let completedBook1 = createTestBook(title: "완료1", isCompleted: true)
        let completedBook2 = createTestBook(title: "완료2", isCompleted: true)
        await mockRepository.setBooks([readingBook, completedBook1, completedBook2])

        // 테스트 실행
        let result = try await service.fetchCompletedBooks()

        // 검증
        #expect(result.count == 2)
        #expect(result.contains(where: { $0.bookMetaData.title == "완료1" }))
        #expect(result.contains(where: { $0.bookMetaData.title == "완료2" }))
        #expect(!result.contains(where: { $0.bookMetaData.title == "읽는 중" }))
    }

    /// fetchBookDetail 테스트: 특정 책 조회
    @Test("fetchBookDetail로 특정 책 상세 조회")
    func testFetchBookDetail() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // Mock 데이터 설정
        let testBook = createTestBook(title: "테스트 책", author: "테스트 작가")
        await mockRepository.setBooks([testBook])

        // 테스트 실행
        let result = try await service.fetchBookDetail(id: testBook.id)

        // 검증
        #expect(result.id == testBook.id)
        #expect(result.bookMetaData.title == "테스트 책")
        #expect(result.bookMetaData.author == "테스트 작가")
    }

    /// fetchBookDetail 테스트: 존재하지 않는 책 조회 시 에러
    @Test("fetchBookDetail로 존재하지 않는 책 조회 시 에러 발생")
    func testFetchBookDetailNotFound() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        let nonexistentId = UUID()

        // 존재하지 않는 ID로 조회 시 에러 발생
        await #expect(throws: RepositoryError.self) {
            _ = try await service.fetchBookDetail(id: nonexistentId)
        }
    }

    /// 빈 목록 테스트: 책이 없을 때 빈 배열 반환
    @Test("책이 없을 때 빈 배열 반환")
    func testFetchEmptyBooks() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // Mock 데이터 없음
        await mockRepository.setBooks([])

        // 읽는 중인 책 조회
        let readingBooks = try await service.fetchReadingBooks()
        #expect(readingBooks.isEmpty)

        // 완료된 책 조회
        let completedBooks = try await service.fetchCompletedBooks()
        #expect(completedBooks.isEmpty)
    }

    // MARK: - Command Tests

    /// registerBook 테스트: 책 등록 시 Repository에 저장되는지 검증
    @Test("registerBook로 책 등록 시 Repository에 저장됨")
    func testRegisterBook() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // RegisterBookInput 생성
        let input = RegisterBookInput(
            bookMetaData: FGBookMetaData(
                title: "테스트 책",
                author: "테스트 작가",
                coverImageURL: "https://example.com/cover.jpg",
                totalPages: 300
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 300,
                startDate: makeDate("2025-01-01"),
                targetEndDate: makeDate("2025-01-31"),
                excludedReadingDays: []
            )
        )

        // 책 등록
        let registeredBook = try await service.registerBook(input)

        // 검증: Repository에 책이 저장되었는지 확인
        let booksInRepo = await mockRepository.books
        #expect(booksInRepo.count == 1)
        #expect(booksInRepo.first?.id == registeredBook.id)
        #expect(booksInRepo.first?.bookMetaData.title == "테스트 책")
    }

    /// registerBook 테스트: 초기 스케줄이 계산되는지 검증
    @Test("registerBook로 책 등록 시 초기 스케줄이 계산됨")
    func testRegisterBookWithScheduleCalculation() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // RegisterBookInput 생성 (10일 동안 300페이지 읽기)
        let input = RegisterBookInput(
            bookMetaData: FGBookMetaData(
                title: "스케줄 테스트",
                author: "작가",
                coverImageURL: nil,
                totalPages: 300
            ),
            userSettings: FGUserSetting(
                startPage: 1,
                targetEndPage: 300,
                startDate: makeDate("2025-01-01"),
                targetEndDate: makeDate("2025-01-10"),
                excludedReadingDays: []
            )
        )

        // 책 등록
        let registeredBook = try await service.registerBook(input)

        // 검증: ReadingProgress에 스케줄이 계산되었는지 확인
        #expect(!registeredBook.readingProgress.dailyReadingRecords.isEmpty)

        // 첫 날 기록 확인
        let firstDateKey = makeDate("2025-01-01").toYearMonthDayString()
        let firstRecord = registeredBook.readingProgress.dailyReadingRecords[firstDateKey]
        #expect(firstRecord != nil)
        #expect(firstRecord!.targetPages > 0)
    }

    /// deleteBook 테스트: 책 삭제 시 Repository에서 제거되는지 검증
    @Test("deleteBook로 책 삭제 시 Repository에서 제거됨")
    func testDeleteBook() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 테스트용 책 추가
        let testBook = createTestBook(title: "삭제할 책", isCompleted: false)
        await mockRepository.setBooks([testBook])

        // 책이 있는지 확인
        var booksInRepo = await mockRepository.books
        #expect(booksInRepo.count == 1)

        // 책 삭제
        try await service.deleteBook(id: testBook.id)

        // 검증: Repository에서 책이 제거되었는지 확인
        booksInRepo = await mockRepository.books
        #expect(booksInRepo.isEmpty)
    }

    /// deleteBook 테스트: 존재하지 않는 책 삭제 시 에러 발생 안 함
    @Test("deleteBook로 존재하지 않는 책 삭제 시 에러 없이 처리")
    func testDeleteNonexistentBook() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        let nonexistentId = UUID()

        // 존재하지 않는 책 삭제 (MockRepository는 에러를 발생시키지 않고 무시)
        try await service.deleteBook(id: nonexistentId)

        // 검증: 에러 없이 완료되면 성공
        let booksInRepo = await mockRepository.books
        #expect(booksInRepo.isEmpty)
    }

    // MARK: - recordReading Tests (STEP 5)

    /// recordReading 테스트: 일반적인 독서 기록
    @Test("recordReading로 일반적인 독서 기록")
    func testRecordReading_normal() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록 (300페이지, 10일)
        let testBook = createTestBook(totalPages: 300)
        await mockRepository.setBooks([testBook])

        // 1월 2일에 50페이지 기록
        let recordDate = makeDate("2025-01-02")
        let result = try await service.recordReading(
            bookId: testBook.id,
            pagesRead: 50,
            readDate: recordDate
        )

        // 검증: 일반 기록 결과
        switch result {
        case .recorded(let updatedBook):
            #expect(updatedBook.readingProgress.lastReadPage == 50)
            #expect(updatedBook.readingProgress.lastReadDate == recordDate)
        default:
            Issue.record("Expected .recorded, got \(result)")
        }
    }

    /// recordReading 테스트: 완독 케이스
    @Test("recordReading로 완독 처리")
    func testRecordReading_completion() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록 (300페이지)
        let testBook = createTestBook(totalPages: 300)
        await mockRepository.setBooks([testBook])

        // 300페이지 완독
        let recordDate = makeDate("2025-01-15")
        let result = try await service.recordReading(
            bookId: testBook.id,
            pagesRead: 300,
            readDate: recordDate
        )

        // 검증: 완독 결과
        switch result {
        case .completed(let updatedBook):
            #expect(updatedBook.readingProgress.lastReadPage >= 300)
        default:
            Issue.record("Expected .completed, got \(result)")
        }
    }

    /// recordReading 테스트: 날짜 자동 연장 (마지막 날에 목표 미달)
    @Test("recordReading로 마지막 날 목표 미달 시 날짜 자동 연장")
    func testRecordReading_dateExtension() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록 (300페이지, 종료일: 1월 31일)
        let testBook = createTestBook(totalPages: 300)
        await mockRepository.setBooks([testBook])

        // 마지막 날(1월 31일)에 200페이지만 기록 (목표 미달)
        let lastDate = makeDate("2025-01-31")
        let result = try await service.recordReading(
            bookId: testBook.id,
            pagesRead: 200,
            readDate: lastDate
        )

        // 검증: 날짜 연장 결과
        switch result {
        case .dateExtended:
            // 날짜가 연장되었는지 Repository에서 확인
            let updatedBook = try await mockRepository.fetchBook(by: testBook.id)
            let expectedNewEndDate = makeDate("2025-02-01")
            #expect(updatedBook.userSettings.targetEndDate == expectedNewEndDate)
        default:
            Issue.record("Expected .dateExtended, got \(result)")
        }
    }

    /// recordReading 테스트: 목표 페이지 초과
    @Test("recordReading로 목표 페이지 초과 시 exceedsTarget 반환")
    func testRecordReading_exceedsTarget() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록 (300페이지)
        let testBook = createTestBook(totalPages: 300)
        await mockRepository.setBooks([testBook])

        // 350페이지 기록 (초과)
        let recordDate = makeDate("2025-01-15")
        let result = try await service.recordReading(
            bookId: testBook.id,
            pagesRead: 350,
            readDate: recordDate
        )

        // 검증: 초과 결과
        switch result {
        case .exceedsTarget(let currentTarget):
            #expect(currentTarget == 300)
        default:
            Issue.record("Expected .exceedsTarget, got \(result)")
        }
    }

    // MARK: - completeBook Tests

    /// completeBook 테스트: 정상적인 완독 처리
    @Test("completeBook로 정상적인 완독 처리")
    func testCompleteBook() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록
        let testBook = createTestBook(totalPages: 300, isCompleted: false)
        await mockRepository.setBooks([testBook])

        // 완독 처리
        let completionDate = makeDate("2025-01-20")
        let review = "좋은 책이었습니다!"
        try await service.completeBook(
            id: testBook.id,
            completionDate: completionDate,
            review: review
        )

        // 검증: 완독 상태 업데이트 확인
        let updatedBook = try await mockRepository.fetchBook(by: testBook.id)
        #expect(updatedBook.completionStatus.isCompleted == true)
        #expect(updatedBook.completionStatus.reviewAfterCompletion == review)
        #expect(updatedBook.userSettings.targetEndDate == completionDate)
    }

    /// completeBook 테스트: 시작일이 완독일보다 미래인 경우
    @Test("completeBook로 시작일이 완독일보다 미래인 경우 처리")
    func testCompleteBook_futureStartDate() async throws {
        let mockRepository = MockBookRepository()
        let service = DefaultBookManagementService(repository: mockRepository)

        // 책 등록 (시작일: 2025-01-10, 종료일: 2025-01-31)
        var testBook = createTestBook(totalPages: 300, isCompleted: false)
        testBook.userSettings = FGUserSetting(
            startPage: 1,
            targetEndPage: 300,
            startDate: makeDate("2025-01-10"),
            targetEndDate: makeDate("2025-01-31"),
            excludedReadingDays: []
        )
        await mockRepository.setBooks([testBook])

        // 완독일을 시작일보다 이전으로 설정 (2025-01-05)
        let earlyCompletionDate = makeDate("2025-01-05")
        try await service.completeBook(
            id: testBook.id,
            completionDate: earlyCompletionDate,
            review: "빨리 읽었어요"
        )

        // 검증: 시작일과 종료일이 모두 완독일로 설정됨
        let updatedBook = try await mockRepository.fetchBook(by: testBook.id)
        #expect(updatedBook.userSettings.startDate == earlyCompletionDate)
        #expect(updatedBook.userSettings.targetEndDate == earlyCompletionDate)
    }
}
