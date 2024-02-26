//
//  ContentView.swift
//  WhisperCube
//
//  Created by cheng on 2024/2/26.
//

import SwiftUI

struct ContentView: View {
    @State private var modelLoaded = false

    var body: some View {
        VStack {
            if modelLoaded {
                toggleRecordButton
            } else {
                loadModelButton
            }

            ScrollView {
                Text(verbatim: "Hello, this is a sentence")
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
            }
        }
        .padding()
    }
}

extension ContentView {
    var toggleRecordButton: some View {
        Button {
            print("start")
        } label: {
            Text("Start recording")
        }
        .buttonStyle(.bordered)
        .disabled(true)
    }

    var loadModelButton: some View {
        Button {
            modelLoaded = true
        } label: {
            Text("Load model")
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 300, height: 200)
}
