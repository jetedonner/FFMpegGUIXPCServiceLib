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
        
//        let allowed = NSSet(array: [
////            MediaDetailsDTO.self,
//            MediaDetails.self,
//            ProgressUpdate.self,
//            ImportResult.self,
//            TaskResult.self,
//            LogMsg.self,
//            XPCServiceTaskConfigBase.self,
//            XPCServiceImportTaskConfig.self,
//            NSUUID.self,
//            TaskTypeBase.self,
//            NSString.self
//        ])
        
        var listenerInterface = NSXPCInterface(with: ImportProgressListenerLib.self)

        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onLogMsg(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            LogMsg.self
        ]))
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerLib.onLogMsg(_:)),
//            argumentIndex: 0,
//            ofReply: false)
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerNG.onProgress(_:)),
//            argumentIndex: 0,
//            ofReply: false)

        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onCompleted(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            TaskResult.self
        ]))
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerLib.onCompleted(_:)),
//            argumentIndex: 0,
//            ofReply: false)
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onImportedMedia(_:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            MediaDetails.self
        ]))
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerLib.onImportedMedia(_:)),
//            argumentIndex: 0,
//            ofReply: false)
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onBatchTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerLib.onBatchTaskProgress(id:progress:)),
//            argumentIndex: 0,
//            ofReply: false)
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onSingleTaskProgress(id:progress:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        
        
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 0, allowedObjects: NSSet(array: [
            NSUUID.self
        ]))
        listenerInterface = AAllowedClassesHelper.allowClassesForSelector(interface: listenerInterface, selector: #selector(ImportProgressListenerLib.onMediaStateChanged(id:result:)), argumentIndex: 1, allowedObjects: NSSet(array: [
            TaskTypeBase.self
        ]))
        
//        listenerInterface.setClasses(allowed as! Set<AnyHashable>,
//            for: #selector(ImportProgressListenerLib.onSingleTaskProgress(id:progress:)),
//            argumentIndex: 0,
//            ofReply: false)
        
        return listenerInterface
    }
    
    public static func setImportTaskInterface(interface: NSXPCInterface) -> NSXPCInterface {
        var iface = interface
        let selector = #selector(
            FFMpegXPCServiceProtocol.startImportTask(taskConfig:listener:withReply:) //(
                //url:listener:taskConfig:recurseIntoSubDirs:withReply:
            //)
        )

        // 1. listener (argument 1) → remote object, use setInterface
        iface.setInterface(
            ListenerHelperNG.getImportProgressListenerInterface(),
            for: selector,
            argumentIndex: 1,
            ofReply: false
        )

//        // 2. taskConfig (argument 2) → NSSecureCoding object, use setClasses
//        let allowed: Set<AnyClass> = [
//            XPCServiceTaskConfig.self,
//            MediaDetails.self,
//            NSDictionary.self,
//            NSArray.self,
//            NSString.self
//        ]
//
//        interface.setClasses(
//            allowed,
//            for: selector,
//            argumentIndex: 2,
//            ofReply: false
//        )
//        let allowed = NSSet(array: [
//            XPCServiceTaskConfigBase.self,
//            XPCServiceImportTaskConfig.self,
//            MediaDetails.self,
//            NSDictionary.self,
//            NSArray.self,
//            NSUUID.self,
//            NSString.self,
//            TaskResult.self
//        ])
//
//        interface.setClasses(
//            allowed as! Set<AnyHashable>, // as! Set<AnyHashable> as! Set<AnyClass>,
//            for: selector,
//            argumentIndex: 0,
//            ofReply: false
//        )

        iface = AAllowedClassesHelper.allowClassesForSelector(interface: iface, selector: selector, argumentIndex: 0, allowedObjects: NSSet(array: [
            XPCServiceImportTaskConfig.self
        ]))
        
        return iface
    }
}
