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
    
    
    
    public func processVideo2(at fileURL: URL, completion: @escaping (Bool) -> Void){
     
        // 2. Open the sandbox gate for the XPC service process
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("❌ XPC Service failed to claim security scope.")
            completion(false)
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() } // Clean up when finished
        
//            // 3. Run your FFmpeg setup safely inside the security container block
//            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil
//
//            // 💡 Optimization Tip: Use filesystem representation for C libraries to avoid string encoding bugs
//            let pathString = xpcScopedURL.withUnsafeFileSystemRepresentation { String(cString: $0!) }
//            let resultCode = avformat_open_input(&formatContext, pathString, nil, nil)
        
//            var resultCode = 0
//            guard resultCode == 0 else {
//                print("❌ FFmpeg failed inside XPC: \(getFFmpegError(code: resultCode))")
//                completion(false)
//                return
//            }
        
        // Process media files here...
        completion(true)
    }
    
//    @MainActor
    public func processVideo(bookmarkData: Data, completion: @escaping (Bool) -> Void) {
        var isStale = false
        do {
            let location = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
          defer {
            location.stopAccessingSecurityScopedResource()
          }
          // Use the resource at the location URL.
//            Task { @MainActor in
////                do {
                    let md = FFProbeLibNG().runFFProbeSB(on: URL(fileURLWithPath: location.path)) { logMsg in
//                        listener.onLogMsg(logMsg)
                        print(logMsg.msg)
                    }
            print(md.filenameOnly)
                completion(true)
//                } catch {
//                    print("Error getting FFProbe: \(error)")
//                    completion(false)
//                }
//            }
            return
        }
        catch let error {
          // Handle any errors.
//            completion(false)
            print("Error resolving bookmark: \(error)")
//            completion(false)
        }
        completion(false)
        return
        
//        var isStale = false
//        
//        do {
//            //  Converted to Swift 6.3 by Swiftify v6.3.25104 - https://swiftify.com/
//            // Decode the Base64 bookmark data
////            guard let decodedBookmark = Data(base64Encoded: bookmarkData, options: .ignoreUnknownCharacters) else { return }
//            
//            // 1. Resolve the main app's bookmark payload directly inside the XPC's sandbox context
//            let xpcScopedURL = try URL(
//                resolvingBookmarkData: bookmarkData,
//                options: .withSecurityScope,
//                relativeTo: nil,
//                bookmarkDataIsStale: &isStale
//            )
//            
//            // 2. Open the sandbox gate for the XPC service process
//            guard xpcScopedURL.startAccessingSecurityScopedResource() else {
//                print("❌ XPC Service failed to claim security scope.")
//                completion(false)
//                return
//            }
//            defer { xpcScopedURL.stopAccessingSecurityScopedResource() } // Clean up when finished
//            
////            // 3. Run your FFmpeg setup safely inside the security container block
////            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil
////            
////            // 💡 Optimization Tip: Use filesystem representation for C libraries to avoid string encoding bugs
////            let pathString = xpcScopedURL.withUnsafeFileSystemRepresentation { String(cString: $0!) }
////            let resultCode = avformat_open_input(&formatContext, pathString, nil, nil)
//            
////            var resultCode = 0
////            guard resultCode == 0 else {
////                print("❌ FFmpeg failed inside XPC: \(getFFmpegError(code: resultCode))")
////                completion(false)
////                return
////            }
//            
//            // Process media files here...
//            completion(true)
//            
//        } catch {
//            print("❌ XPC service bookmark resolution crash: \(error)")
//            completion(false)
//        }
    }
    
    public func startImportTaskSB(taskConfig: XPCServiceImportTaskConfigSB, listener: ImportProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void) {
        
        logger.info("startImportTask called")
        
        let id = taskConfig.id
        
        let task = Task {
            do {
                try await performImportSB(id: taskConfig.id, url: taskConfig.bookmarkData, listener: listener, maxConcurrent: taskConfig.maxConcurrent, type: taskConfig.ffmpegType, recurseIntoSubDirs: taskConfig.recurseIntoSubDirs, withReply: reply)
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
    
    func performImportSB(id: UUID, url: Data, listener: ImportProgressListenerLib, maxConcurrent: Int = 1, type: FFMpegResourceType = .linkedLibraries, recurseIntoSubDirs: Bool = true, withReply reply: @escaping  (UUID?, Error?) -> Void) async throws {
        
        do {
            
            var isStale: Bool = false
            
            let location = try URL(resolvingBookmarkData: url, bookmarkDataIsStale: &isStale)
          defer {
            location.stopAccessingSecurityScopedResource()
          }
        let files = FilesystemManager.mediaFilesInPath(in: location, recurseIntoSubDirs: recurseIntoSubDirs)
        let totalCount = files.count
        
        // Create a TaskGroup to handle concurrent processing
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedCount = 0
            
            if(files.count <= 0){
                ImportProgressStore.shared.setProgress(1.0, for: id, done: true)
            }else{
                for file in files {
                    guard FileSecurityManager.isFileValidMedia(url: file) else {
                        continue
                    }
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
                            
//                            var isStale: Bool = false
//                            
//                            let location = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
//                          defer {
//                            location.stopAccessingSecurityScopedResource()
//                          }
                          // Use the resource at the location URL.
                //            Task { @MainActor in
                ////                do {
                            let md = FFProbeLibNG().runFFProbeSB(on: URL(fileURLWithPath: file.path)) { logMsg in
                                listener.onLogMsg(logMsg)
                            }
                            print(md.filenameOnly)
                            if md.filename == "/" ||  md.filename == "" {
                                return
                            }
                            md.taskType = .importing
                            listener.onImportedMedia(md)
//                                completion(true)
                //                } catch {
                //                    print("Error getting FFProbe: \(error)")
                //                    completion(false)
                //                }
                //            }
//                            return
                            
//                            let md = try await self.getFFProbeForType(type).runFFProbe(on: URL(fileURLWithPath: file.path)) { logMsg in
//                                listener.onLogMsg(logMsg)
//                            }
//                            
//                            if md.filename == "/" ||  md.filename == "" {
//                                return
//                            }
//                            md.taskType = .importing
//                            listener.onImportedMedia(md)
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
                            let res = FFProbeLibNG().checkIntegritySB(item: md) {  progress in //  try await self.getFFProbeForType(type).checkIntegrity(item: md) { progress in
                                
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
        listener.onLogMsg(LogMsg(msg: "Completed loading (\(totalCount)) media files ... You can now start to work with \(totalCount >= 2 ? "them" : "it").", type: .info))
//        clientProxy.didLogMsg(msg: LogMsg(msg: "Completed loading (\(totalCount)) media files ... You can now start to work with them.", type: .info))
        } catch {
            print("Failed to process ulr ...") // \(location.path): \(error)")
            listener.onLogMsg(LogMsg(msg: "Failed to process  ulr ...", type: .error)) // \(location.path): \(error)", type: .error))
        }
        reply(id, nil)
            
    }
    
    public func observeImportProgressSB(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        ImportProgressStore.shared.withProgress(for: taskID) { progress, done in
            reply(progress, done, nil)
        }
    }
    
    // ---------------------------------------------------- END SB --------------------------------------------------------
    
    public func observeImportProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        ImportProgressStore.shared.withProgress(for: taskID) { progress, done in
            reply(progress, done, nil)
        }
    }
    
    public func observeCheckIntegrityProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        CheckIntegrityProgressStore.shared.withProgress(for: taskID) { progress, done in
            reply(progress, done, nil)
        }
    }
    
    // --------------------------------- SB START --------------------------------
    
    public func startIntegrityCheckTaskSB(md: [MediaDetails], taskConfig: XPCServiceIntegrityCheckTaskConfigSB, listener: IntegrityCheckProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void)  /*-> ConversionResult*/{
        
        logger.info("startIntegrityCheckTask called")
        
        let id = UUID()
        
        let task = Task {
            do {
//                try await performConversion(id: id, md: md, listener: listener, maxConcurrent: 5, type: type, withReply: reply)
                try await self.performIntegrityCheckSB(id: id, md: md, bookmarkData: taskConfig.bookmarkData, listener: listener, type: taskConfig.ffmpegType, withReply: reply)
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
    
    func performIntegrityCheckSB(id: UUID, md: [MediaDetails], bookmarkData: Data, listener: IntegrityCheckProgressListenerLib, maxConcurrent: Int = 5, type: FFMpegResourceType = .linkedLibraries, withReply reply: @escaping (UUID?, Error?) -> Void) async throws {
//        let file = md
        //        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: md.filename).deletingLastPathComponent())
        let totalCount = md.count
        
        var isStale: Bool = false
        
        let location = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
        location.startAccessingSecurityScopedResource()
      defer {
        location.stopAccessingSecurityScopedResource()
      }
        
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
                    
                        await Task.yield()
                        try await Task.sleep(nanoseconds: 100_000_000)
                        
                    
                        
//                        let res = try await self.getFFProbeForType(type).checkIntegrity(item: file, onProgress: { progress in
//                            // Force the UI update to hop back to the Main Actor safely
//    //                        Task { @MainActor in
////                            DispatchQueue.main.async {
//                                print("Progress: \(progress)")
//                                listener.onSingleTaskProgress(id: file.id, progress: progress)
////                            }
//                        })
                    var locBase = location
                    file.fileURLSB = locBase.appending(path: file.filenameOnly)
                    let lastTimestamp = LockedBox(Date())
                    let res = try await /*self.getFFProbeForType(type)*/ FFProbeLibNG().checkIntegritySB2(item: file) { progress in
                        
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
    
    // --------------------------------- SB END --------------------------------
  
    var oldProgressOverAll = 0.0
    
    public func startConversionTaskSB(md: [MediaDetails], taskConfig: XPCServiceConversionTaskConfigSB, listener: ConversionProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void) {
        logger.info("startConvertTask called")
        
        let id = UUID()
        
        let task = Task {
            do {
                try await performConversionSB(id: id, md: md, bookmarkData: taskConfig.bookmarkData, listener: listener, maxConcurrent: taskConfig.maxConcurrent, type: taskConfig.ffmpegType, withReply: reply)
            } catch {
                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
                    self.logger.error("Import task \(id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    print("Import task \(id.uuidString) failed: \(error.localizedDescription)")
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
  
//    var oldProgressOverAll = 0.0
    func performConversionSB(id: UUID, md: [MediaDetails], bookmarkData: Data, listener: ConversionProgressListenerLib, maxConcurrent: Int = 1, type: FFMpegResourceType = .linkedLibraries, withReply reply: @escaping (UUID?, Error?) -> Void) async throws {
//        guard let clientProxy = self.connection?.remoteObjectProxy as? FFMpegXPCClientProtocol else { return }
        self.oldProgressOverAll = 0.0
//        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: url))
        let totalCount = md.count
        
        let totalDuration: Double = md.reduce(0) { $0 + $1.duration2 }
//        let id = UUID()
        // Create a TaskGroup to handle concurrent processing
//        var isUpdating: Bool = false
        
        var isStale: Bool = false
        
        let location = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
        location.startAccessingSecurityScopedResource()
      defer {
        location.stopAccessingSecurityScopedResource()
      }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedCount = 0
            
            if(md.count <= 0){
                ConversionProgressStore.shared.setProgress(1.0, for: id, done: true)
            }else{
                for file in md {
                    if file.taskType == .corrupted {
                        continue
                    }
                    if activeTasks >= maxConcurrent {
                        _ = try await group.next()
                        activeTasks -= 1
                        completedCount += 1
                        
                        // Safe to report overall batch progress here
//                        listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount)) //  completedCount, totalCount)
                        try Task.checkCancellation()
                        let progress = Double(completedCount) / Double(totalCount)
                        ConversionProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
//                        listener.onMediaStateChanged(id: file.id, result: .converting)
                    }
                    
                    activeTasks += 1
                    group.addTask {
                        do {
                            
                            listener.onMediaStateChanged(id: file.id, result: .converting)
                            
                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)
                            
                            var locBase = location
                            file.fileURLSB = locBase.appending(path: file.filenameOnly)
                            
                            let lastTimestamp = LockedBox(Date())
                            let res = await /*self.getFFMpegForType(type)*/ FFMpegLibNew().convertMediaFileSB(md: file, selectedCodec: file.mediaConversionConfig.outputCodec, progress: { progress, total, current in
                            
//                                if Task.isCancelled { return }
//                                Task { @MainActor in
//                                    try await Task.checkCancellation()
//                                }
//                                listener.onConversionProgress(id: file.id, progress: progress)
                                // 2. Safely check and update the timestamp atomically on the spot
                                let shouldUpdateProgress = lastTimestamp.mutate { lastTime -> Bool in
                                    let now = Date()
                                    if now.timeIntervalSince(lastTime) >= 0.1 {
                                        lastTime = now // Updates immediately, blocking the throttling flood
                                        return true
                                    }
                                    return false
                                }
                                
                                if shouldUpdateProgress || progress == 1.0 {
                                    file.current = current
    //                                    if md.taskType != .validated && md.taskType != .corrupted {
                                        
                                        // This call is synchronous, keeping the outer closure happy
                                    listener.onSingleTaskProgress(id: file.id, progress: progress)
                                    
                                    let currentDuration: Double = md.reduce(0) { $0 + $1.current }
                                    let progressOverAll = Double(currentDuration) / Double(totalDuration)
                                    ConversionProgressStore.shared.setProgress(progressOverAll, for: id, done: currentDuration == totalDuration)
//                                    await Task.yield()
//                                    try await Task.sleep(nanoseconds: 10_000_000)
                                }
                                    
                                    // 3. If the throttle check passed, dispatch the UI update to the MainActor
    //                                if shouldUpdateProgress {
    //
    ////                                    await Task.yield()
    ////                                    Task { @MainActor in
    ////                                        if file.taskType != .validated && file.taskType != .corrupted {
    ////                                            clientProxy.didUpdateSingleImportProgress(id: file.id, progress: progress)
    //                                            let currentDuration: Double = md.reduce(0) { $0 + $1.current }
    //                                            let progressOverAll = Double(currentDuration) / Double(totalDuration)
    ////                                        if progressOverAll >= self.oldProgressOverAll + 0.1 {
    //                                            ConversionProgressStore.shared.setProgress(progressOverAll, for: id, done: currentDuration == totalDuration)
    //                                            //                                            clientProxy.didUpdateBatchImportProgress(id: id, progress: progressOverAll)
    ////                                        }
    ////                                            await Task.yield()
    ////                                        }
    ////                                    }
    //
    //                                }
    //                                try await Task.sleep(nanoseconds: 1_000_000)
    ////                                    await Task.yield()
    ////                                    isUpdating = false
    //                            }
    //                            let currentDuration: Double = md.reduce(0) { $0 + $1.current }
    //                            let progressOverAll = Double(currentDuration) / Double(totalDuration)
    ////                            if progressOverAll >= self.oldProgressOverAll + 0.1 {
    //
    ////                                ConversionProgressStore.shared.setProgress(progressOverAll, for: id, done: currentDuration == totalDuration)
    //                                clientProxy.didUpdateBatchImportProgress(id: id, progress: progressOverAll)

    //                                self.oldProgressOverAll = progressOverAll
    //                            }
    ////                            }
    //                            var mediaProgress: [UUID: Double] = [:]
    //                            md.forEach {
    //                                mediaProgress[$0.id] = $0.progress
    //                            }
    //                            md.forEach { mediaProgress[$0.id] = $0.current }
                                
    //                            ConversionProgressStore.shared.setProgress(progressOverAll, for: id, done: currentDuration == totalDuration)
    //                            ConversionProgressStoreNG.shared.setProgress(progressOverAll, for: id, done: currentDuration == totalDuration, mediaProgress: mediaProgress)
                            })

                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)

                            if(res != .success){
                                listener.onMediaStateChanged(id: file.id, result: .corrupted)
    //                                listener.onConversionProgress(id: file.id, progress: 1.0)
    //                                listener.onLogMsg(LogMsg(msg: "Failed to process \(file.path): \(res) > corrupted"))
                            }else{
                                listener.onMediaStateChanged(id: file.id, result: .converted)
    //                                listener.onConversionProgress(id: file.id, progress: 1.0)
    //                                listener.onLogMsg(LogMsg(msg: "Loaded media file \(file.path): \(res) ..."))
                            }
                        
//                        Task { @MainActor in
//                            listener.onConversionProgress(id: file.id, progress: 1.0)
//                        }
//                        ConversionSingleMediaProgressStore.shared.setProgress(1.0, for: file.id, done: true)
                        } catch {
                            print("Failed to process \(file.filename): \(error)")
                            file.taskType = .cancelled
//                            listener.onLogMsg(LogMsg(msg: "Failed to process \(file.filename): \(error)", type: .error))
                        }
                    }
                }
                
                // 3. Drain the remaining tasks in the final batch
                for try await _ in group {
                    completedCount += 1
                    //                    Task { @MainActor in
                    //                        listener.onConversionProgress(id: file.id, progress: progress)
                    //                        listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount))  // )(completedCount, totalCount)
                    //                    }
                    
                    try Task.checkCancellation()
                    if completedCount == totalCount {
                        //                        listener.onMediaStateChanged(id: file.id, result: .converting)
                        let progress = 1.0 // Double(completedCount) / Double(totalCount) >>> Do we need it???
                        ConversionProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
                        //                        clientProxy.didUpdateBatchImportProgress(id: id, progress: progress)
                    }
                    
                }
            }
        }
        
        // 4. Batch complete
        listener.onCompleted(TaskResult(id: id, progress: 1.0, success: true)) // ImportResult(outputPath: "", id: id, taskType: .converted))
//        listener.onLogMsg(LogMsg(msg: "Completed loading media files!"))
        reply(id, nil)
    }
    
    public func observeConversionProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        ConversionProgressStore.shared.withProgress(for: taskID) { progress, done in
//            print("ConversionProgressStore.shared.withProgress(for: \(taskID)) => \(progress), \(done)")
            reply(progress, done, nil)
        }
    }
    
    public func startSanitationTask(md: [MediaDetails], taskConfig: XPCServiceSanitazionTaskConfig, listener: SanitizerProgressListenerLib, withReply reply: @escaping @Sendable (UUID?, Error?) -> Void) {
//        logger.info("startConvertTask called")
//        
//        let id = UUID()
//        
//        let task = Task {
//            do {
//                try await performSanitizatio(id: id, md: md, listener: listener, maxConcurrent: taskConfig.maxConcurrent, type: taskConfig.ffmpegType, withReply: reply)
//            } catch {
//                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
//                    self.logger.error("Import task \(id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
//                    print("Import task \(id.uuidString) failed: \(error.localizedDescription)")
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
        logger.info("startSanitizerTask called")
        
        let id = UUID()
        
        let task = Task {
            do {
                try await performSanitation(id: id, md: md, listener: listener, maxConcurrent: 1, withReply: reply)
            } catch {
                if !(error is CancellationError) /*, let taskID = currentTaskID*/ {
                    self.logger.error("Sanitization task \(id.uuidString, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
                    print("Sanitization task \(id.uuidString) failed: \(error.localizedDescription)")
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
    
    
  
//    var oldProgressOverAll = 0.0
    func performSanitation(id: UUID, md: [MediaDetails], listener: SanitizerProgressListenerLib, maxConcurrent: Int = 1, type: FFMpegResourceType = .linkedLibraries, withReply reply: @escaping (UUID?, Error?) -> Void) async throws {
        self.oldProgressOverAll = 0.0
//        let files = FileSystemManager.mediaFilesInPath(in: URL(fileURLWithPath: url))
        let totalCount = md.count
        
//        let totalDuration: Double = md.reduce(0) { $0 + $1.duration2 }
//        let id = UUID()
        // Create a TaskGroup to handle concurrent processing
//        var isUpdating: Bool = false
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            var completedCount = 0
            
            if(md.count <= 0){
                SanitationProgressStore.shared.setProgress(1.0, for: id, done: true)
            }else{
                for file in md {
                    if activeTasks >= 1 {
                        _ = try await group.next()
                        activeTasks -= 1
                        completedCount += 1
                        
                        // Safe to report overall batch progress here
//                        listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount)) //  completedCount, totalCount)
                        try Task.checkCancellation()
                        let progress = Double(completedCount) / Double(totalCount)
                        SanitationProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
//                        listener.onMediaStateChanged(id: file.id, result: .converting)
                    }
                    
                    activeTasks += 1
                    group.addTask {
                        do {
                            
                            listener.onMediaStateChanged(id: file.id, result: .sanitizing)
                            
                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)
                            
                            let res = await FFMpegMedicLib().sanitizeMediaFile(md: md.first!, progress: { progress, _, _ in
                                listener.onLogMsg(LogMsg(msg: "Sanitize file: \(file.filenameOnly) => \(String(format: "%.2f", (progress * 100)))%"))
                                listener.onSingleTaskProgress(id: md.first!.id, progress: progress)
                                SanitationProgressStore.shared.setProgress(progress, for: id, done: false /*currentDuration == totalDuration*/)
                            })
                            listener.onLogMsg(LogMsg(msg: "Sanitize file: \(file.filenameOnly) complete !!"))

                            listener.onSingleTaskProgress(id: file.id, progress: 1.0)
                            
                            if(res != .success){
                                listener.onMediaStateChanged(id: file.id, result: .corrupted)
    //                                listener.onConversionProgress(id: file.id, progress: 1.0)
    //                                listener.onLogMsg(LogMsg(msg: "Failed to process \(file.path): \(res) > corrupted"))
                            }else{
                                listener.onMediaStateChanged(id: file.id, result: .sanitized)
    //                                listener.onConversionProgress(id: file.id, progress: 1.0)
    //                                listener.onLogMsg(LogMsg(msg: "Loaded media file \(file.path): \(res) ..."))
                            }
                            
                            await Task.yield()
                            try await Task.sleep(nanoseconds: 100_000_000)
                        
//                        Task { @MainActor in
//                            listener.onConversionProgress(id: file.id, progress: 1.0)
//                        }
//                        ConversionSingleMediaProgressStore.shared.setProgress(1.0, for: file.id, done: true)
                        } catch {
                            print("Failed to process \(file.filename): \(error)")
                            listener.onLogMsg(LogMsg(msg: "Failed to process \(file.filename): \(error)", type: .error))
                        }
                    }
                }
                
                // 3. Drain the remaining tasks in the final batch
                for try await _ in group {
                    completedCount += 1
//                    Task { @MainActor in
//                        listener.onConversionProgress(id: file.id, progress: progress)
//                        listener.onProgress(ProgressUpdate(allCount: totalCount, current: completedCount))  // )(completedCount, totalCount)
//                    }
                    try Task.checkCancellation()
                    if completedCount == totalCount {
//                        listener.onMediaStateChanged(id: file.id, result: .converting)
                        let progress = 1.0 // Double(completedCount) / Double(totalCount) >>> Do we need it???
                        SanitationProgressStore.shared.setProgress(progress, for: id, done: completedCount == totalCount)
                    }
                }
            }
        }
        
        // 4. Batch complete
//        listener.onCompleted(ImportResult(outputPath: "", id: id, taskType: .converted))
        listener.onLogMsg(LogMsg(msg: "Completed sanitizing media files!"))
        reply(id, nil)
    }
    
    public func observeSanitationProgress(taskID: UUID, withReply reply: @escaping (Double, Bool, Error?) -> Void) {
        SanitationProgressStore.shared.withProgress(for: taskID) { progress, done in
//            print("ConversionProgressStore.shared.withProgress(for: \(taskID)) => \(progress), \(done)")
            reply(progress, done, nil)
        }
    }
    
    public func ping(withReply reply: @escaping () -> Void) {
        reply()
    }
    
    func getFFProbeForType(_ type: FFMpegResourceType) -> FFProbeProtocol {
        if(type == .bundledBinaries || type == .homebrewBinaries){
            return FFProbeBinNG()
        }else{
            return FFProbeLibNG()
        }
    }
    
    func getFFMpegForType(_ type: FFMpegResourceType) -> FFMpegProtocol {
        if(type == .bundledBinaries || type == .homebrewBinaries){
            return FFMpegBinNew()
        }else{
            return FFMpegLibNew()
        }
    }
}
