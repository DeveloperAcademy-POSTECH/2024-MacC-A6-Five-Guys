//
//  DefaultBookManagementService.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-11-01.
//

import Foundation

/// BookManagementService의 기본 구현
///
/// Repository를 통해 데이터 접근하고, ReadingScheduleCalculator를 통해 비즈니스 로직을 처리합니다.
final class DefaultBookManagementService: BookManagementService {

    // MARK: - Properties

    private let repository: BookRepository
    private let notificationManager: NotificationManager
    private let scheduleCalculator: ReadingScheduleCalculatorV2

    // MARK: - Initialization

    init(
        repository: BookRepository,
        notificationManager: NotificationManager = NotificationManager(),
        scheduleCalculator: ReadingScheduleCalculatorV2 = ReadingScheduleCalculatorV2()
    ) {
        self.repository = repository
        self.notificationManager = notificationManager
        self.scheduleCalculator = scheduleCalculator
    }

    // MARK: - Query Operations

    func fetchReadingBooks() async throws -> [FGUserBook] {
        return try await repository.getReadingBooks()
    }

    func fetchCompletedBooks() async throws -> [FGUserBook] {
        return try await repository.getCompletedBooks()
    }

    func fetchBookDetail(id: UUID) async throws -> FGUserBook {
        return try await repository.fetchBook(by: id)
    }

    func rescheduleOnAppOpen(bookId: UUID, today: Date) async throws {
        let currentBook = try await repository.fetchBook(by: bookId)

        let updatedProgress = try scheduleCalculator.rescheduleOnAppOpen(
            settings: currentBook.userSettings,
            progress: currentBook.readingProgress,
            today: today
        )

        guard updatedProgress != currentBook.readingProgress else {
            return
        }

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: currentBook.userSettings,
            readingProgress: updatedProgress,
            completionStatus: currentBook.completionStatus
        )

