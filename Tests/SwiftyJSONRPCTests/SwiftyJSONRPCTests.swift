import XCTest
@testable import SwiftyJSONRPC

class SwiftyJSONRPCTests: XCTestCase {
    static var allTests : [(String, (SwiftyJSONRPCTests) -> () throws -> Void)] {
        return [
            ("testSingle", testSingle),
            ("testBatch", testBatch),
            ("testResponseBatch", testResponseBatch),
            ("testBatchMixedError", testBatchMixedError),
            ("testResponseSerialize", testResponseSerialize),
            ("testRequestSerialize", testRequestSerialize)
        ]
    }
    
    func testSingle() {
        let json: JSON = ["jsonrpc": "2.0", "id": 1, "method": "sum", "params": [1, 1]]
        let request = JSONRPCV2.Request(json: json)
        XCTAssertEqual(request.isBatch, false)
        XCTAssertEqual(request.items[0].id?.number, 1)
        XCTAssertEqual(request.items[0].method, "sum")
        XCTAssertEqual(request.items[0].params!.arrayValue.flatMap { $0.int }, [1, 1])
    }
    
    func testBatch() {
        let json: JSON = [
            ["jsonrpc": "2.0", "id": 1, "method": "sum", "params": [1, 1]],
            ["jsonrpc": "2.0", "id": 2, "method": "mul", "params": [1, 1]],
            ["jsonrpc": "2.0", "id": 3, "method": "div", "params": [10, 2]],
        ]
        
        let request = JSONRPCV2.Request(json: json)
        XCTAssertEqual(request.isBatch, true)
        XCTAssertEqual(request.items[0].id?.number, 1)
        XCTAssertEqual(request.items[0].method, "sum")
        XCTAssertEqual(request.items[0].params!.arrayValue.flatMap { $0.int }, [1, 1])

        XCTAssertEqual(request.items[1].id?.number, 2)
        XCTAssertEqual(request.items[1].method, "mul")
        XCTAssertEqual(request.items[1].params!.arrayValue.flatMap { $0.int }, [1, 1])
        
        XCTAssertEqual(request.items[2].id?.number, 3)
        XCTAssertEqual(request.items[2].method, "div")
        XCTAssertEqual(request.items[2].params!.arrayValue.flatMap { $0.int }, [10, 2])
    }
    
    func testBatchMixedError() {
        let json: JSON = [
            ["jsonrpc": "2.0", "id": 1, "method": "sum", "params": [1, 1]],
            ["id": 2, "method": "mul", "params": [1, 1]],
            ["jsonrpc": "2.0", "id": 3, "params": [1, 1]],
            ["jsonrpc": "2.0", "id": 4, "method": "div", "params": [10, 2]],
        ]
        
        let request = JSONRPCV2.Request(json: json)
        XCTAssertEqual(request.isBatch, true)
        XCTAssertEqual(request.items[0].id?.number, 1)
        XCTAssertEqual(request.items[0].method, "sum")
        XCTAssertEqual(request.items[0].params!.arrayValue.flatMap { $0.int }, [1, 1])
        
        XCTAssertEqual(request.items[1].id?.number, 2)
        XCTAssertNotNil(request.items[1].error)
        
        XCTAssertEqual(request.items[2].id?.number, 3)
        XCTAssertNotNil(request.items[2].error)
        
        XCTAssertEqual(request.items[3].id?.number, 4)
        XCTAssertEqual(request.items[3].method, "div")
        XCTAssertEqual(request.items[3].params!.arrayValue.flatMap { $0.int }, [10, 2])
    }
    
    func testResponseBatch(){
        let json: JSON = [
            ["jsonrpc": "2.0", "result": [1]],
            ["jsonrpc": "2.0", "id": 2, "error": ["code": -32700, "messaage": "Parse Error"]],
            ["jsonrpc": "2.0", "id": 3, "result": [2]]
        ]
        
        let response = JSONRPCV2.Response(json: json)
        XCTAssertEqual(response.isBatch, true)
        XCTAssertEqual(response.items[0].result!.array!, [1])
        XCTAssertNotNil(response.items[1].error)
        XCTAssertEqual(response.items[2].result!.array!, [2])
    }
    
    func testResponseSerialize(){
        let response = JSONRPCV2.Response(
            isBatch: true,
            items: [
                JSONRPCV2.ResponseItem(id: .number(1), result: [1, 2]),
                JSONRPCV2.ResponseItem(id: .number(2), error: .invalidRequest),
            ]
        )
        
        let json = response.toJSON().array
        XCTAssertEqual(json![0].dictionary!["id"]?.int, 1)
        XCTAssertEqual(json![1].dictionary!["id"]?.int, 2)
    }
    
    func testRequestSerialize(){
        let response = JSONRPCV2.Request(
            isBatch: true,
            items: [
                JSONRPCV2.RequestItem(id: .number(1), method: "sum", params: [1, 2]),
                JSONRPCV2.RequestItem(id: .number(2), error: .invalidRequest),
            ]
        )
        
        let json = response.toJSON().array
        XCTAssertEqual(json![0].dictionary!["id"]?.int, 1)
        XCTAssertEqual(json![1].dictionary!["id"]?.int, 2)
    }
}
