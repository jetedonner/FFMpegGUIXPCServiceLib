//
//  File.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//

import Foundation

public final class AAllowedClassesHelper {
//    public static var allowedClasses: [AnyClass] {
//        [NSNull.self, NSNumber.self, String.self, Data.self]
//    }
    
    public static func allowClassesForSelector(interface: NSXPCInterface, selector: Selector, argumentIndex: Int, allowedObjects: NSSet) -> NSXPCInterface {
//        var interface = NSXPCInterface(with: (any FFMpegXPCServiceProtocol).self)
        
//        interface = ListenerHelperNG.setImportTaskInterface(interface: interface)
//        interface = ListenerHelper.setImportTaskNGInterface(interface: interface)
//        interface = ListenerHelper.setImportTaskInterface(interface: interface)
//        interface = ListenerHelper.setCheckIntegrityTaskInterface(interface: interface)
////        interface = ListenerHelper.setCheckIntegrityTaskInterface(interface: interface)
//        interface = ListenerHelper.setConversionTaskInterface(interface: interface)
//        interface = ListenerHelper.setSanitizerTaskInterface(interface: interface)
        
        
//        let allowed = NSSet(array: [
//            NSArray.self, MediaDetails.self, NSDictionary.self, XPCServiceTaskConfigBase.self, XPCServiceImportTaskConfig.self, NSString.self, TaskResult.self
//        ])
        
////        let allowed = NSSet(array: [
////            NSArray.self, MediaDetails.self
////        ])
        interface.setClasses(allowedObjects as! Set<AnyHashable>, for: selector, argumentIndex: argumentIndex, ofReply: false)
        return interface
    }
}
