//
//  Readable.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

public protocol Readable
{
    func read(_ size: Int) async throws -> Data
}
