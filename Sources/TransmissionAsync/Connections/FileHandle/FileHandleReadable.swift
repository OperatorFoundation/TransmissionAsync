//
//  FileHandleReadable.swift
//
//
//  Created by Dr. Brandon Wiley on 6/17/24.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class FileHandleReadable: Readable
{
    public let handle: FileHandle

    let straw: Straw = Straw()

    public init(_ fd: Int32)
    {
        self.handle = FileHandle(fileDescriptor: fd)
    }

    public init(_ fileHandle: FileHandle)
    {
        self.handle = fileHandle
    }

    public func read() async throws -> Data
    {
        return await AsyncAwaitAsynchronizer.async
        {
            return self.handle.availableData
        }
    }

    public func read(_ size: Int) async throws -> Data
    {
        if size == 0
        {
            return Data()
        }

        return try await AsyncAwaitAsynchronizer.async
        {
            while self.straw.count < size
            {
                guard let data = try self.handle.read(upToCount: size) else
                {
                    throw AsyncStdioConnectionError.readFailed
                }

                self.straw.write(data)
            }

            let result = try self.straw.read(size: size)
            return result
        }
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        throw AsyncStdioConnectionError.unimplemented
    }
}
