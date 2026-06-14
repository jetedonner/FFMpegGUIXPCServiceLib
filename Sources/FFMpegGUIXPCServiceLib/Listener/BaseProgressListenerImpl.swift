//
//  BaseProgressListenerImpl.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//


//
//  ProgressListenerImpl.swift
//  FFMpegSwiftManagerLib
//
//  Created by Kim-David Hauser on 06.05.2026.
//

import Foundation
import FFMpegSwiftManagerLib

//public class BaseProgressListenerImpl: NSObject, BaseProgressListener {
//    
//    let onLogMsg: (LogMsg) -> Void
//    let onCompleted: (TaskResult) -> Void
//    let onBatchTaskProgress: (UUID, Double) -> Void
//    let onSingleTaskProgress: (UUID, Double) -> Void
//
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void) {
//        self.onLogMsg = onLogMsg
//        self.onBatchTaskProgress = onBatchTaskProgress
//        self.onSingleTaskProgress = onSingleTaskProgress
//        self.onCompleted = onCompleted
//    }
//
//    public func onLogMsg(_ msg: LogMsg) {
//        onLogMsg(msg)
//    }
//    
//    public func onCompleted(_ result: TaskResult) {
//        onCompleted(result)
//    }
//    
//    public func onBatchTaskProgress(id: UUID, progress: Double) {
//        onBatchTaskProgress(id, progress)
//    }
//    
//    public func onSingleTaskProgress(id: UUID, progress: Double) {
//        onSingleTaskProgress(id, progress)
//    }
//}
//
//public class MediaProgressListenerImpl: BaseProgressListenerImpl, MediaProgressListener {
//    
//    let onMediaStateChanged: (UUID, TaskTypeBase) -> Void
//
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void,
//         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
//        self.onMediaStateChanged = onMediaStateChanged
//        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onCompleted: onCompleted)
//    }
//        
//    public func onMediaStateChanged(id: UUID, result: TaskTypeBase) {
//        onMediaStateChanged(id, result)
//    }
//}

//@objc
//public class ImportProgressListenerLibImpl: NSObject, ImportProgressListenerLib, @unchecked Sendable /* MediaProgressListenerImpl, ImportProgressListenerNG*/ {
//    public func onCompleted(_ result: FFMpegSwiftManagerLib.ImportResult) {
//        
//    }
//    
//    public func onProgress(_ update: FFMpegSwiftManagerLib.ProgressUpdate) {
//        
//    }
//    
//
//    let onLogMsg: (LogMsg) -> Void
//    let onCompleted: (TaskResult) -> Void
//    let onBatchTaskProgress: (UUID, Double) -> Void
//    let onFileIntegrityProgress: (UUID, Double) -> Void
////    func onFileIntegrityProgress(id: UUID, progress: Double)
////    func onFileIntegrityProgress(id: UUID, progress: Double)
//    let onMediaStateChanged: (UUID, TaskTypeBase) -> Void
//    let onImportedMediaHandler: (MediaDetails) -> Void
//
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//        onFileIntegrityProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void,
//        onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void,
//        onImportedMediaHandler: @escaping (MediaDetails) -> Void) {
//        self.onLogMsg = onLogMsg
//        self.onBatchTaskProgress = onBatchTaskProgress
//        self.onFileIntegrityProgress = onFileIntegrityProgress
//        self.onCompleted = onCompleted
//        self.onMediaStateChanged = onMediaStateChanged
//        self.onImportedMediaHandler = onImportedMediaHandler
//    }
//
//
//    public func onLogMsg(_ msg: LogMsg) {
//        onLogMsg(msg)
//    }
//    
//    public func onCompleted(_ result: TaskResult) {
//        onCompleted(result)
//    }
//    
//    public func onBatchTaskProgress(id: UUID, progress: Double) {
//        onBatchTaskProgress(id, progress)
//    }
//    
//    public func onFileIntegrityProgress(id: UUID, progress: Double) {
//        onFileIntegrityProgress(id, progress)
//    }
//    
//    public func onMediaStateChanged(id: UUID, result: TaskTypeBase) {
//        onMediaStateChanged(id: id, result: result)
//    }
//    
//    public func onImportedMedia(_ media: MediaDetails) {
//        onImportedMediaHandler(media)
//    }
//}
