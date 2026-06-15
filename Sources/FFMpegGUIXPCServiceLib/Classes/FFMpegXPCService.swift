//
//  FFMpegGUIXPCService.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//


import Foundation
import os
import Combine
import SwiftUI
import FFMpegSwiftManagerLib

public class FFMpegXPCService: NSObject, FFMpegXPCServiceProtocol, @unchecked Sendable {
    
    weak var connection: NSXPCConnection?
    
    private var cnt: Int = 0
    
    private let logger = Logger(subsystem: "ch.kimhauser.swift.FFMpegGUI.FFMpegGUIXPCService",
                                category: "service")
    
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let queue = DispatchQueue(label: "FFMpegGUIXPCServiceTasks")
    
    public func cancelTask(taskID: UUID, withReply reply: @escaping () -> Void) {
        queue.async {
            self.tasks[taskID]?.cancel()
            self.tasks[taskID] = nil
        }
        reply()
    }
    
    public func startImportTask(taskConfig: XPCServiceImportTaskConfig, listener: ImportProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void){
        
        logger.info("startImportTask called")
        
        let id = taskConfig.id
        
        let task = Task {
            do {
                try await performImport(id: taskConfig.id, url: taskConfig.importURL, listener: listener, maxConcurrent: taskConfig.maxConcurrent, type: taskConfig.ffmpegType, recurseIntoSubDirs: taskConfig.recurseIntoSubDirs, withReply: reply)
            } catch {
                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
                    self.logger.error("Import task \(taskConfig.id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    listener.onLogMsg(LogMsg(msg: "Import task \(taskConfig.id.uuidString) failed: \(error.localizedDescription)", type: .error))
                }
            }
            self.queue.async {
                self.tasks[id] = nil
            }
        }
        
        queue.async {
            self.tasks[taskConfig.id] = task
        }
        
        reply(taskConfig.id, nil)
    }
    
    func performImport(id: UUID, url: String, listener: ImportProgressListenerLib, maxConcurrent: Int = 1, type: FFMpegResourceType = .linkedLibraries, recurseIntoSubDirs: Bool = true, withReply reply: @escaping  (UUID?, Error?) -> Void) async throws {
        
        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: url), recurseIntoSubDirs: recurseIntoSubDirs)
        let totalCount = files.count
        
        // Create a TaskGroup to handle concurrent processing
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedCount = 0
            
            if(files.count <= 0){
                ImportProgressStore.shared.setProgress(1.0, for: id, done: true)
            }else{
                for file in files {
                    if activeTasks >= maxConcurrent {
                        _ = try await group.next()
                        activeTasks -= 1
                        completedCount += 1
                        
//                        listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount))
                        try Task.checkCancellation()
                        let progress = Double(completedCount) / Double(totalCount)
                        ImportProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
//                        clientProxy.didUpdateBatchImportProgress(id: id, progress: progress)
                    }
                    
                    activeTasks += 1
                    group.addTask {
                        do {
                            let md = try await self.getFFProbeForType(type).runFFProbe(on: URL(fileURLWithPath: file.path))
                            if md.filename == "/" ||  md.filename == "" {
                                return
                            }
                            md.taskType = .importing
                            listener.onImportedMedia(md)
//                            clientProxy.didFindMedia(media: md)
                            listener.onLogMsg(LogMsg(msg: "Loaded \(md.filename) for integrity check ...", type: .info))
//                            clientProxy.didLogMsg(msg: LogMsg(msg: "Loaded \(md.filename) for integrity check ...", type: .info))
                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)
                            listener.onMediaStateChanged(id: md.id, result: .validating)
//                            clientProxy.didMediaStateChange(id: md.id, state: .validating)
                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)
                            // 1. Change to a thread-safe LockedBox
//                            let lastTimestamp = LockedBox(Date())
//                            let res = try await self.getFFProbeForType(type).checkIntegrity(item: md) {  progress in
//                                // 2. Safely check and update the timestamp atomically on the spot
//                                let shouldUpdateProgress = lastTimestamp.mutate { lastTime -> Bool in
//                                    let now = Date()
//                                    if now.timeIntervalSince(lastTime) >= 0.1 {
//                                        lastTime = now // Updates immediately, blocking the throttling flood
//                                        return true
//                                    }
//                                    return false
//                                }
//                                
//                                // 3. If the throttle check passed, dispatch the UI update to the MainActor
//                                if shouldUpdateProgress || progress == 1.0 {
////                                    Task { @MainActor in
//                                        if md.taskType != .validated && md.taskType != .corrupted {
//                                            listener.onSingleTaskProgress(id: md.id, progress: progress)
////                                            clientProxy.didUpdateSingleImportProgress(id: md.id, progress: progress)
//                                            try? await Task.sleep(nanoseconds: 10_000_000)
//                                            await Task.yield()
//                                        }
////                                    }
//                                }
//                            }
                            // 1. Change to a thread-safe LockedBox
                            let lastTimestamp = LockedBox(Date())
                            let res = try await self.getFFProbeForType(type).checkIntegrity(item: md) { progress in
                                
                                // 2. Safely check and update the timestamp atomically on the spot
                                let shouldUpdateProgress = lastTimestamp.mutate { lastTime -> Bool in
                                    let now = Date()
                                    if now.timeIntervalSince(lastTime) >= 0.1 {
                                        lastTime = now // Updates immediately, blocking the throttling flood
                                        return true
                                    }
                                    return false
                                }
                                
                                // 3. If the throttle check passed, dispatch the UI update
                                if shouldUpdateProgress || progress == 1.0 {
                                    if md.taskType != .validated && md.taskType != .corrupted {
                                        
                                        // This call is synchronous, keeping the outer closure happy
                                        listener.onSingleTaskProgress(id: md.id, progress: progress)
                                        
                                        // ✅ FIXED: Removed try? await Task.sleep and await Task.yield()
                                        // Your LockedBox throttle handles the frame-thrashing perfectly now.
                                    }
                                }
                            }
                            if(res != .success){
                                listener.onMediaStateChanged(id: md.id, result: .corrupted)
                                listener.onLogMsg(LogMsg(msg: "Failed to process \(file.path): \(res.description) > File is corrupted!", type: .error))
                            }else{
                                listener.onMediaStateChanged(id: md.id, result: .validated)
                                listener.onLogMsg(LogMsg(msg: "Loaded media file \(file.path): \(res.description) ...", type: .info))
//                                clientProxy.didLogMsg(msg: LogMsg(msg: "Loaded media file \(file.path): \(res.description) ...", type: .info))
                            }
                        } catch {
                            print("Failed to process \(file.path): \(error)")
                            listener.onLogMsg(LogMsg(msg: "Failed to process \(file.path): \(error)", type: .error))
                        }
                    }
                }
                
                // 3. Drain the remaining tasks in the final batch
                for try await _ in group {
                    completedCount += 1
                    listener.onBatchTaskProgress(id: id, progress: Double(completedCount / totalCount))  // )(completedCount, totalCount)
                    try Task.checkCancellation()
                    let progress = Double(completedCount) / Double(totalCount)
                    ImportProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
                }
            }
        }
        
        // 4. Batch complete
