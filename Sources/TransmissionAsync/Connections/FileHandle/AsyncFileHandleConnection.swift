//
//  AsyncFileHandleConnection.swift
//
//
//  Created by Dr. Brandon Wiley on 6/17/24.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class AsyncFileHandleConnection: AsyncChannelConnection<FileHandleChannel>
{
    public init(readFile: FileHandle, writeFile: FileHandle, _ logger: Logger, verbose: Bool = false)
    {
        let channel = FileHandleChannel(readFile: readFile, writeFile: writeFile)

        super.init(channel, logger, verbose: verbose)
    }
}

public class AsyncReadOnlyFileHandleConnection: AsyncChannelConnection<ReadOnlyFileHandleChannel>
{
    public init(readFile: FileHandle, _ logger: Logger, verbose: Bool = false)
    {
        let channel = ReadOnlyFileHandleChannel(readFile: readFile)

        super.init(channel, logger, verbose: verbose)
    }
}

public class AsyncWriteOnlyFileHandleConnection: AsyncChannelConnection<WriteOnlyFileHandleChannel>
{
    public init(writeFile: FileHandle, _ logger: Logger, verbose: Bool = false)
    {
        let channel = WriteOnlyFileHandleChannel(writeFile: writeFile)

        super.init(channel, logger, verbose: verbose)
    }
}

public class FileHandleChannel: Channel
{
    public typealias R = FileHandleReadable
    public typealias W = FileHandleWritable

    public var readable: FileHandleReadable
    {
        return self.readFile
    }

    public var writable: FileHandleWritable
    {
        return self.writeFile
    }

    let readFile: FileHandleReadable
    let writeFile: FileHandleWritable

    public init(readFile: FileHandle, writeFile: FileHandle)
    {
        self.readFile = FileHandleReadable(readFile)
        self.writeFile = FileHandleWritable(writeFile)
    }

    public func close() throws
    {
        try self.readFile.handle.close()
        try self.writeFile.handle.close()
    }
}

public class ReadOnlyFileHandleChannel: Channel
{
    public typealias R = FileHandleReadable
    public typealias W = UnimplementedWritable

    public var readable: FileHandleReadable
    {
        return self.readFile
    }

    public var writable: UnimplementedWritable
    {
        return self.writer
    }

    let readFile: FileHandleReadable
    let writer: UnimplementedWritable

    public init(readFile: FileHandle)
    {
        self.readFile = FileHandleReadable(readFile)
        self.writer = UnimplementedWritable()
    }

    public func close() throws
    {
        try self.readFile.handle.close()
    }
}

public class WriteOnlyFileHandleChannel: Channel
{
    public typealias R = UnimplementedReadable
    public typealias W = FileHandleWritable

    public var readable: UnimplementedReadable
    {
        return self.reader
    }

    public var writable: FileHandleWritable
    {
        return self.writeFile
    }

    let reader: UnimplementedReadable
    let writeFile: FileHandleWritable

    public init(writeFile: FileHandle)
    {
        self.writeFile = FileHandleWritable(writeFile)
        self.reader = UnimplementedReadable()
    }

    public func close() throws
    {
        try self.writeFile.handle.close()
    }
}

public enum AsyncFileHandleConnectionError: Error
{
    case readFailed
    case noData
}
