//
//  AsyncConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

public protocol AsyncConnection
{
    // Reads an amount of data decided by magic
    func read() async throws -> Data

    // Reads exactly size bytes
    func readSize(_ size: Int) async throws -> Data

    // reads up to maxSize bytes
    func readMaxSize(_ maxSize: Int) async throws -> Data

    // reads at least minSize bytes and up to maxSize bytes
    func readMinMaxSize(_ minSize: Int, _ maxSize: Int) async throws -> Data

    func readWithLengthPrefix(prefixSizeInBits: Int) async throws -> Data

    func readWithLengthPrefixNonblocking(prefixSizeInBits: Int) async throws -> Data

    func writeString(string: String) async throws

    func write(_ data: Data) async throws

    func writeWithLengthPrefix(_ data: Data, _ prefixSizeInBits: Int) async throws

    func close() async throws
}
