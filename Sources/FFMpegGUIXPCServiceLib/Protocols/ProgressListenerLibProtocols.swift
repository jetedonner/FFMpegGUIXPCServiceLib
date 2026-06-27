//
//  BaseProgressListener.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//

import Foundation
import FFMpegSwiftManagerLib

@objc(BaseProgressListenerLib)
public protocol BaseProgressListenerLib {
    func onLogMsg(_ msg: LogMsg)
    func onBatchTaskProgress(id: UUID, progress: Double)
    func onSingleTaskProgress(id: UUID, progress: Double)
    func onSingleTaskCompleted(id: UUID, task: TaskTypeBase, result: TaskResultSBNG)
    func onCompleted(_ result: TaskResult)
}

@objc(MediaProgressListenerLib)
public protocol MediaProgressListenerLib: BaseProgressListenerLib {
    func onMediaStateChanged(id: UUID, result: TaskTypeBase)
}

@objc(ImportProgressListenerLib)
public protocol ImportProgressListenerLib: MediaProgressListenerLib, Sendable {
    func onImportedMedia(_ media: MediaDetails)
}

@objc(IntegrityCheckProgressListenerLib)
public protocol IntegrityCheckProgressListenerLib: MediaProgressListenerLib, Sendable {
//    func onImportedMedia(_ media: MediaDetails)
//    func onCompleted(_ result: IntegrityChecktTaskResult)
}

@objc(ConversionProgressListenerLib)
public protocol ConversionProgressListenerLib: MediaProgressListenerLib, Sendable {
//    func onImportedMedia(_ media: MediaDetails)
}

@objc(SanitizerProgressListenerLib)
public protocol SanitizerProgressListenerLib: MediaProgressListenerLib, Sendable {
//    func onImportedMedia(_ media: MediaDetails)
}



