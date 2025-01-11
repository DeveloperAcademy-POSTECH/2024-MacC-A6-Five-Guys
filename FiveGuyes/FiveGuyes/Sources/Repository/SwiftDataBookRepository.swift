//
//  SwiftDataBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation
import SwiftData

final class SwiftDataBookRepository: BookRepository {
    typealias SDUserBook = UserBookSchemaV2.UserBookV2
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initial Methods
    
    @MainActor init(modleContainer: ModelContainer) {
        do {
            self.modelContainer = try ModelContainer(
                for: SDUserBook.self,
                migrationPlan: MigrationPlan.self
            )
            
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchBooks() -> Result<[UserBook1], RepositoryError> {
        do {
            let swiftDatabooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            let books = swiftDatabooks.map { $0.toUserBook() }
            return .success(books)
        } catch {
            return .failure(.fetchFailed)
        }
    }
    
    func fetchBook(by id: UUID) -> Result<UserBook1, RepositoryError> {
        switch findSwiftDataBook(by: id) {
        case .success(let book):
            return .success(book.toUserBook())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addBook(_ book: UserBook1) -> Result<Void, RepositoryError> {
        let swiftDataBook = toSwiftDataBookModel(book)
        modelContext.insert(swiftDataBook)
        
        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func updateBook(_ book: UserBook1) -> Result<Void, RepositoryError> {
        switch findSwiftDataBook(by: book.id) {
        case .success(let swiftDataBook):
            // 기존 책 데이터를 DTO를 기준으로 업데이트
            updateSwiftDataModel(swiftDataBook, with: book)
            
            // 저장
            do {
                try modelContext.save()
                return .success(())
            } catch {
                return .failure(.updateFailed)
            }
            
        case .failure(let error):
            // 책을 찾지 못했거나 다른 에러 발생 시
            return .failure(error)
        }
    }
    
    func deleteBook(by id: UUID) -> Result<Void, RepositoryError> {
        switch findSwiftDataBook(by: id) {
        case .success(let swiftDataBook):
            do {
                modelContext.delete(swiftDataBook)
                try modelContext.save()
                return .success(())
            } catch {
                return .failure(.deleteFailed)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// DTO를 SwiftData 모델로 변환
    private func toSwiftDataBookModel(_ book: UserBook1) -> SDUserBook {
        let bookMetaData: BookMetaData = BookMetaData(
            title: book.bookMetaData.title,
            author: book.bookMetaData.author,
            coverURL: book.bookMetaData.coverImageURL,
            totalPages: book.bookMetaData.totalPages
        )
        
        let userSettings: UserSettings = .init(
            startPage: book.userSettings.startPage,
            targetEndPage: book.userSettings.targetEndPage,
            startDate: book.userSettings.startDate,
            targetEndDate: book.userSettings.targetEndDate,
            nonReadingDays: book.userSettings.excludedReadingDays
        )
        
        let readingProgress: ReadingProgress = ReadingProgress(
            readingRecords: book.readingProgress.dailyReadingRecords,
            lastReadDate: book.readingProgress.lastReadDate,
            lastPagesRead: book.readingProgress.lastReadPage
        )
        
        let completionStatus: CompletionStatus = CompletionStatus(
            isCompleted: book.completionStatus.isCompleted,
            completionReview: book.completionStatus.reviewAfterCompletion
        )
        
        return SDUserBook(bookMetaData: bookMetaData, userSettings: userSettings, readingProgress: readingProgress, completionStatus: completionStatus)
    }
    
    /// UserBook으로 기존 SwiftData 모델을  업데이트
    private func updateSwiftDataModel(_ existingBook: SDUserBook, with book: UserBook1) {
        existingBook.userSettings.startPage = book.userSettings.startPage
        existingBook.userSettings.targetEndPage = book.userSettings.targetEndPage
        existingBook.userSettings.startDate = book.userSettings.startDate
        existingBook.userSettings.targetEndDate = book.userSettings.targetEndDate
        existingBook.userSettings.nonReadingDays = book.userSettings.excludedReadingDays
        
        existingBook.readingProgress.readingRecords = book.readingProgress.dailyReadingRecords
        existingBook.readingProgress.lastReadDate = book.readingProgress.lastReadDate
        existingBook.readingProgress.lastPagesRead = book.readingProgress.lastReadPage
        
        existingBook.completionStatus.isCompleted = book.completionStatus.isCompleted
        existingBook.completionStatus.completionReview = book.completionStatus.reviewAfterCompletion
    }
    
    /// 특정 ID로 SwiftData 모델을 조회
    private func findSwiftDataBook(by id: UUID) -> Result<SDUserBook, RepositoryError> {
        var fetchDescriptor: FetchDescriptor<SDUserBook> = .init(
            predicate: #Predicate { book in
                book.id == id
            }
        )
        fetchDescriptor.fetchLimit = 1
        
        do {
            let books = try modelContext.fetch(fetchDescriptor)
            guard let book = books.first else {
                return .failure(.notFound)
            }
            return .success(book)
        } catch {
            return .failure(.fetchFailed)
        }
    }
}
