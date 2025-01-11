//
//  SwiftDataBookRepository.swift
//  FiveGuyes
//
//  Created by zaehorang on 1/8/25.
//

import Foundation
import SwiftData

final class SwiftDataBookRepository: BookRepository {
    typealias UserBook = UserBookSchemaV2.UserBookV2
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initial Methods
    
    @MainActor init(modleContainer: ModelContainer) {
        do {
            self.modelContainer = try ModelContainer(
                for: UserBook.self,
                migrationPlan: MigrationPlan.self
            )
            
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchBooks() -> Result<[UserBookDTO], RepositoryError> {
        do {
            let books = try modelContext.fetch(FetchDescriptor<UserBook>())
            let dtos = books.map { $0.toDTO() }
            return .success(dtos)
        } catch {
            return .failure(.fetchFailed)
        }
    }
    
    func fetchBook(by id: UUID) -> Result<UserBookDTO, RepositoryError> {
        switch findSwiftDataBook(by: id) {
        case .success(let book):
            return .success(book.toDTO())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addBook(_ book: UserBookDTO) -> Result<Void, RepositoryError> {
        let swiftDataBook = toSwiftDataBookModel(dto: book)
        modelContext.insert(swiftDataBook)
        
        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func updateBook(_ book: UserBookDTO) -> Result<Void, RepositoryError> {
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
    private func toSwiftDataBookModel(dto: UserBookDTO) -> UserBook {
        let bookMetaData: SDBookMetaData = SDBookMetaData(
            title: dto.bookMetaData.title,
            author: dto.bookMetaData.author,
            coverURL: dto.bookMetaData.coverImageURL,
            totalPages: dto.bookMetaData.totalPages
        )
        
        let userSettings: SDUserSettings = .init(
            startPage: dto.userSettings.startPage,
            targetEndPage: dto.userSettings.targetEndPage,
            startDate: dto.userSettings.startDate,
            targetEndDate: dto.userSettings.targetEndDate,
            nonReadingDays: dto.userSettings.excludedReadingDays
        )
        
        let readingProgress: SDReadingProgress = SDReadingProgress(
            readingRecords: dto.readingProgress.dailyReadingRecords,
            lastReadDate: dto.readingProgress.lastReadDate,
            lastPagesRead: dto.readingProgress.lastReadPage
        )
        
        let completionStatus: SDCompletionStatus = SDCompletionStatus(
            isCompleted: dto.completionStatus.isCompleted,
            completionReview: dto.completionStatus.reviewAfterCompletion
        )
        
        return UserBook(bookMetaData: bookMetaData, userSettings: userSettings, readingProgress: readingProgress, completionStatus: completionStatus)
    }
    
    /// 기존 SwiftData 모델을 DTO로 업데이트
    private func updateSwiftDataModel(_ existingBook: UserBook, with dto: UserBookDTO) {
        existingBook.userSettings.startPage = dto.userSettings.startPage
        existingBook.userSettings.targetEndPage = dto.userSettings.targetEndPage
        existingBook.userSettings.startDate = dto.userSettings.startDate
        existingBook.userSettings.targetEndDate = dto.userSettings.targetEndDate
        existingBook.userSettings.nonReadingDays = dto.userSettings.excludedReadingDays
        
        existingBook.readingProgress.readingRecords = dto.readingProgress.dailyReadingRecords
        existingBook.readingProgress.lastReadDate = dto.readingProgress.lastReadDate
        existingBook.readingProgress.lastPagesRead = dto.readingProgress.lastReadPage
        
        existingBook.completionStatus.isCompleted = dto.completionStatus.isCompleted
        existingBook.completionStatus.completionReview = dto.completionStatus.reviewAfterCompletion
    }
    
    /// 특정 ID로 SwiftData 모델을 조회
    private func findSwiftDataBook(by id: UUID) -> Result<UserBook, RepositoryError> {
        var fetchDescriptor: FetchDescriptor<UserBook> = .init(
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
