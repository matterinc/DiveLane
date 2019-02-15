//
//  IgnisTransaction.swift
//  Franklin
//
//  Created by Anton on 12/02/2019.
//  Copyright © 2019 Matter Inc. All rights reserved.
//

import Foundation
import EthereumAddress
import BigInt

import JavaScriptCore

public class TransactionIgnis {
    
    private let vm = JSVirtualMachine()
    
    lazy var context: JSContext? = {
        let context = JSContext(virtualMachine: vm)
        guard let
            jsPath = Bundle.main.path(forResource: "bundle", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        do {
            let bundle = try String(contentsOfFile: jsPath, encoding: String.Encoding.utf8)
            print(bundle)
            context?.evaluateScript(bundle)
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }
        
        return context
    }()
    
    func createTransaction(from: BigUInt, to: BigUInt, amount: BigUInt, fee: BigUInt = 0, nonce: BigUInt = 0, goodUntilBlock: BigUInt = 10000, privateKey: String) throws -> [AnyHashable : Any] {
        guard let context = context else {
            print("JSContext not found.")
            throw PlasmaErrors.StructureErrors.wrongData
        }
        
        context.exceptionHandler = { context, exception in
            if let exc = exception {
                print("JS Exception:", exc.toString())
            }
        }
        
//        guard let createTransactionFunction = context.objectForKeyedSubscript("add") else {
//            print("Unable to parse JSON")
//            return
//        }
        
        guard let createTransactionFunction = context.objectForKeyedSubscript("createTransaction") else {
            print("Unable to parse JSON")
            throw PlasmaErrors.StructureErrors.wrongData
        }
//        let add = addFunction?.invokeMethod("add", withArguments: [])
//        return add
        guard let createTransaction = createTransactionFunction.call(withArguments: [from, to, amount, fee, nonce, goodUntilBlock, privateKey]) else {
            print("Unable to parse JSON")
            throw PlasmaErrors.StructureErrors.wrongData
        }
//        guard let createTransaction = createTransactionFunction.call(withArguments: []) else {
//            print("Unable to parse JSON")
//            return
//        }
        print(createTransaction.isNull)
        print(createTransaction.isUndefined)
        print(createTransaction.isArray)
        print(createTransaction.isObject)
        print(createTransaction.isString)
        print(createTransaction.isNumber)
        print(createTransaction.isBoolean)
        
        guard let tx = createTransaction.toDictionary() else {
            throw PlasmaErrors.StructureErrors.wrongData
        }
        return tx
        
//        print(createTransaction.toDictionary())
    }
}