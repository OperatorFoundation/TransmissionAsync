import XCTest
@testable import TransmissionAsync

final class TransmissionAsyncTests: XCTestCase
{
    func testConnect() async throws
    {
        let _ = try await AsyncTcpSocketConnection("142.250.138.139", 443)
    }

    func testListen() async throws
    {
        let _ = try AsyncTcpSocketListener(port: 1234)
    }

    func testListenConnect() async throws
    {
        let listener = try AsyncTcpSocketListener(port: 1234)
        Task
        {
            try await listener.accept()
        }

        let _ = try await AsyncTcpSocketConnection("127.0.0.1", 1234)
    }

    func testListenConnectReadWrite() async throws
    {
        let listener = try AsyncTcpSocketListener(port: 1234)
        Task
        {
            let serverConnection = try await listener.accept()
            let data = try await serverConnection.readSize(4)
            try await serverConnection.write(data)
        }

        let data = Data(repeating: 65, count: 4)
        let clientConnection = try await AsyncTcpSocketConnection("127.0.0.1", 1234)
        try await clientConnection.write(data)

        let result = try await clientConnection.readSize(4)

        XCTAssertEqual(data, result)
    }
}
