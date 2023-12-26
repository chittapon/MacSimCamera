//
//  Log.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import Foundation

let APP_PREFIX = "ℹ️ MacSimCamera: "
func log(_ what: Any...) {
    print(APP_PREFIX+what.map {"\($0)"}.joined(separator: " "))
}