        try await repository.updateBook(updatedBook)
    }

    // MARK: - Command Operations (향후 구현 예정)

    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook {
        // 1. ReadingScheduleCalculatorV2로 초기 스케줄 계산 (immutable)
        let initialProgress = try scheduleCalculator.createInitialSchedule(settings: input.userSettings)

        // 2. FGUserBook 생성 (초기 스케줄 포함)
        let bookWithSchedule = FGUserBook(
            id: UUID(),
            bookMetaData: input.bookMetaData,
            userSettings: input.userSettings,
            readingProgress: initialProgress,
            completionStatus: FGCompletionStatus(isCompleted: false, reviewAfterCompletion: "")
        )

        // 3. Repository에 저장
        try await repository.addBook(bookWithSchedule)

        // 4. 알림 설정
        await notificationManager.setupAllNotifications(bookWithSchedule)

        return bookWithSchedule
    }

    func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult {
        // 1. 현재 책 정보 조회
        let currentBook = try await repository.fetchBook(by: bookId)

        // 2. 목표 페이지 초과 체크
        if pagesRead > currentBook.userSettings.targetEndPage {
            // 초과 입력 - 사용자가 Alert에서 확인하면 호출됨
            return .exceedsTarget(currentTarget: currentBook.userSettings.targetEndPage)
        }

        // 3. 마지막 날 체크 (날짜 자동 연장 필요 여부)
        let isTodayCompletionDate = Calendar.app.isDate(
            readDate,
            inSameDayAs: currentBook.userSettings.targetEndDate
        )

        if isTodayCompletionDate
            && pagesRead < currentBook.userSettings.targetEndPage {
            // 마지막 날인데 목표를 못 채움 → 날짜 자동 연장
            try await handleDateExtension(
                book: currentBook,
                pagesRead: pagesRead,
                readDate: readDate
            )
            return .dateExtended
        }

        // 4. 일반 기록 처리
        let result = try scheduleCalculator.applyTodayReading(
            settings: currentBook.userSettings,
            progress: currentBook.readingProgress,
            pagesRead: pagesRead,
            date: readDate
        )

        // 5. 업데이트된 책 생성
        let finalSettings = result.updatedSettings ?? currentBook.userSettings

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: finalSettings,
            readingProgress: result.progress,
            completionStatus: currentBook.completionStatus
        )

        // 6. Repository에 저장
        try await repository.updateBook(updatedBook)

        // 7. 알림 재설정
        await notificationManager.setupAllNotifications(updatedBook)

        // 8. 완독 여부 확인
        if pagesRead >= currentBook.userSettings.targetEndPage {
            return .completed(updatedBook: updatedBook)
        } else {
            return .recorded(updatedBook: updatedBook)
        }
    }
    
    func deleteBook(id: UUID) async throws {
        // 1. Repository에서 삭제
        try await repository.deleteBook(by: id)

        // 2. 남은 읽는 책 기준으로 알림 상태를 재구성
        let remainingReadingBooks = try await repository.getReadingBooks()
        if let nextReadingBook = remainingReadingBooks.first {
            await notificationManager.setupAllNotifications(nextReadingBook)
        } else {
            await notificationManager.clearRequests()
        }
    }

    func completeBook(id: UUID, completionDate: Date, review: String) async throws {
        // 1. 현재 책 정보 조회
        let currentBook = try await repository.fetchBook(by: id)

        // 2. 완독 상태 업데이트
        let updatedStatus = FGCompletionStatus(
            isCompleted: true,
            reviewAfterCompletion: review
        )

        // 3. 완독 날짜를 설정에 반영
        var updatedSettings = currentBook.userSettings

        // 시작일이 완독일보다 미래인 경우 → 시작일과 종료일을 모두 완독일로 설정
        if currentBook.userSettings.startDate > completionDate {
            updatedSettings = FGUserSetting(
                startPage: currentBook.userSettings.startPage,
                targetEndPage: currentBook.userSettings.targetEndPage,
                startDate: completionDate,
                targetEndDate: completionDate,
                excludedReadingDays: currentBook.userSettings.excludedReadingDays
            )
        } else {
            // 정상적인 경우 → 종료일만 완독일로 설정
            updatedSettings = FGUserSetting(
                startPage: currentBook.userSettings.startPage,
                targetEndPage: currentBook.userSettings.targetEndPage,
                startDate: currentBook.userSettings.startDate,
                targetEndDate: completionDate,
                excludedReadingDays: currentBook.userSettings.excludedReadingDays
            )
        }

        // 4. Repository에 저장
        try await repository.updateCompletionStatus(bookId: id, status: updatedStatus)
        try await repository.updateSettings(bookId: id, settings: updatedSettings)

        // 5. 알림 취소 (완독한 책은 알림 불필요)
        await notificationManager.clearRequests()
    }

    func updateCompletionReview(id: UUID, review: String) async throws {
        let currentBook = try await repository.fetchBook(by: id)

        let updatedStatus = FGCompletionStatus(
            isCompleted: currentBook.completionStatus.isCompleted,
            reviewAfterCompletion: review
        )

        try await repository.updateCompletionStatus(bookId: id, status: updatedStatus)
    }

    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date],
        today: Date
    ) async throws {
        let currentBook = try await repository.fetchBook(by: bookId)

        let newSettings = FGUserSetting(
            startPage: currentBook.userSettings.startPage,
            targetEndPage: currentBook.userSettings.targetEndPage,
            startDate: startDate,
            targetEndDate: targetEndDate,
            excludedReadingDays: excludedReadingDays
        )

        let updatedProgress = try scheduleCalculator.rescheduleForSettingsChange(
            oldSettings: currentBook.userSettings,
            newSettings: newSettings,
            progress: currentBook.readingProgress,
            today: today
        )

        let updatedBook = FGUserBook(
            id: currentBook.id,
            bookMetaData: currentBook.bookMetaData,
            userSettings: newSettings,
            readingProgress: updatedProgress,
            completionStatus: currentBook.completionStatus
        )

        try await repository.updateBook(updatedBook)

        await notificationManager.setupAllNotifications(updatedBook)
    }

    // MARK: - Private Helper Methods

    /// 목표 날짜 자동 연장 처리
    private func handleDateExtension(
        book: FGUserBook,
        pagesRead: Int,
        readDate: Date
    ) async throws {
        // 목표 날짜를 하루 연장
        let extendedSettings = FGUserSetting(
            startPage: book.userSettings.startPage,
            targetEndPage: book.userSettings.targetEndPage,
            startDate: book.userSettings.startDate,
            targetEndDate: book.userSettings.targetEndDate.addDays(1),
            excludedReadingDays: book.userSettings.excludedReadingDays
        )

        // 읽기 진행 상황 업데이트
        let result = try scheduleCalculator.applyTodayReading(
            settings: extendedSettings,
            progress: book.readingProgress,
            pagesRead: pagesRead,
            date: readDate
        )

        // 최종 설정 (제외일이 변경되었을 수 있음)
        let finalSettings = result.updatedSettings ?? extendedSettings

        // 업데이트된 책 생성
        let updatedBook = FGUserBook(
            id: book.id,
            bookMetaData: book.bookMetaData,
            userSettings: finalSettings,
            readingProgress: result.progress,
            completionStatus: book.completionStatus
        )

        // Repository에 저장
        try await repository.updateBook(updatedBook)

        // 알림 재설정
        await notificationManager.setupAllNotifications(updatedBook)
    }
}
