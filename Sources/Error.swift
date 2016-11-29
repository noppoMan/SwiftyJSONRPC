//
//  Error.swift
//  SwiftyJSONRPC
//
//  Created by Yuki Takei on 2016/11/30.
//
//

public enum JSONRPCV2Error: Error {
    case parseError
    case invalidRequest
    case methodNotFound
    case invalidParams
    case internalError
    case serverError
}

extension JSONRPCV2Error {
    
    public var message: String {
        switch self {
        case .parseError:
            return "Parse Error"
        case .invalidRequest:
            return "Invalid Request"
        case .methodNotFound:
            return "Method Not Found"
        case .invalidParams:
            return "Invalid Params"
        case .internalError:
            return "Internal error"
        case .serverError:
            return "Server error"
        }
    }
    
    public var code: Int {
        switch self {
        case .parseError:
            return -32700
        case .invalidRequest:
            return -32600
        case .methodNotFound:
            return -32601
        case .invalidParams:
            return -32602
        case .internalError:
            return -32603
        case .serverError:
            return -32000
        }
    }
    
    public init?(value: Int) {
        switch value {
        case JSONRPCV2Error.parseError.code:
            self = .parseError
        case JSONRPCV2Error.invalidRequest.code:
            self = .invalidRequest
        case JSONRPCV2Error.methodNotFound.code:
            self = .methodNotFound
        case JSONRPCV2Error.invalidParams.code:
            self = .invalidParams
        case JSONRPCV2Error.internalError.code:
            self = .internalError
        default:
            if (-32099)...(-32000) ~= value {
                self = .serverError
            }
            return nil
        }
    }
}
