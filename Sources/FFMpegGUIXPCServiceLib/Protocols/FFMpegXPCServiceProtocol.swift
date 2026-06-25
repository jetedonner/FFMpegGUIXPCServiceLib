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
    
    // COMMON Fucntion
    func ping(withReply reply: @escaping () -> Void)
    func cancelTask(taskID: UUID, withReply reply: @escaping () -> Void)
    
    // --------------------------------------------------------------------
//    // New With SANDBOX
//    func processVideo(bookmarkData: Data, completion: @escaping (Bool) -> Void)
//    
//    func processVideo2(at fileURL: URL, completion: @escaping (Bool) -> Void)
    
    
    func startImportTaskSB(taskConfig: XPCServiceImportTaskConfigSB, listener: ImportProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    func observeImportProgressSB(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
    
    func startIntegrityCheckTaskSB(md: [MediaDetails], taskConfig: XPCServiceIntegrityCheckTaskConfigSB, listener: IntegrityCheckProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    
    func startConversionTaskSB(md: [MediaDetails], taskConfig: XPCServiceConversionTaskConfigSB, listener: ConversionProgressListenerLib,  withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    
    // --------------------------------------------------------------------
    
    // IMPORT Functions
//    func startImportTask(taskConfig: XPCServiceImportTaskConfig, listener: ImportProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    func observeImportProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
    
    // INTEGRITY Functions
//    func startIntegrityCheckTask(md: [MediaDetails], taskConfig: XPCServiceIntegrityCheckTaskConfig, listener: IntegrityCheckProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    func observeCheckIntegrityProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
    
    // CONVERSION Functions
//    func startConversionTask(md: [MediaDetails], taskConfig: XPCServiceConversionTaskConfig, listener: ConversionProgressListenerLib,  withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    func observeConversionProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
    
    // SANITATION Functions
    func startSanitationTaskSB(md: [MediaDetails], taskConfig: XPCServiceSanitazionTaskConfigSB, listener: SanitizerProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)
    func observeSanitationProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void)
}
