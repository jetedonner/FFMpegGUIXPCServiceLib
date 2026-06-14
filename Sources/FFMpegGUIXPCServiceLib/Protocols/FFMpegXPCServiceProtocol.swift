//
//  that.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//


import Foundation
import FFMpegSwiftManagerLib

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc public protocol FFMpegXPCServiceProtocol {
    
    func ping(withReply reply: @escaping () -> Void)
    
    func startImportTask(taskConfig: XPCServiceImportTaskConfig, listener: ImportProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    
    func observeImportProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
    
}
