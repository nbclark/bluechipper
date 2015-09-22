//
//  Array.swift
//  bluechipper
//
//  Created by Nicholas Clark on 9/19/15.
//  Copyright © 2015 Nicholas Clark. All rights reserved.
//

import Foundation

internal extension Array {
    func uniqueBy <T: Equatable> (call: (Element) -> (T)) -> [Element] {
        var result: [Element] = []
        var uniqueItems: [T] = []
        
        for item in self {
            let callResult: T = call(item)
            if !uniqueItems.contains(callResult) {
                uniqueItems.append(callResult)
                result.append(item)
            }
        }
        
        return result
    }
    
    func union <U: Equatable> (values: [U]...) -> Array {
        
        var result = self
        
        for array in values {
            for value in array {
                if !result.contains(value) {
                    result.append(value as! Element)
                }
            }
        }
        
        return result
        
    }
    
    func contains <T: Equatable> (items: T...) -> Bool {
        return items.all { (item: T) -> Bool in self.indexOf(item) >= 0 }
    }
    
    func all (test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }
        
        return true
    }
    
    func indexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            return self.indexOf({ (object) -> Bool in
                return (object as! U) == item
            })
        }
        
        return nil
    }
}