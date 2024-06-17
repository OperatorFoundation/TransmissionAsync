//
//  UnimplementedReadable.swift
//
//
//  Created by Dr. Brandon Wiley on 6/17/24.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class UnimplementedReadable: Readable
{
    public init()
    {
    }

    public func read() async throws -> Data
    {
        throw UnimplementedReadableError.unimplemented
    }

    public func read(_ size: Int) async throws -> Data
    {
        throw UnimplementedReadableError.unimplemented
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        throw UnimplementedReadableError.unimplemented
    }
}

public enum UnimplementedReadableError: Error
{
    case unimplemented
}
