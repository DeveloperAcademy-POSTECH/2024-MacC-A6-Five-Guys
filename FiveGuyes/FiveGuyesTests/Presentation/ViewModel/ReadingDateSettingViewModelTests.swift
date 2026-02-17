//
//  ReadingDateSettingViewModelTests.swift
//  FiveGuyesTests
//
//  Created by zaehorang on 2/16/26.
//

@testable import FiveGuyes
import Testing

@Suite("ReadingDateSettingViewModel 테스트")
@MainActor
struct ReadingDateSettingViewModelTests {
    @Test("ReadingDateSettingViewModel: 시작/종료일이 없으면 기본 일수 1 반환")
    func readingDateSetting_dayCount_withoutRange_returnsOne() {
        let metricsUseCase = ReadingGoalMetricsUseCaseStub()
        let viewModel = ReadingDateSettingViewModel(readingGoalMetricsUseCase: metricsUseCase)

        let dayCount = viewModel.dayCount(startDate: nil, endDate: nil)

        #expect(dayCount == 1)
        #expect(metricsUseCase.dayCountInputs.isEmpty)
    }

    @Test("ReadingDateSettingViewModel: 페이지/기간 입력으로 일일 페이지 계산 위임")
    func readingDateSetting_pagesPerDay_delegatesToMetricsUseCase() {
        let metricsUseCase = ReadingGoalMetricsUseCaseStub()
        metricsUseCase.dayCountResult = 12
        metricsUseCase.totalPagesResult = 240
        metricsUseCase.pagesPerDayResult = 20
        let viewModel = ReadingDateSettingViewModel(readingGoalMetricsUseCase: metricsUseCase)

        let pagesPerDay = viewModel.pagesPerDay(
            startPage: 1,
            targetEndPage: 240,
            startDate: makeDate("2025-01-01"),
            endDate: makeDate("2025-01-12")
        )

        #expect(pagesPerDay == 20)
        #expect(metricsUseCase.totalPagesInputs.count == 1)
        #expect(metricsUseCase.totalPagesInputs[0].startPage == 1)
        #expect(metricsUseCase.totalPagesInputs[0].targetEndPage == 240)
        #expect(metricsUseCase.dayCountInputs.count == 1)
        #expect(metricsUseCase.pagesPerDayInputs.count == 1)
        #expect(metricsUseCase.pagesPerDayInputs[0].totalPages == 240)
        #expect(metricsUseCase.pagesPerDayInputs[0].totalDays == 12)
    }
}
