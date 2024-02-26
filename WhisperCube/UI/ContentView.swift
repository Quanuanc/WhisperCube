//
//  ContentView.swift
//  WhisperCube
//
//  Created by cheng on 2024/2/26.
//

import HotKey
import SwiftUI

struct ContentView: View {
    let hotKey = HotKey(key: .a, modifiers: [.control, .command])

    @State private var modelLoaded = false
    @StateObject var whisperState = WhisperState()

    private func toggleRecordAction() {
        Task {
            await whisperState.toggleRecord()
        }
    }

    var body: some View {
        VStack {
            if modelLoaded {
                toggleRecordButton
            } else {
                loadModelButton
            }

            ScrollView {
                Text(verbatim: whisperState.transcribedText)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
            }
        }
        .padding()
    }
}

extension ContentView {
    var toggleRecordButton: some View {
        let titleKey = whisperState.isRecording ? "Stop recording" : "Start recording"
        return Button(titleKey, action: toggleRecordAction)
            .buttonStyle(.bordered)
            .disabled(false)
            .onAppear {
                hotKey.keyDownHandler = toggleRecordAction
            }
    }

    var loadModelButton: some View {
        Button {
            whisperState.loadModel()
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
