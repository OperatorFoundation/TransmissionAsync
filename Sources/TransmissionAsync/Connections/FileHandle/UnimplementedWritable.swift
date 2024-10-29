//
//  UnimplementedWritable.swift
//
//
//  Created by Dr. Brandon Wiley on 6/17/24.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class UnimplementedWritable: Writable
{
    public init()
    {
    }

    public func write(_ data: Data) async throws
    {
        throw UnimplementedWritableError.unimplemented
    }
}

public enum UnimplementedWritableError: Error
{
    case unimplemented
}
