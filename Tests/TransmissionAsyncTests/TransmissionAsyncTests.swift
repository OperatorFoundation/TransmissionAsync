import Logging
import XCTest
@testable import TransmissionAsync
import Chord
import Socket

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

    func testTaskConcurrency2a() async throws
    {
        
        let task1Complete = Task
        {
            
            let listener = try AsyncTcpSocketListener(port: 1235, self.logger)
            let _ = try await listener.accept()
            print("Task 1")
        }

        let task2Complete = Task
        {
            let _ = try await AsyncTcpSocketConnection("localhost", 1235, self.logger)
            print("Task 2")
        }
        
        let _ = try await task1Complete.value
        let _ = try await task2Complete.value
    }
    
    func testTaskConcurrency2b() async throws
    {
        
        let task1Complete = Task
        {
            
            let listener = try AsyncTcpSocketListener(port: 1235, self.logger)
            let clientConnection = try await listener.accept()
            let readResult = try await clientConnection.readSize(18)
            XCTAssertNotNil(readResult)
            print("Received a message from a client: \(readResult.string)")
            try await clientConnection.writeString(string: "Server says hello.")
        }

        let task2Complete = Task
        {
            let connection = try await AsyncTcpSocketConnection("localhost", 1235, self.logger)
            try await connection.writeString(string: "Client says hello.")
            let readResult = try await connection.readSize(18)
            XCTAssertNotNil(readResult)
            print("Received a message from the server: \(readResult.string)")
        }
        
        let _ = try await task1Complete.value
        let _ = try await task2Complete.value
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

    func testUdpServer() throws
    {
        let read = XCTestExpectation(description: "server read from client")
        let wrote = XCTestExpectation(description: "client wrote to serfer")

        let correct = "asdf".data

        let host = "127.0.0.1"
        let port = 4455

        Task
        {
            let server = try AsyncUdpSocketMailbox(host: host, port: port)

            let (data, from) = try await server.read()
            print("read \(data)")
            print(from.debugDescription)
            XCTAssert(data == correct)

            read.fulfill()
        }

        wait(for: [read, wrote], timeout: 60)
    }


    func testUdpClientAndServer() throws
    {
        let read = XCTestExpectation(description: "server read from client")
        let wrote = XCTestExpectation(description: "client wrote to serfer")

        let correct = "asdf".data

        let host = "127.0.0.1"
        let port = 4455

        let lock = DispatchSemaphore(value: 0)

        Task
        {
            let server = try AsyncUdpSocketMailbox(host: "127.0.0.1", port: 4455)

            lock.signal()

            let (data, from) = try await server.read()
            print("read \(data)")
            print(from.debugDescription)
            XCTAssert(data == correct)

            read.fulfill()
        }

        lock.wait()

        Task
        {
            let client = try AsyncUdpSocketMailbox()
            try await client.write("test", address: Socket.createAddress(for: host, on: Int32(port))!)
            wrote.fulfill()
        }

        wait(for: [read, wrote], timeout: 60)
    }

    func testUDPProxy() async throws
    {
        print("Starting the UDP Proxy test!")
        let logger = Logger(label: "UDPProxyTestLogger")

        print("Attempting to write data...")
        let asyncConnection = try await AsyncTcpSocketConnection("146.190.137.108", 1233, logger, verbose: true)
        let dataString = "0000000a7f000001000774657374"
        guard let data = Data(hex: dataString) else
        {
            XCTFail()
            return
        }

        try await asyncConnection.write(data)

        print("Wrote \(data.count) bytes, attempting to read some data...")
                let responseData = try await asyncConnection.readWithLengthPrefix(prefixSizeInBits: 32)
//        let responseData = try await asyncConnection.readSize(14)

        print("Received \(responseData.count) bytes of response data: \n\(responseData.hex)")
    }
}
