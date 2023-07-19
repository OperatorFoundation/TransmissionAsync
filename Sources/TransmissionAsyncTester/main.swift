//
//  main.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/18/23.
//

import Foundation

//
//  main.swift
//
//
//  Created by Dr. Brandon Wiley on 7/18/23.
//

#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif
import Foundation
#if os(macOS) || os(iOS)
#else
import FoundationNetworking
#endif

import TransmissionAsync

#if os(macOS)
let logger = Logger(subsystem: "TransmissionAsyncTests", category: "Testing")
#else
let logger = Logger(label: "Testing")
#endif

let connection = AsyncStdioConnection(logger)
let data = try await connection.readSize(4)
try await connection.write(data)