//        listener.onCompleted(TaskResult(id: id, progress: 1.0, success: true))
        listener.onLogMsg(LogMsg(msg: "Completed loading (\(totalCount)) media files ... You can now start to work with them.", type: .info))
//        clientProxy.didLogMsg(msg: LogMsg(msg: "Completed loading (\(totalCount)) media files ... You can now start to work with them.", type: .info))
        reply(id, nil)
    }
    
    public func observeImportProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        ImportProgressStore.shared.withProgress(for: taskID) { progress, done in
            reply(progress, done, nil)
        }
    }
    
    
    public func startIntegrityCheckTask(md: [MediaDetails], taskConfig: XPCServiceIntegrityCheckTaskConfig, listener: IntegrityCheckProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)  /*-> ConversionResult*/{
        
        logger.info("startIntegrityCheckTask called")
        
        let id = UUID()
        
        let task = Task {
            do {
//                try await performConversion(id: id, md: md, listener: listener, maxConcurrent: 5, type: type, withReply: reply)
                try await self.performIntegrityCheck(id: id, md: md, listener: listener, type: taskConfig.ffmpegType, withReply: reply)
            } catch {
                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
                    self.logger.error("IntegrityCheck task \(id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    print("IntegrityCheck task \(id.uuidString) failed: \(error.localizedDescription)")
//                    listener.onLogMsg(LogMsg(msg: "Import task \(id.uuidString) failed: \(error.localizedDescription)"))
                }
            }
            self.queue.async {
                self.tasks[id] = nil
            }
        }
        
        queue.async {
            self.tasks[id] = task
        }
        
        reply(id, nil)
    }
    
    func performIntegrityCheck(id: UUID, md: [MediaDetails], listener: IntegrityCheckProgressListenerLib, maxConcurrent: Int = 5, type: FFMpegResourceType = .linkedLibraries, withReply reply: @escaping (UUID?, Error?) -> Void) async throws {
//        let file = md
        //        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: md.filename).deletingLastPathComponent())
        let totalCount = md.count
        
        // Create a TaskGroup to handle concurrent processing
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedCount = 0
            
            if(md.count <= 0){
                CheckIntegrityProgressStore.shared.setProgress(1.0, for: id, done: true)
            }else{
                for file in md {
                // 1. If we hit our concurrency limit, wait for one task to finish
                if activeTasks >= maxConcurrent {
                    _ = try await group.next()
                    activeTasks -= 1
                    completedCount += 1
                    
                    // Safe to report overall batch progress here
//                    listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount)) //  completedCount, totalCount)
                    try Task.checkCancellation()
                    let progress = Double(completedCount) / Double(totalCount)
                    CheckIntegrityProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
                }
                
                activeTasks += 1
                group.addTask {
    //                do {
                        //                            let md = try await self.getFFProbeForType(type).runFFProbe(on: URL(fileURLWithPath: file.path))
                        //                            if md.filename == "/" ||  md.filename == "" {
                        //                                return
                        //                            }
                        
                        //                            listener.onImportedMedia(md)
                        listener.onMediaStateChanged(id: file.id, result: .validating)
                        
//                        let res = try await self.getFFProbeForType(type).checkIntegrity(item: file, onProgress: { progress in
//                            // Force the UI update to hop back to the Main Actor safely
//    //                        Task { @MainActor in
////                            DispatchQueue.main.async {
//                                print("Progress: \(progress)")
//                                listener.onSingleTaskProgress(id: file.id, progress: progress)
////                            }
//                        })
                    let lastTimestamp = LockedBox(Date())
                    let res = try await self.getFFProbeForType(type).checkIntegrity(item: file) { progress in
                        
                        // 2. Safely check and update the timestamp atomically on the spot
                        let shouldUpdateProgress = lastTimestamp.mutate { lastTime -> Bool in
                            let now = Date()
                            if now.timeIntervalSince(lastTime) >= 0.1 {
                                lastTime = now // Updates immediately, blocking the throttling flood
                                return true
                            }
                            return false
                        }
                        
                        // 3. If the throttle check passed, dispatch the UI update
                        if shouldUpdateProgress || progress == 1.0 {
                            if file.taskType != .validated && file.taskType != .corrupted {
                                
                                // This call is synchronous, keeping the outer closure happy
                                listener.onSingleTaskProgress(id: file.id, progress: progress)
                                
                                // ✅ FIXED: Removed try? await Task.sleep and await Task.yield()
                                // Your LockedBox throttle handles the frame-thrashing perfectly now.
                            }
                        }
                    }
//                    if(res != .success){
////                                md.taskType = .corrupted
//                        listener.onMediaStateChanged(id: md.id, result: .corrupted)
////                                clientProxy.didMediaStateChange(id: md.id, state: .corrupted)
//                        listener.onLogMsg(LogMsg(msg: "Failed to process \(file.path): \(res.description) > File is corrupted!", type: .error))
////                                clientProxy.didLogMsg(msg: LogMsg(msg: "Failed to process \(file.path): \(res.description) > File is corrupted!", type: .error))
//                    }else{
////                                md.taskType = .validated
//                        listener.onMediaStateChanged(id: md.id, result: .validated)
////                                clientProxy.didMediaStateChange(id: md.id, state: .validated)
//                        listener.onLogMsg(LogMsg(msg: "Loaded media file \(file.path): \(res.description) ...", type: .info))
////                                clientProxy.didLogMsg(msg: LogMsg(msg: "Loaded media file \(file.path): \(res.description) ...", type: .info))
//                    }
                        if(res != .success){
                            listener.onMediaStateChanged(id: file.id, result: .corrupted)
                        }else{
                            listener.onMediaStateChanged(id:file.id, result: .validated)
                        }
    //                } catch {
    //                    print("Failed to process \(md.filename): \(error)")
    //                }
                    }
                }
                
                // 3. Drain the remaining tasks in the final batch
                for try await _ in group {
                    completedCount += 1
//                    listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount))  // )(completedCount, totalCount)
                    try Task.checkCancellation()
                    let progress = Double(completedCount) / Double(totalCount)
                    CheckIntegrityProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
                }
            }
        }
        
        // 4. Batch complete
