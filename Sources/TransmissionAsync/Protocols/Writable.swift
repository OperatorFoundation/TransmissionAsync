//
//  Writable.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

public protocol Writable
{
    func write(_ data: Data) async throws
}
