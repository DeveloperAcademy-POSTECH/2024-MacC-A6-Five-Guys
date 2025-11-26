//
//  BookManagementService.swift
//  FiveGuyes
//
//  Created by zaehorang on 2025-11-01.
//

import Foundation

/// "내 서재" 관리 비즈니스 로직을 담당하는 서비스
///
/// 책 등록, 독서 기록, 삭제, 완료 등 독서 관련 모든 비즈니스 규칙을 단일화합니다.
protocol BookManagementService {

    // MARK: - Command (쓰기 작업)

    /// 새로운 책을 등록하고 초기 독서 스케줄을 생성합니다.
    /// - Parameter input: 책 메타데이터와 사용자 설정
    /// - Returns: 등록된 책 (초기 Progress 포함)
    /// - Throws: 등록 실패 시 에러
    func registerBook(_ input: RegisterBookInput) async throws -> FGUserBook

    /// 독서 기록을 저장하고, 필요 시 스케줄을 재분배합니다.
    /// - Parameters:
    ///   - bookId: 책 ID
    ///   - pagesRead: 읽은 페이지 수
    ///   - readDate: 독서 날짜
    /// - Returns: 기록 결과 (완독, 일반 기록, 날짜 연장, 목표 초과)
    /// - Throws: 기록 실패 시 에러
    func recordReading(bookId: UUID, pagesRead: Int, readDate: Date) async throws -> RecordReadingResult

    /// 책을 삭제하고 관련 알림을 취소합니다.
    /// - Parameter id: 삭제할 책 ID
    /// - Throws: 삭제 실패 시 에러
    func deleteBook(id: UUID) async throws

    /// 책을 완독 처리하고 알림을 취소합니다.
    /// - Parameters:
    ///   - id: 완료할 책 ID
    ///   - completionDate: 완독 날짜
    ///   - review: 완독 소감
    /// - Throws: 완료 처리 실패 시 에러
    func completeBook(id: UUID, completionDate: Date, review: String) async throws

    // MARK: - Query (읽기 작업)

    /// 읽는 중인 책 목록을 조회합니다.
    /// - Returns: 읽는 중인 책 목록
    /// - Throws: 조회 실패 시 에러
    func fetchReadingBooks() async throws -> [FGUserBook]

    /// 완독한 책 목록을 조회합니다.
    /// - Returns: 완독한 책 목록
    /// - Throws: 조회 실패 시 에러
    func fetchCompletedBooks() async throws -> [FGUserBook]

    /// 특정 책의 상세 정보를 조회합니다.
    /// - Parameter id: 조회할 책 ID
    /// - Returns: 책 상세 정보
    /// - Throws: 조회 실패 시 에러
    func fetchBookDetail(id: UUID) async throws -> FGUserBook
}
