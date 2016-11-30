//
//  JSONRPCValidator.swift
//  TSSS-JSONRPCServer
//
//  Created by Yuki Takei on 2016/11/29.
//
//

@_exported import SwiftyJSON

public protocol JSONTransformable {
    func toJSON() -> JSON
}

public protocol JSONRPCV2BaseT: JSONTransformable {
    associatedtype ItemType: JSONTransformable
    var isBatch: Bool { get }
    var items: [ItemType] { get }
}

extension JSONRPCV2BaseT {
    public func toJSON() -> JSON {
        if isBatch {
            return JSON(items.map{$0.toJSON()})
        } else {
            return items[0].toJSON()
        }
    }
}

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
    public struct Response: JSONRPCV2BaseT {
        public let isBatch: Bool
        public let items: [ResponseItem]
        
        public init(isBatch: Bool, items: [ResponseItem]){
            self.isBatch = isBatch
            self.items = items
        }
    }
    
    public struct ResponseItem: JSONTransformable {
        public let version = "2.0"
        public let id: ID?
        public let result: JSON?
        public let error: JSONRPCV2Error?
        
        public init(id: ID? = nil, result: JSON? = nil){
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
    public struct Request: JSONRPCV2BaseT {
        public let isBatch: Bool
        public let items: [RequestItem]
        
        public init(isBatch: Bool, items: [RequestItem]){
            self.isBatch = isBatch
            self.items = items
        }
    }
    
    public struct RequestItem: JSONTransformable {
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
        
        public func toJSON() -> JSON {
            var json: JSON = ["jsonrpc": version]
            
            if let id = id?.number {
                json["id"].int = id
            } else if let id = id?.string {
                json["id"].string = id
            }
            
            if let error = error {
                json["error"].object = ["code": error.code, "message": error.message]
            } else {
                json["method"].string = method!
                if let params = params {
                    json["params"].object = params
                }
            }
            
            return json
        }
    }
}

extension JSONRPCV2.Response {
    public init(json: JSON){
        if let _ = json.array {
            self.init(isBatch: true, items: JSONRPCV2.Response.multipleValidate(json))
        } else {
            self.init(isBatch: false, items: [JSONRPCV2.Response.singleValidate(json)])
        }
    }
    
    static func multipleValidate(_ json: JSON) -> [JSONRPCV2.ResponseItem] {
        if let array = json.array {
            return array.flatMap { multipleValidate($0) }
        } else {
            return [singleValidate(json)]
        }
    }
    
    static func singleValidate(_ json: JSON) -> JSONRPCV2.ResponseItem {
        var id: JSONRPCV2.ID?
        if let _id = json["id"].string {
            id = .string(_id)
        }
        else if let _id = json["id"].int {
            id = .number(_id)
        }
        
        guard let versionString = json["jsonrpc"].string else {
            return JSONRPCV2.ResponseItem(id: id, error: .invalidRequest)
        }
        
        if versionString != "2.0" {
            return JSONRPCV2.ResponseItem(id: id, error: .invalidRequest)
        }
        
        if json["error"].exists() {
            guard let errCode = json["error"]["code"].int, let errMsg = json["error"]["message"].string else {
                return JSONRPCV2.ResponseItem(id: id, error: JSONRPCV2Error.parseError)
            }
            return JSONRPCV2.ResponseItem(id: id, error: JSONRPCV2Error.raw(errCode, errMsg))
        }
        
        return JSONRPCV2.ResponseItem(id: id, result: json["result"].exists() ?  json["result"] : nil)
    }
}


extension JSONRPCV2.Request {
    public init(json: JSON){
        if let _ = json.array {
            self.init(isBatch: true, items: JSONRPCV2.Request.multipleValidate(json))
        } else {
            self.init(isBatch: false, items: [JSONRPCV2.Request.singleValidate(json)])
        }
    }
    
    static func multipleValidate(_ json: JSON) -> [JSONRPCV2.RequestItem] {
        if let array = json.array {
            return array.flatMap { multipleValidate($0) }
        } else {
            return [singleValidate(json)]
        }
    }
    
    static func singleValidate(_ json: JSON) -> JSONRPCV2.RequestItem {
        var id: JSONRPCV2.ID?
        if let _id = json["id"].string {
            id = .string(_id)
        }
        else if let _id = json["id"].int {
            id = .number(_id)
        }
        
        guard let versionString = json["jsonrpc"].string else {
            return JSONRPCV2.RequestItem(id: id, error: .invalidRequest)
        }
        
        if versionString != "2.0" {
            return JSONRPCV2.RequestItem(id: id, error: .invalidRequest)
        }
        
        guard let method = json["method"].string else {
            return JSONRPCV2.RequestItem(id: id, error: .invalidRequest)
        }
        
        return JSONRPCV2.RequestItem(id: id, method: method, params: json["params"].exists() ?  json["params"] : nil)
    }
}
