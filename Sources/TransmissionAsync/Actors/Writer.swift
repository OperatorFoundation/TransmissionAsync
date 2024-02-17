//
//  Writer.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

public actor Writer<T: Writable>
{
    let writable: T
    var logger: Logger

    public init(_ writable: T, _ logger: Logger)
    {
        self.writable = writable
        self.logger = logger
        self.logger.logLevel = Logger.Level.debug
    }

    public func write(_ data: Data) async throws
    {
        logger.debug("🦠 TransmissionAsync.Writer<\(writable)>.write(data: \(data.count) bytes")
        try await self.writable.write(data)
    }

    public func write(_ datas: [Data]) async throws
    {
        logger.debug("🦠 TransmissionAsync.Writer<\(writable)>.write(datas: \(datas.count) items")
        let data = datas.reduce(Data(), (+))
        try await self.writable.write(data)
    }

    public func writeWithLengthPrefix(_ data: Data, _ prefixSizeInBits: Int) async throws
    {
        logger.debug("🦠 TransmissionAsync.Writer<\(writable)>.writeWithLengthPrefix(data: \(data.count) bytes, prefixSizeInBits: \(prefixSizeInBits)")
        
        let length: Int = data.count
        
        logger.debug("TransmissionAsync.Writer<\(writable)>.writeWithLengthPrefix: length of data to write is \(length)")

        let lengthBytes: Data
        switch prefixSizeInBits
        {
            case 8:
                let length8 = UInt8(length)
                guard let lengthData = length8.maybeNetworkData else
                {
                    throw WriterError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 16:
                let length16 = UInt16(length)
                guard let lengthData = length16.maybeNetworkData else
                {
                    throw WriterError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 32:
                let length32 = UInt32(length)
                guard let lengthData = length32.maybeNetworkData else
                {
                    throw WriterError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 64:
                let length64 = UInt64(length)
                guard let lengthData = length64.maybeNetworkData else
                {
                    throw WriterError.badLengthPrefix
                }

                lengthBytes = lengthData

            default:
                throw WriterError.badLengthPrefix
        }
        
        logger.debug("TransmissionAsync.writeWithLengthPrefix: Writing length bytes: \(lengthBytes.hex) + data (\(data.count) bytes)")
        
        if lengthBytes[0] > 0
        {
            logger.debug("🦠 Weird lengthBytes[0] value: \(lengthBytes[0])")
        }

        try await self.writable.write(lengthBytes + data)
    }
}

public enum WriterError: Error
{
    case badLengthPrefix
}
