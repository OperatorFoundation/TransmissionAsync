//
//  AsyncChannelListener.swift
//  TransmissionAsync
//
//  Created by Dr. Brandon Wiley on 7/6/23.
//

import Foundation

public protocol AsyncChannelListener
{
    associatedtype C: Channel

    func accept() async throws -> AsyncChannelConnection<C>
}
