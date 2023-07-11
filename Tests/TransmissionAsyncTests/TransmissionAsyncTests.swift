#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif
import XCTest
@testable import TransmissionAsync

final class TransmissionAsyncTests: XCTestCase
{
    #if os(macOS)
    let logger = Logger(subsystem: "TransmissionAsyncTests", category: "Testing")
    #else
    let logger = Logger(label: "Testing")
    #endif

    func testConnect() async throws
    {
        let _ = try await AsyncTcpSocketConnection("142.250.138.139", 443, logger)
    }

    func testListen() async throws
    {
        let _ = try AsyncTcpSocketListener(port: 1234, logger)
    }

    func testListenConnect() async throws
    {
        let listener = try AsyncTcpSocketListener(port: 1234, logger)
        Task
        {
            try await listener.accept()
        }

        let _ = try await AsyncTcpSocketConnection("127.0.0.1", 1234, logger)
    }

    func testListenConnectReadWrite() async throws
    {
        let listener = try AsyncTcpSocketListener(port: 1234, logger)
        Task
        {
            let serverConnection = try await listener.accept()
            let data = try await serverConnection.readSize(4)
            try await serverConnection.write(data)
        }

        let data = Data(repeating: 65, count: 4)
        let clientConnection = try await AsyncTcpSocketConnection("127.0.0.1", 1234, logger)
        try await clientConnection.write(data)

        let result = try await clientConnection.readSize(4)

        XCTAssertEqual(data, result)
    }
    
    func testTaskConcurrency() async throws
    {
        let listener = try AsyncTcpSocketListener(port: 1234, logger)
        let _ = await withThrowingTaskGroup(of: Bool.self)
        {
            group -> Bool in
            
            group.addTask
            {
                let _ = try await listener.accept()
                return true
            }
            
            group.addTask
            {
                print("💥  Or something")
                return true
            }
            
            return true
        }
    }
}
