//
//  ReadingNotificationScheduling.swift
//  FiveGuyes
//
//  Created by zaehorang on 2026-02-14.
//

protocol ReadingNotificationScheduling {
    func setupAllNotifications(_ readingBook: FGUserBook) async
    func clearRequests() async
}
