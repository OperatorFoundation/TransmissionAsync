import Logging
import XCTest
@testable import TransmissionAsync
import Chord

final class TransmissionAsyncTests: XCTestCase
{
    let logger = Logger(label: "Testing")

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
        let _ = await withThrowingTaskGroup(of: Bool.self)
        {
            group -> Bool in
            
            group.addTask
            {
                let listener = try AsyncTcpSocketListener(port: 1234, self.logger)
                let _ = try await listener.accept()
                return true
            }
            
            group.addTask
            {
                let _ = try await AsyncTcpSocketConnection("localhost", 1234, self.logger)
                return true
            }
            
            return true
        }
    }

    func testTaskConcurrency2() async throws
    {
        Task
        {
            let listener = try AsyncTcpSocketListener(port: 1235, self.logger)
            let _ = try await listener.accept()
        }

        Task
        {
            let _ = try await AsyncTcpSocketConnection("localhost", 1235, self.logger)
        }
    }

    func testTaskConcurrency3() async throws
    {
        let queue1 = DispatchQueue(label: "queue1")
        let queue2 = DispatchQueue(label: "queue2")

        queue1.async
        {
            do
            {
                let listener = try AsyncTcpSocketListener(port: 1235, self.logger)

                try AsyncAwaitThrowingSynchronizer<Void>.sync
                {
                    let _ = try await listener.accept()
                }
            }
            catch
            {
                XCTFail()
                return
            }
        }

        queue2.async
        {
            do
            {
                try AsyncAwaitThrowingSynchronizer<Void>.sync
                {
                    let _ = try await AsyncTcpSocketConnection("localhost", 1235, self.logger)
                }
            }
            catch
            {
                XCTFail()
                return
            }
        }
    }

    func testStdio() async throws
    {
        let connection = AsyncStdioConnection(logger)
        let data = try await connection.readSize(4)
        try await connection.write(data)
    }
}
