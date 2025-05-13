//
//  SessionModeSelectionView.swift
//  HaptiTalkWatch Watch App
//
//  Created on 5/13/25.
//

import SwiftUI

struct SessionModeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let sessionModes = ["소개팅 모드", "회의 모드", "발표 모드", "사용자 지정"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("세션 모드 선택")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)
                
                ForEach(sessionModes, id: \.self) { mode in
                    Button(action: {
                        // 선택한 모드로 세션 시작
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(mode)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0))) // #212121
                            )
                    }
                }
                
                Button(action: {
                    // 취소
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("취소")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color.black)
    }
}

struct SessionModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionModeSelectionView()
    }
} 