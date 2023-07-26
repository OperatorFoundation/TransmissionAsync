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
    let logger: Logger

    public init(_ writable: T, _ logger: Logger)
    {
        self.writable = writable
        self.logger = logger
    }

    public func write(_ data: Data) async throws
    {
        try await self.writable.write(data)
    }

    public func write(_ datas: [Data]) async throws
    {
        let data = datas.reduce(Data(), (+))
        try await self.writable.write(data)
    }
}
