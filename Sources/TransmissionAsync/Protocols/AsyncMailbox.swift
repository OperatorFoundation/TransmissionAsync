//
//  AsyncMailbox.swift
//
//
//  Created by Dr. Brandon Wiley on 7/24/23.
//

import Foundation
import Logging

import Socket

public protocol AsyncMailbox
{
    // Reads an amount of data decided by magic
    func read() async throws -> (data: Data, address: Socket.Address?)

    func write(_ data: Data, address: Socket.Address) async throws

    func close() async throws
}
