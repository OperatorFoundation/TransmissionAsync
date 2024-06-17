//
//  File.swift
//  
//
//  Created by Dr. Brandon Wiley on 6/17/24.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class FileHandleWritable: Writable
{
    public let handle: FileHandle

    public init(_ fd: Int32)
    {
        self.handle = FileHandle(fileDescriptor: fd)
    }

    public init(_ fileHandle: FileHandle)
    {
        self.handle = fileHandle
    }

    public func write(_ data: Data) async throws
    {
        await AsyncAwaitAsynchronizer.async
        {
            self.handle.write(data)
        }
    }
}
