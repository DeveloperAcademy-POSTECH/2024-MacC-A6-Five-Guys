//
//  LocationInfoProcessor.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/14/24.
//

import CoreLocation
import ImageIO

class LocationInfoProcessor {
    static func processGPSInfo(from properties: [String: Any], imageDate: Date?, completion: @escaping (String?) -> Void) {
        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            print("❌ GPSInfoProcessor/processGPSInfo: GPS 데이터가 없습니다 - 문제 발생")
            completion(nil)
            return
        }

        Task {
            let locationName = await getLocationName(latitude: latitude, longitude: longitude)
            completion(locationName)
        }
    }

    private static func getLocationName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let fullLocationName = placemarks?.first.map { placemark in
                    [placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.name]
                        .compactMap { $0 }
                        .joined(separator: " ")
                } ?? nil
                continuation.resume(returning: fullLocationName?.trimmingCharacters(in: .whitespaces))
            }
        }
    }
}
