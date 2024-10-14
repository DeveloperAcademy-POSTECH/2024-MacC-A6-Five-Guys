//
//  FeedProgressTimer.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/14/24.
//

import Foundation

/// `FeedProgressTimer`는 피드 내 이미지 슬라이드의 진행 상태를 관리하는 타이머 클래스입니다.
/// 이 클래스는 주어진 시간 간격(interval)에 따라 `progress`와 `feedImageIndex`를 업데이트합니다.
@MainActor
class FeedProgressTimer: ObservableObject {
    
    /// 타이머 진행 상태를 나타내는 값입니다. (0.0 ~ 1.0)
    @Published var progress: Double = 0
    @Published var feedImageIndex: Int = 0
    
    var feedImageCount: Int
    /// 타이머가 종료되었을 때 실행할 클로저입니다. 피드가 마지막 이미지에 도달하면 호출됩니다.
    var onFeedFinished: (() -> Void)?
    
    private var interval: TimeInterval
    private var timerTask: Task<Void, Error>?
    
    init(feedImageCount: Int, interval: TimeInterval) {
        self.feedImageCount = feedImageCount
        self.interval = interval
    }
    
    /// 타이머를 시작하는 함수입니다. 타이머는 0.1초마다 progress를 업데이트하며,
    /// 설정된 `feedImageCount`에 도달하면 `onFeedFinished`가 호출됩니다.
    func start() {
        self.cancel() // 기존 타이머가 있으면 취소
        
        let timerStream = self.makeTimerStream()
        
        // 타이머 작업 실행
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            for await _ in timerStream {
                self.handleTimerUpdate()
            }
        }
    }
    
    /// 타이머를 취소하고 progress와 feedImageIndex를 초기화합니다.
    func cancel() {
        self.timerTask?.cancel()
        self.timerTask = nil
        self.resetProgress()
    }
    
    /// 타이머 상태를 업데이트하고, 필요 시 `onFeedFinished`를 호출하는 함수입니다.
    private func handleTimerUpdate() {
        let newProgress = self.progress + (0.1 / self.interval)
        let intNewProgress = Int(newProgress)
        
        // 피드가 끝나면 종료 로직 호출
        if intNewProgress >= self.feedImageCount {
            self.onFeedFinished?()
        }
        
        // progress와 이미지 인덱스 업데이트
        self.progress = newProgress
        if feedImageIndex != intNewProgress {
            self.feedImageIndex = intNewProgress
        }
    }
    
    private func resetProgress() {
        self.progress = 0
        self.feedImageIndex = 0
    }
    
    /// 0.1초마다 타이머 신호를 보내는 비동기 스트림을 생성합니다.
    /// - Returns: 타이머 이벤트를 생성하는 `AsyncStream`
    private func makeTimerStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(0.1))
                    continuation.yield()
                }
                continuation.finish()
            }
        }
    }
}
