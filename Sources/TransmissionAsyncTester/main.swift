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

import Logging
import Foundation
#if os(macOS) || os(iOS)
#else
import FoundationNetworking
#endif

import TransmissionAsync

let logger = Logger(label: "Testing")

let connection = AsyncSystemdConnection(logger)
let data = try await connection.readSize(4)
try await connection.write(data)
