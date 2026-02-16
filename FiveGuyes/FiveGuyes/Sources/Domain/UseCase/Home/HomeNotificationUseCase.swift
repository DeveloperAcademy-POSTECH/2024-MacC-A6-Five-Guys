//
//  HomeNotificationUseCase.swift
//  FiveGuyes
//
//  Created by zaehorang on 2/16/26.
//

protocol HomeNotificationUsing {
    func setupNotifications(for readingBook: FGUserBook) async
}

struct HomeNotificationUseCase: HomeNotificationUsing {
    private let notificationScheduler: any ReadingNotificationScheduling

    init(notificationScheduler: any ReadingNotificationScheduling) {
        self.notificationScheduler = notificationScheduler
    }

    func setupNotifications(for readingBook: FGUserBook) async {
        await notificationScheduler.setupAllNotifications(readingBook)
    }
}
