////
////  NameHash.swift
////  DiveLane
////
////  Created by Anton Grigorev on 07/12/2018.
////  Copyright © 2018 Matter Inc. All rights reserved.
////
//
//import Foundation
//import CryptoSwift
//
//public struct NameHash {
//    public static func normalizeDomainName(_ domain: String) -> String? {
//        let normalized = domain.lowercased()
//        return normalized
//    }
//
//    public static func nameHash(_ domain: String) -> Data? {
//        guard let normalized = NameHash.normalizeDomainName(domain) else {return nil}
//        return namehash(normalized)
//    }
//
//    static func namehash(_ name: String) -> Data? {
//        if name == "" {
//            return Data(repeating: 0, count: 32)
//        }
//        let parts = name.split(separator: ".")
//        guard parts.count > 0 else {
//            return nil
//        }
//        guard let lowerLevel = parts.first else {
//            return nil
//        }
//        var remainder = ""
//        if parts.count > 1 {
//            remainder = parts[1 ..< parts.count].joined(separator: ".")
//        }
//        var hashData = Data()
//        guard let remainderHash = namehash(remainder) else {
//            return nil
//        }
//        guard let labelData = lowerLevel.data(using: .utf8) else {
//            return nil
//        }
//        hashData.append(remainderHash)
//        hashData.append(labelData.sha3(.keccak256))
//        let hash = hashData.sha3(.keccak256)
//        print(name)
//        print(hash.toHexString())
//        return hash
//    }
//}
