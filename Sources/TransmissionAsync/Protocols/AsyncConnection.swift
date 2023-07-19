//
//  AsyncConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

public protocol AsyncConnection
{
    // Reads an amount of data decided by magic
    func read() async throws -> Data

    // Reads exactly size bytes
    func readSize(_ size: Int) async throws -> Data

    // reads up to maxSize bytes
    func readMaxSize(_ maxSize: Int) async throws -> Data

    func readWithLengthPrefix(prefixSizeInBits: Int) async throws -> Data

    func writeString(string: String) async throws

    func write(_ data: Data) async throws

    func writeWithLengthPrefix(_ data: Data, _ prefixSizeInBits: Int) async throws

    func close() async throws
}
