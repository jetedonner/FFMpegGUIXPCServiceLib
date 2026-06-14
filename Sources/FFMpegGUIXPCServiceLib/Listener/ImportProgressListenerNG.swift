
//
//  ImportProgressListener.swift
//  FFMpegGUI
//
//  Created by Kim-David Hauser on 19.05.2026.
//


import Foundation
import FFMpegSwiftManagerLib

//@objc(ImportProgressListenerLib)
//public protocol ImportProgressListenerLib: Sendable {
////    func onImportedMedia(_ media: MediaDetailsDTO)
//    func onLogMsg(_ msg: LogMsg)
//    func onImportedMedia(_ media: MediaDetails)
//    func onProgress(_ update: ProgressUpdate)
//    func onCompleted(_ result: ImportResult)
//    // NEW: Send file-specific progress back to the client
//    func onFileIntegrityProgress(id: UUID, progress: Double)
//    func onMediaStateChanged(id: UUID, result: TaskTypeBase)
//}

//@objc(CheckIntegrityProgressListener)
//public protocol CheckIntegrityProgressListener /*: Sendable*/ {
////    func onImportedMedia(_ media: MediaDetails)
////    func onImportedMediaNG(_ media: MediaDetails)
//    func onProgress(_ update: ProgressUpdate)
//    func onCompleted(_ result: ImportResult)
//    func onFileIntegrityProgress(id: UUID, progress: Double)
//    func onMediaStateChanged(id: UUID, result: TaskTypeBase)
//}
//
//@objc(SanitizerProgressListener)
//public protocol SanitizerProgressListener {
////    func onImportedMedia(_ media: MediaDetailsDTO)
//    func onLogMsg(_ msg: LogMsg)
////    func onImportedMedia(_ media: MediaDetails)
////    func onProgress(_ update: ProgressUpdate)
////    func onCompleted(_ result: ImportResult)
//    // NEW: Send file-specific progress back to the client
//    func onSanitationProgress(id: UUID, progress: Double)
////    func onMediaStateChanged(id: UUID, result: TaskTypeBase)
//}
//
//@objc(ConversionProgressListener)
//public protocol ConversionProgressListener {
//    func onProgress(_ update: ProgressUpdate)
//    func onCompleted(_ result: ImportResult)
//    func onConversionProgress(id: UUID, progress: Double)
//    func onMediaStateChanged(id: UUID, result: TaskTypeBase)
//}
//
//@objc(ExtractProgressListener)
//public protocol ExtractProgressListener {
//    func onProgress(_ update: ProgressUpdate)
//    func onCompleted(_ result: ExtractResult)
//}
