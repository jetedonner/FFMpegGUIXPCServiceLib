//
//  File.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//

import Foundation
import Combine
import Dispatch
import XPC
import FFMpegSwiftManagerLib

public class ListenerHelperNG {
    
    public init() { }
    
    public static func getImportProgressListenerInterface() -> NSXPCInterface {
        
        var listenerInterface = NSXPCInterface(with: ImportProgressListenerLib.self)

        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onLogMsg(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            LogMsg.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onCompleted(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            TaskResult.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onImportedMedia(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            MediaDetails.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onBatchTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onSingleTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 1, allowedObjects: NSSet(array: [
            TaskTypeBase.self
        ]))
        
        return listenerInterface
    }
    
    public static func setImportTaskInterface(interface: NSXPCInterface) -> NSXPCInterface {
        var iface = interface
        let selector = #selector(
            FFMpegXPCServiceProtocol.startImportTask(taskConfig:listener:withReply:)
        )

        // 1. listener (argument 1) → remote object, use setInterface
        iface.setInterface(
            ListenerHelperNG.getImportProgressListenerInterface(),
            for: selector,
            argumentIndex: 1,
            ofReply: false
        )

        iface = AAllowedClassesHelper.allowClassesForSelector(interface: iface, selector: selector, argumentIndex: 0, allowedObjects: NSSet(array: [
            XPCServiceImportTaskConfig.self
        ]))
        
        return iface
    }
    
    
    public static func getCheckIntegrityProgressListenerInterface() -> NSXPCInterface {

        var listenerInterface = NSXPCInterface(with: ImportProgressListenerLib.self)

        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onLogMsg(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            LogMsg.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onCompleted(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            TaskResult.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onImportedMedia(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            MediaDetails.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onBatchTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onSingleTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(IntegrityCheckProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 1, allowedObjects: NSSet(array: [
            TaskTypeBase.self
        ]))
        
        return listenerInterface
    }
    
    public static func setCheckIntegrityTaskInterface(interface: NSXPCInterface) -> NSXPCInterface {
        var iface = interface
        let selector = #selector(
            FFMpegXPCServiceProtocol.startIntegrityCheckTask(md:taskConfig:listener:withReply:) //(
        )
        
        iface.setInterface(
            ListenerHelperNG.getCheckIntegrityProgressListenerInterface(),
            for: selector,
            argumentIndex: 2,
            ofReply: false
        )
        
        iface = AAllowedClassesHelper.allowClassesForSelector(interface: iface, selector: selector, argumentIndex: 0, allowedObjects: NSSet(array: [
            NSArray.self,
            MediaDetails.self
        ]))
        
        iface = AAllowedClassesHelper.allowClassesForSelector(interface: iface, selector: selector, argumentIndex: 1, allowedObjects: NSSet(array: [
            XPCServiceIntegrityCheckTaskConfig.self
        ]))
        
        return iface
    }
}