//        listener.onCompleted(ImportResult(outputPath: "", id: id))
        listener.onCompleted(TaskResult(id: id, progress: 1.0, success: true))
        reply(id, nil)
    }
//    public func startIntegrityCheckTask(md: [MediaDetails], taskConfig: XPCServiceIntegrityCheckTaskConfig, listener: IntegrityCheckProgressListenerLibImpl, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void) {
//     
//        logger.info("startIntegrityCheckTaskNG called")
//        
//        let id = UUID()
//        
//        let task = Task {
//            do {
////                try await performConversion(id: id, md: md, listener: listener, maxConcurrent: 5, type: type, withReply: reply)
//                try await self.performIntegrityCheckNG(id: id, md: md, listener: listener, type: taskConfig.ffmpegType, withReply: reply)
//            } catch {
//                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
//                    self.logger.error("IntegrityCheck task \(id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
//                    print("IntegrityCheck task \(id.uuidString) failed: \(error.localizedDescription)")
////                    listener.onLogMsg(LogMsg(msg: "Import task \(id.uuidString) failed: \(error.localizedDescription)"))
//                }
//            }
//            self.queue.async {
//                self.tasks[id] = nil
//            }
//        }
//        
//        queue.async {
//            self.tasks[id] = task
//        }
//        
//        reply(id, nil)
//    }
//    
//    func performIntegrityCheckNG(id: UUID, md: [MediaDetails], listener: IntegrityCheckProgressListenerLibImpl, maxConcurrent: Int = 5, type: FFMpegResourceType = .linkedLibraries, withReply reply: @escaping (UUID?, Error?) -> Void) async throws {
////        let file = md
//        //        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: md.filename).deletingLastPathComponent())
//        let totalCount = md.count
//        
//        // Create a TaskGroup to handle concurrent processing
//        try await withThrowingTaskGroup(of: Void.self) { group in
//            var activeTasks = 0
//            var completedCount = 0
//            
//            if(md.count <= 0){
//                CheckIntegrityProgressStore.shared.setProgress(1.0, for: id, done: true)
//            }else{
//                for file in md {
//                // 1. If we hit our concurrency limit, wait for one task to finish
//                if activeTasks >= maxConcurrent {
//                    _ = try await group.next()
//                    activeTasks -= 1
//                    completedCount += 1
//                    
//                    // Safe to report overall batch progress here
////                    listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount)) //  completedCount, totalCount)
//                    try Task.checkCancellation()
//                    let progress = Double(completedCount) / Double(totalCount)
//                    CheckIntegrityProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
//                }
//                
//                activeTasks += 1
//                group.addTask {
//    //                do {
//                        //                            let md = try await self.getFFProbeForType(type).runFFProbe(on: URL(fileURLWithPath: file.path))
//                        //                            if md.filename == "/" ||  md.filename == "" {
//                        //                                return
//                        //                            }
//                        
//                        //                            listener.onImportedMedia(md)
////                        listener.onMediaStateChanged(id: file.id, result: .validating)
//                        
//                        let res = try await self.getFFProbeForType(type).checkIntegrity(item: file) { progress in
//                            // Force the UI update to hop back to the Main Actor safely
//    //                        Task { @MainActor in
////                            DispatchQueue.main.async {
//                                print("Progress: \(progress)")
//                            listener.onSingleTaskProgress(id: file.id, progress: progress)
////                                listener.onFileIntegrityProgress(id: file.id, progress: progress)
////                            }
//                        }
//                        if(res != .success){
//                            listener.onMediaStateChanged(id: file.id, result: .corrupted)
//                        }else{
//                            listener.onMediaStateChanged(id:file.id, result: .validated)
//                        }
//    //                } catch {
//    //                    print("Failed to process \(md.filename): \(error)")
//    //                }
//                    }
//                }
//                
//                // 3. Drain the remaining tasks in the final batch
//                for try await _ in group {
//                    completedCount += 1
////                    listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount))  // )(completedCount, totalCount)
//                    
//                    try Task.checkCancellation()
//                    let progress = Double(completedCount) / Double(totalCount)
//                    CheckIntegrityProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
//                }
//            }
//        }
//        
//        // 4. Batch complete
//        listener.onCompleted(TaskResult(id: id, progress: 1.0, success: true))
//        reply(id, nil)
//    }
    
    public func observeCheckIntegrityProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        CheckIntegrityProgressStore.shared.withProgress(for: taskID) { progress, done in
            reply(progress, done, nil)
        }
    }
    
    public func ping(withReply reply: @escaping () -> Void) {
        reply()
    }
    
    func getFFProbeForType(_ type: FFMpegResourceType) -> FFProbeProtocol {
        if(type == .bundledBinaries){
            return FFProbeBinNG()
        }else{
            return FFProbeLibNG()
        }
    }
    
    func getFFMpegForType(_ type: FFMpegResourceType) -> FFMpegProtocol {
        if(type == .bundledBinaries){
            return FFMpegBinNew()
        }else{
            return FFMpegLibNew()
        }
    }
}
