//
//  BookManagementUseCasesQueryAndRegistrationTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/14/26.
//

@testable import FiveGuyes
import Foundation
import Testing

extension BookManagementUseCasesTests {
    @Test("ReadingLibraryUseCase.fetchLibrarySnapshot로 읽는 중/완독 책 분리 조회")
    func testFetchLibrarySnapshot() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

        let readingBook1 = createTestBook(title: "읽는 중1", isCompleted: false)
        let readingBook2 = createTestBook(title: "읽는 중2", isCompleted: false)
        let completedBook = createTestBook(title: "완료됨", isCompleted: true)
        await mockRepository.setBooks([readingBook1, readingBook2, completedBook])

        let snapshot = try await useCase.fetchLibrarySnapshot()

        #expect(snapshot.readingBooks.count == 2)
        #expect(snapshot.completedBooks.count == 1)
        #expect(snapshot.readingBooks.contains(where: { $0.bookMetaData.title == "읽는 중1" }))
        #expect(snapshot.readingBooks.contains(where: { $0.bookMetaData.title == "읽는 중2" }))
        #expect(snapshot.completedBooks.contains(where: { $0.bookMetaData.title == "완료됨" }))
    }

    @Test("FetchBookDetailUseCase로 특정 책 상세 조회")
    func testFetchBookDetail() async throws {
        let mockRepository = MockBookRepository()
        let useCase = FetchBookDetailUseCase(repository: mockRepository)

        let testBook = createTestBook(title: "테스트 책", author: "테스트 작가")
        await mockRepository.setBooks([testBook])

        let result = try await useCase.execute(id: testBook.id)

        #expect(result.id == testBook.id)
        #expect(result.bookMetaData.title == "테스트 책")
        #expect(result.bookMetaData.author == "테스트 작가")
    }

    @Test("FetchBookDetailUseCase로 존재하지 않는 책 조회 시 에러 발생")
    func testFetchBookDetailNotFound() async throws {
        let mockRepository = MockBookRepository()
        let useCase = FetchBookDetailUseCase(repository: mockRepository)

        await #expect(throws: RepositoryError.self) {
            _ = try await useCase.execute(id: UUID())
        }
    }

    @Test("책이 없을 때 ReadingLibraryUseCase.fetchLibrarySnapshot은 빈 결과를 반환")
    func testFetchEmptySnapshot() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

        await mockRepository.setBooks([])
        let snapshot = try await useCase.fetchLibrarySnapshot()

        #expect(snapshot.readingBooks.isEmpty)
        #expect(snapshot.completedBooks.isEmpty)
    }

    @Test("BookRegistrationUseCase.registerBook로 책 등록 시 Repository 저장 및 알림 설정")
    func testRegisterBook() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeBookRegistrationUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

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

        let registeredBook = try await useCase.registerBook(input)

        let booksInRepo = await mockRepository.books
        let setupCount = await schedulerSpy.setupCount()
        let lastSetupBook = await schedulerSpy.lastSetupBook()

        #expect(booksInRepo.count == 1)
        #expect(booksInRepo.first?.id == registeredBook.id)
        #expect(booksInRepo.first?.bookMetaData.title == "테스트 책")
        #expect(setupCount == 1)
        #expect(lastSetupBook?.id == registeredBook.id)
    }

    @Test("BookRegistrationUseCase.registerBook로 책 등록 시 초기 스케줄이 계산됨")
    func testRegisterBookWithScheduleCalculation() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeBookRegistrationUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

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

        let registeredBook = try await useCase.registerBook(input)

        #expect(!registeredBook.readingProgress.dailyReadingRecords.isEmpty)
        let firstDateKey = makeDate("2025-01-01").toYearMonthDayString()
        let firstRecord = registeredBook.readingProgress.dailyReadingRecords[firstDateKey]
        #expect(firstRecord != nil)
        #expect(firstRecord!.targetPages > 0)
    }

    @Test("ReadingLibraryUseCase.deleteBook으로 책 삭제 시 Repository에서 제거")
    func testDeleteBook() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

        let testBook = createTestBook(title: "삭제할 책", isCompleted: false)
        await mockRepository.setBooks([testBook])

        var booksInRepo = await mockRepository.books
        #expect(booksInRepo.count == 1)

        try await useCase.deleteBook(id: testBook.id)

        booksInRepo = await mockRepository.books
        let clearCount = await schedulerSpy.clearCount()

        #expect(booksInRepo.isEmpty)
        #expect(clearCount == 1)
    }

    @Test("ReadingLibraryUseCase.deleteBook으로 존재하지 않는 책 삭제 시 에러 없이 처리")
    func testDeleteNonexistentBook() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy
        )

        try await useCase.deleteBook(id: UUID())

        let booksInRepo = await mockRepository.books
        let clearCount = await schedulerSpy.clearCount()

        #expect(booksInRepo.isEmpty)
        #expect(clearCount == 1)
    }

    @Test("ReadingLibraryUseCase.today는 내부 todayProvider 값을 반환")
    func testReadingLibraryToday() {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let todayProvider = ReadingDateProviderStub(todayValue: makeDate("2025-01-10"))
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy,
            todayProvider: todayProvider
        )

        #expect(useCase.today() == makeDate("2025-01-10"))
    }

    @Test("ReadingLibraryUseCase.rescheduleOnAppOpen은 내부 todayProvider를 통해 기준일을 해상한다")
    func testRescheduleOnAppOpenUsesTodayProvider() async throws {
        let mockRepository = MockBookRepository()
        let schedulerSpy = NotificationSchedulerSpy()
        let todayProvider = ReadingDateProviderSpy(todayValue: makeDate("2025-01-10"))
        let useCase = makeReadingLibraryUseCase(
            repository: mockRepository,
            notificationScheduler: schedulerSpy,
            todayProvider: todayProvider
        )

        let testBook = createTestBook(totalPages: 300, isCompleted: false)
        await mockRepository.setBooks([testBook])

        try await useCase.rescheduleOnAppOpen(bookId: testBook.id)

        #expect(todayProvider.callCount == 1)
    }
}
