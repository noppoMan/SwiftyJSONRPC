//
//  JSONRPCValidator.swift
//  TSSS-JSONRPCServer
//
//  Created by Yuki Takei on 2016/11/29.
//
//

@_exported import SwiftyJSON

public struct JSONRPCV2 {
    public enum ID {
        case number(Int)
        case string(String)
        
        public var number: Int? {
            switch self {
            case .number(let val):
                return val
            default:
                return nil
            }
        }
        
        public var string: String? {
            switch self {
            case .string(let val):
                return val
            default:
                return nil
            }
        }
    }
}

extension JSONRPCV2 {
    public struct Response {
        public let isBatch: Bool
        public let items: [ResponseItem]
        
        public func toJSON() -> JSON {
            if isBatch {
                return JSON(items.map{$0.toJSON()})
            } else {
                return items[0].toJSON()
            }
        }
    }
    
    public struct ResponseItem {
        public let version = "2.0"
        public let id: ID?
        public let result: Any?
        public let error: JSONRPCV2Error?
        
        public init(id: ID? = nil, result: Any? = nil){
            self.id = id
            self.result = result
            self.error = nil
        }
        
        public init(id: ID? = nil, error: JSONRPCV2Error? = nil){
            self.id = id
            self.result = nil
            self.error = error
        }
        
        public func toJSON() -> JSON {
            var json: JSON = ["jsonrpc": version]
            if let error = error {
                json["error"].object = ["code": error.code, "message": error.message]
            } else if let result = result {
                json["result"].object = result
            }
            
            if let id = id?.number {
                json["id"].int = id
            } else if let id = id?.string {
                json["id"].string = id
            }
            
            return json
        }
    }
}

extension JSONRPCV2 {
    public struct Request {
        public let isBatch: Bool
        public let items: [RequestItem]
    }
    
    public struct RequestItem {
        public let version = "2.0"
        public let id: ID?
        public let method: String?
        public let params: JSON?
        public let error: JSONRPCV2Error?
        
        public init(id: ID? = nil, method: String, params: JSON?){
            self.id = id
            self.method = method
            self.params = params
            self.error = nil
        }
        
        public init(id: ID?, error: JSONRPCV2Error){
            self.id = id
            self.method = nil
            self.params = nil
            self.error = error
        }
    }
}

extension JSONRPCV2 {
    public static func validate(_ json: JSON) -> Request {
        if let _ = json.array {
            return Request(isBatch: true, items: multipleValidate(json))
        } else {
            return Request(isBatch: false, items: [singleValidate(json)])
        }
    }
    
    static func multipleValidate(_ json: JSON) -> [RequestItem] {
        if let array = json.array {
            return array.flatMap { multipleValidate($0) }
        } else {
            return [singleValidate(json)]
        }
    }
    
    static func singleValidate(_ json: JSON) -> RequestItem {
        var id: ID?
        if let _id = json["id"].string {
            id = .string(_id)
        }
        else if let _id = json["id"].int {
            id = .number(_id)
        }
        
        guard let versionString = json["jsonrpc"].string else {
            return RequestItem(id: id, error: .invalidRequest)
        }
        
        if versionString != "2.0" {
            return RequestItem(id: id, error: .invalidRequest)
        }
        
        guard let method = json["method"].string else {
            return RequestItem(id: id, error: .invalidRequest)
        }
        
        return RequestItem(id: id, method: method, params: json["params"].exists() ?  json["params"] : nil)
    }
}
