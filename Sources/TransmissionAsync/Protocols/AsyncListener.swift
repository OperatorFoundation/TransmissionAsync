//
//  AsyncListener.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

public protocol AsyncListener
{
    associatedtype C: Channel

    func accept() async throws -> AsyncConnection<C>
}
