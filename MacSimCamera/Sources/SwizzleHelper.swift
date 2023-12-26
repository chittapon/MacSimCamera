//
//  SwizzleHelper.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import Foundation

class SwizzleHelper {
    
    static func exchange(_ selector: Selector, with replacementSelector: Selector, oldClass: AnyClass, newClass: AnyClass) {
        let origMethod: Method? = class_getClassMethod(oldClass, selector) ?? class_getInstanceMethod(oldClass, selector)
        let replacementMethod: Method? = class_getClassMethod(newClass, replacementSelector) ?? class_getClassMethod(newClass, replacementSelector)
        if let origMethod = origMethod, let replacementMethod = replacementMethod {
            method_exchangeImplementations(origMethod, replacementMethod)
        }
    }
    
    static func replace(oldClass: AnyClass?, newClass: AnyClass?) {
        var methodCount: UInt32 = 0, swizzled = 0
        if let methods = class_copyMethodList(newClass, &methodCount) {
            for i in 0 ..< Int(methodCount) {
                let selector = method_getName(methods[i])
                let replacement = method_getImplementation(methods[i])
                guard let method = class_getInstanceMethod(oldClass, selector) ??
                                    class_getInstanceMethod(newClass, selector),
                      let _ = i < 0 ? nil : method_getImplementation(method) else {
                    continue
                }
                if class_replaceMethod(oldClass, selector, replacement,
                    method_getTypeEncoding(methods[i])) != replacement {
                    swizzled += 1
                }
            }
            free(methods)
        }
    }
}
