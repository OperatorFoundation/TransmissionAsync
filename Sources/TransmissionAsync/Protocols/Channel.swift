//
//  Channel.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

public protocol Channel
{
    associatedtype R: Readable
    associatedtype W: Writable

    var readable: R { get }
    var writable: W { get }

    func close()
}
