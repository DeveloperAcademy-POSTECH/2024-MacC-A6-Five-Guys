//
//  TestingMetaView.swift
//  FiveGuyes
//
//  Created by 신혜연 on 10/7/24.
//

import ImageIO
import Photos
import SwiftUI

struct TestingMetaView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var imageMetadata: [String: Any]?
    
    init() {
        checkAuthorizationStatus() // 권한 확인
    }
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("이미지가 선택되지 않았습니다.")
                    .padding()
            }
            
            if let metadata = imageMetadata {
                // 메타데이터에서 EXIF 정보 가져오기
                if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
                   let date = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                    
                    // 날짜 포맷팅
                    let imageDate = formatDate(from: date)
                    
                    VStack {
                        Text("이미지 날짜: \(imageDate.dateString)")
                            .padding()
                        Text("이미지 시간: \(imageDate.timeString)")
                            .padding()
                    }
                } else {
                    Text("EXIF 정보 없음")
                        .padding()
                }
                
                if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                    let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double
                    let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double
                    
                    if let latitude = latitude, let longitude = longitude {
                        Text("위치 정보: 위도 \(latitude), 경도 \(longitude)")
                            .padding()
                    } else {
                        Text("위치 정보 없음")
                            .padding()
                    }
                } else {
                    Text("GPS 정보 없음")
                        .padding()
                }
                
                // 추가 메타데이터 정보 출력
                if let pixelWidth = metadata[kCGImagePropertyPixelWidth as String] as? Int,
                   let pixelHeight = metadata[kCGImagePropertyPixelHeight as String] as? Int {
                    Text("이미지 해상도: \(pixelWidth) x \(pixelHeight)")
                        .padding()
                }
            } else {
                Text("메타데이터 없음")
                    .padding()
            }
            
            Button(action: {
                showImagePicker = true
            }, label: {
                Text("이미지 선택")
            })
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, imageMetadata: $imageMetadata)
            }
        }
    }
    
    struct FormattedDate {
        var dateString: String
        var timeString: String
    }
    
    // 날짜 포맷팅 함수
    func formatDate(from dateString: String) -> FormattedDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss" // EXIF 날짜 형식
        
        if let imageDate = dateFormatter.date(from: dateString) {

            dateFormatter.dateFormat = "yyyy년 M월 d일"
            let formattedDate = dateFormatter.string(from: imageDate)
            
            dateFormatter.dateFormat = "H시 m분"
            let formattedTime = dateFormatter.string(from: imageDate)
            
            return FormattedDate(dateString: formattedDate, timeString: formattedTime)
        } else {
            return FormattedDate(dateString: "날짜 형식 변환 실패", timeString: "")
        }
    }
}

func checkAuthorizationStatus() {
    let status = PHPhotoLibrary.authorizationStatus()
    
    if status == .notDetermined {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // 권한이 허용됨
            } else {
                // 권한 거부됨
            }
        }
    }
}
