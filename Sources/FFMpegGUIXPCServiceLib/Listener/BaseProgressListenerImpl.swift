//
//  BaseProgressListenerImpl 2.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//


import Foundation
import FFMpegSwiftManagerLib

public class BaseProgressListenerLibImpl: NSObject, BaseProgressListenerLib {
    
    let onLogMsg: (LogMsg) -> Void
    let onCompleted: (TaskResult) -> Void
    let onBatchTaskProgress: (UUID, Double) -> Void
    let onSingleTaskProgress: (UUID, Double) -> Void
    let onSingleTaskCompleted: (UUID, TaskTypeBase, TaskResultForTaskResultHistory, ConversionResult) -> Void

    public init(onLogMsg: @escaping (LogMsg) -> Void,
         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
         onSingleTaskCompleted: @escaping (UUID, TaskTypeBase, TaskResultForTaskResultHistory, ConversionResult) -> Void,
         onCompleted: @escaping (TaskResult) -> Void) {
        self.onLogMsg = onLogMsg
        self.onBatchTaskProgress = onBatchTaskProgress
        self.onSingleTaskProgress = onSingleTaskProgress
        self.onSingleTaskCompleted = onSingleTaskCompleted
        self.onCompleted = onCompleted
    }

    public func onLogMsg(_ msg: LogMsg) {
        onLogMsg(msg)
    }
    
    public func onSingleTaskProgress(id: UUID, progress: Double) {
        onSingleTaskProgress(id, progress)
    }
    
    public func onSingleTaskCompleted(id: UUID, task: TaskTypeBase, taskResult: TaskResultForTaskResultHistory, result: ConversionResult) {
        onSingleTaskCompleted(id, task, taskResult, result)
    }
    
    public func onBatchTaskProgress(id: UUID, progress: Double) {
        onBatchTaskProgress(id, progress)
    }
    
    public func onCompleted(_ result: TaskResult) {
        onCompleted(result)
    }
}

public class MediaProgressListenerLibImpl: BaseProgressListenerLibImpl, MediaProgressListenerLib {
    
    let onMediaStateChanged: (UUID, TaskTypeBase) -> Void

    public init(onLogMsg: @escaping (LogMsg) -> Void,
         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
         onSingleTaskCompleted: @escaping (UUID, TaskTypeBase, TaskResultForTaskResultHistory, ConversionResult) -> Void,
         onCompleted: @escaping (TaskResult) -> Void,
         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
        self.onMediaStateChanged = onMediaStateChanged
        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onSingleTaskCompleted: onSingleTaskCompleted, onCompleted: onCompleted)
    }
        
    public func onMediaStateChanged(id: UUID, result: TaskTypeBase) {
        onMediaStateChanged(id, result)
    }
}

@objc
public class ImportProgressListenerLibImpl: MediaProgressListenerLibImpl, ImportProgressListenerLib, @unchecked Sendable {
    
    let onImportedMediaHandler: (MediaDetails) -> Void

    public init(onLogMsg: @escaping (LogMsg) -> Void,
         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
        onSingleTaskCompleted: @escaping (UUID, TaskTypeBase, TaskResultForTaskResultHistory, ConversionResult) -> Void,
         onCompleted: @escaping (TaskResult) -> Void,
         onImportedMedia: @escaping (MediaDetails) -> Void,
         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
        self.onImportedMediaHandler = onImportedMedia
        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onSingleTaskCompleted: onSingleTaskCompleted, onCompleted:  onCompleted, onMediaStateChanged: onMediaStateChanged)
    }

    public func onImportedMedia(_ media: MediaDetails) {
        onImportedMediaHandler(media)
    }
}

@objc
public class IntegrityCheckProgressListenerLibImpl: MediaProgressListenerLibImpl, IntegrityCheckProgressListenerLib, @unchecked Sendable {
    
//    let integrityChecktTaskResult: IntegrityChecktTaskResult
//    
//    
//    public func onCompleted(_ result: IntegrityChecktTaskResult){
//        
//    }
////    let onImportedMediaHandler: (MediaDetails) -> Void
////
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void,
//        // onImportedMedia: @escaping (MediaDetails) -> Void,
//         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
//        self.onImportedMediaHandler = onImportedMedia
//        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onCompleted:  onCompleted, onMediaStateChanged: onMediaStateChanged)
//    }
////
////    public func onImportedMedia(_ media: MediaDetails) {
////        onImportedMediaHandler(media)
////    }
}

@objc
public class ConversionProgressListenerLibImpl: MediaProgressListenerLibImpl, ConversionProgressListenerLib, @unchecked Sendable {
    
//    let onImportedMediaHandler: (MediaDetails) -> Void
//
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void,
//         onImportedMedia: @escaping (MediaDetails) -> Void,
//         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
//        self.onImportedMediaHandler = onImportedMedia
//        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onCompleted:  onCompleted, onMediaStateChanged: onMediaStateChanged)
//    }
//
//    public func onImportedMedia(_ media: MediaDetails) {
//        onImportedMediaHandler(media)
//    }
}

@objc
public class SanitizerProgressListenerLibImpl: MediaProgressListenerLibImpl, SanitizerProgressListenerLib, @unchecked Sendable {
    
//    let onImportedMediaHandler: (MediaDetails) -> Void
//
//    public init(onLogMsg: @escaping (LogMsg) -> Void,
//         onBatchTaskProgress: @escaping (UUID, Double) -> Void,
//         onSingleTaskProgress: @escaping (UUID, Double) -> Void,
//         onCompleted: @escaping (TaskResult) -> Void,
//         onImportedMedia: @escaping (MediaDetails) -> Void,
//         onMediaStateChanged: @escaping (UUID, TaskTypeBase) -> Void) {
//        self.onImportedMediaHandler = onImportedMedia
//        super.init(onLogMsg: onLogMsg, onBatchTaskProgress: onBatchTaskProgress, onSingleTaskProgress: onSingleTaskProgress, onCompleted:  onCompleted, onMediaStateChanged: onMediaStateChanged)
//    }
//
//    public func onImportedMedia(_ media: MediaDetails) {
//        onImportedMediaHandler(media)
//    }
}
