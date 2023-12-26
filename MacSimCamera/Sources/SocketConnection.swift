//
//  SocketConnection.swift
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

import Network

class SocketConnection {
    
    var connection: NWConnection?
    var onReceiveData: (_ data: Data) -> Void = { _ in }
    var onComplete: () -> Void = {}
    let port: Int
    
    init(port: Int = 8899) {
        self.port = port
    }

    func start() {
        let connection = NWConnection(
            host: "127.0.0.1",
            port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)),
            using: .tcp
        )
        self.connection = connection
        stateHandler(on: connection)
        setupReceive(on: connection)
        connection.start(queue: .main)
    }
    
    func cancel() {
        connection?.cancel()
    }
    
    func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 512000) { (data, contentContext, isComplete, error) in
            if let data = data, !data.isEmpty {
                self.onReceiveData(data)
            }
            if isComplete {
                connection.cancel()
                self.onComplete()
                log("Connection disconnected")
            } else if let error = error {
                connection.cancel()
                log("⚠️ \(error.localizedDescription)")
            } else {
                self.setupReceive(on: connection)
            }
        }
    }
    
    func stateHandler(on connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            switch state {
            case .setup:
                log("Connection setup")
            case .waiting(_):
                log("Connection waiting")
            case .preparing:
                log("Connection preparing")
            case .ready:
                log("Connection ready to receive data")
            case .failed(let error):
                log("⚠️ Connection failed: \(error.localizedDescription)")
            case .cancelled:
                break
            @unknown default:
                break
            }
        }
    }
}
