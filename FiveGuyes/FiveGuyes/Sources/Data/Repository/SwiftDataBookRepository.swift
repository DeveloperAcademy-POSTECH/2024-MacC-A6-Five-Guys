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
    
    func fetchBooks() -> Result<[FGUserBook], RepositoryError> {
        do {
            let swiftDatabooks = try modelContext.fetch(FetchDescriptor<SDUserBook>())
            let books = swiftDatabooks.map { $0.toFGUserBook() }
            return .success(books)
        } catch {
            return .failure(.fetchFailed)
        }
    }
    
    func fetchBook(by id: UUID) -> Result<FGUserBook, RepositoryError> {
        switch findSwiftDataBook(by: id) {
        case .success(let book):
            return .success(book.toFGUserBook())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addBook(_ book: FGUserBook) -> Result<Void, RepositoryError> {
        let swiftDataBook = book.toUserBookV2()
        modelContext.insert(swiftDataBook)
        
        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.saveFailed)
        }
    }
    
    func updateBook(_ book: FGUserBook) -> Result<Void, RepositoryError> {
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
    
    /// UserBook으로 기존 SwiftData 모델을  업데이트
    private func updateSwiftDataModel(_ existingBook: SDUserBook, with book: FGUserBook) {
        existingBook.userSettings = book.userSettings.toUserSettings()
        existingBook.readingProgress = book.readingProgress.toReadingProgress()
        existingBook.completionStatus = book.completionStatus.toCompletionStatus()
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
