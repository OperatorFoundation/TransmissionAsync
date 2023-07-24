//
//  AsyncUdpSocketMailbox.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/24/23.
//

import Foundation

import Socket

public class AsyncUdpSocketMailbox: AsyncMailbox
{
    let socket: Socket

    public init(host: String = "0.0.0.0", port: Int = 0) throws
    {
        //let address = Socket.createAddress(for: host, on: Int32(port))
        self.socket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
    }

    public func read() async throws -> (data: Data, address: Socket.Address?)
    {
        var data = Data()
        let (read, from) = try self.socket.readDatagram(into: &data)
        guard data.count == read else
        {
            throw AsyncUdpSocketMailboxError.badReadCount(read, data.count)
        }

        return (data: data, address: from)
    }

    public func write(_ data: Data, address: Socket.Address) async throws
    {
        try self.socket.write(from: data, to: address)
    }

    public func close() async throws
    {
        self.socket.close()
    }
}

public enum AsyncUdpSocketMailboxError: Error
{
    case badReadCount(Int, Int) // actual, expected
}
