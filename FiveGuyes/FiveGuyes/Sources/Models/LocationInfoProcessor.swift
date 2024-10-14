//
//  LocationInfoProcessor.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import CoreLocation
import ImageIO

class LocationInfoProcessor {
    static func processGPSInfo(from properties: [String: Any], imageDate: Date?) async -> String? {
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            print("❌ GPSInfoProcessor/processGPSInfo: GPS 데이터가 없습니다 - 문제 발생")
            return nil
        }
        
        return await getLocationName(latitude: latitude, longitude: longitude)
    }
    private static func getLocationName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            let fullLocationName = placemarks.first.map { placemark in
                [placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.name]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
            return fullLocationName?.trimmingCharacters(in: .whitespaces)
        } catch {
            print("❌ GPSInfoProcessor/getLocationName: 역지오코딩 중 오류 발생 - \(error)")
            return nil
        }
    }
}
