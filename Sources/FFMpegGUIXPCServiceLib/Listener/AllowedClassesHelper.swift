//
//  File.swift
//  FFMpegGUIXPCServiceLib
//
//  Created by Kim-David Hauser on 14.06.2026.
//

import Foundation

public final class AAllowedClassesHelper {

    public static func allowClassesForSelector(interface: NSXPCInterface, selector: Selector, argumentIndex: Int, allowedObjects: NSSet, ofReply: Bool = false) -> NSXPCInterface {
        interface.setClasses(allowedObjects as! Set<AnyHashable>, for: selector, argumentIndex: argumentIndex, ofReply: ofReply)
        return interface
    }
}
