import AVFoundation
import Foundation
import SwiftUI

@MainActor
class WhisperState: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isModelLoaded = false
    @Published var canTranscribe = false
    @Published var isRecording = false
    @Published var transcribedText = ""
    
    private var whisperContext: WhisperContext?
    private let recorder = Recorder()
    private var recordedFile: URL? = nil
    
    private var modelUrl: URL? {
        Bundle.main.url(forResource: "ggml-large-v3", withExtension: "bin", subdirectory: "models")
    }
    
    private enum LoadError: Error {
        case couldNotLocateModel
    }
    
    override init() {
        super.init()
    }
    
    func loadModel() {
        if let modelUrl {
            do {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path())
                canTranscribe = true
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("Could not locate model")
        }
    }
    
    private func transcribeAudio(_ url: URL) async {
        if !canTranscribe {
            return
        }
        guard let whisperContext else {
            return
        }
        
        do {
            canTranscribe = false
            print("Reading wave samples...\n")
            let data = try readAudioSamples(url)
            print("Transcribing data...\n")
            await whisperContext.fullTranscribe(samples: data)
            transcribedText = await whisperContext.getTranscription()
            print("Done: \(transcribedText)\n")
        } catch {
            print(error.localizedDescription)
        }
        
        canTranscribe = true
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        return try decodeWaveFile(url)
    }
    
    func toggleRecord() async {
        if isRecording {
            await recorder.stopRecording()
            isRecording = false
            if let recordedFile {
                await transcribeAudio(recordedFile)
            }
        } else {
            requestRecordPermission { granted in
                if granted {
                    Task {
                        do {
                            let file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                .appending(path: "output.wav")
                            try await self.recorder.startRecording(toOutputFile: file, delegate: self)
                            self.isRecording = true
                            self.recordedFile = file
                        } catch {
                            print(error.localizedDescription)
                            self.isRecording = false
                        }
                    }
                }
            }
        }
    }
    
    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
#if os(macOS)
        response(true)
#else
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            response(granted)
        }
#endif
    }
    
    // MARK: AVAudioRecorderDelegate
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error {
            Task {
                await handleRecError(error)
            }
        }
    }
    
    private func handleRecError(_ error: Error) {
        print(error.localizedDescription)
        isRecording = false
    }
    
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task {
            await onDidFinishRecording()
        }
    }
    
    private func onDidFinishRecording() {
        isRecording = false
    }
}
