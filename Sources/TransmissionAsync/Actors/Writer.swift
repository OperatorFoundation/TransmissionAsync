//
//  Writer.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

public actor Writer<T: Writable>
{
    let writable: T

    public init(_ writable: T)
    {
        self.writable = writable
    }

    public func write(_ data: Data) async throws
    {
        try await self.writable.write(data)
    }

    public func write(_ datas: [Data]) async throws
    {
        for data in datas
        {
            try await self.writable.write(data)
        }
    }
}
