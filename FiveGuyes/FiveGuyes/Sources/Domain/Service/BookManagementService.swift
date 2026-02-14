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
    /// - Returns: 기록 결과 (완독, 일반 기록, 날짜 연장, 목표 초과)
    /// - Throws: 기록 실패 시 에러
    func recordReading(bookId: UUID, pagesRead: Int) async throws -> RecordReadingResult

    /// 책을 삭제하고 관련 알림을 취소합니다.
    /// - Parameter id: 삭제할 책 ID
    /// - Throws: 삭제 실패 시 에러
    func deleteBook(id: UUID) async throws

    /// 책을 완독 처리하고 알림을 취소합니다.
    /// - Parameters:
    ///   - id: 완료할 책 ID
    ///   - review: 완독 소감
    /// - Throws: 완료 처리 실패 시 에러
    func completeBook(id: UUID, review: String) async throws

    /// 완독 소감만 수정합니다.
    /// - Parameters:
    ///   - id: 대상 책 ID
    ///   - review: 수정할 소감
    /// - Throws: 수정 실패 시 에러
    func updateCompletionReview(id: UUID, review: String) async throws

    /// 목표 기간/휴일 변경을 반영해 스케줄을 재분배합니다.
    /// - Parameters:
    ///   - bookId: 대상 책 ID
    ///   - startDate: 변경된 시작일
    ///   - targetEndDate: 변경된 종료일
    ///   - excludedReadingDays: 변경된 쉬는 날 목록
    /// - Throws: 재분배 또는 저장 실패 시 에러
    func updateReadingPlan(
        bookId: UUID,
        startDate: Date,
        targetEndDate: Date,
        excludedReadingDays: [Date]
    ) async throws

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

    /// 앱 재진입 시 오늘 기준으로 남은 독서 스케줄을 재분배합니다.
    /// - Parameter bookId: 대상 책 ID
    /// - Throws: 재분배 실패 또는 목표일 초과 에러
    func rescheduleOnAppOpen(bookId: UUID) async throws

    /// 도메인 기준 "오늘"(04:00 경계 보정)을 반환합니다.
    func today() -> Date
}
