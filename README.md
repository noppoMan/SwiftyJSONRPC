# SwiftyJSONRPC
A JSON RPC Parser/Serializer For Swift

## Features
- [x] Request Parser/Serializer
- [x] Response Parser/Serializer
- [x] Batch Request/Response


## Package.swift
```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .Package(url: "https://github.com/noppoMan/SwiftyJSONRPC.git", majorVersion: 0, minor: 1),
    ]
)
```

## Usage

## Request

### Single

```swift
import SwiftyJSONRPC

let json: JSON = ["jsonrpc": "2.0", "id": 1, "method": "sum", "params": [1, 1]]
let request = JSONRPCV2.Request(json: json)

print(request.isBatch) // false
print(request.items.first?.id) // 1

print(request.toJSON()) // SwiftyJSON.JSON type
```

### Batch

We supports [batch request](http://www.jsonrpc.org/specification#batch)

```swift
import SwiftyJSONRPC

let json: JSON = [
    ["jsonrpc": "2.0", "id": 1, "method": "mul", "params": [2, 2],
    ["id": 2, "method": "mul", "params": [2, 2],
    ["jsonrpc": "2.0", "id": 3, "method": "div", "params": [4, 2]
]
let request = JSONRPCV2.Request(json: json)

print(request.isBatch) // true
print(request.items[0].id) // 1
print(request.items[1].error) // invalidRequest
print(request.items[2].id) // 3

print(request.toJSON()) // SwiftyJSON.JSON type
```

## Response

```swift
import SwiftyJSONRPC

let response = JSONRPCV2.Response(
    isBatch: true,
    items: [
        JSONRPCV2.ResponseItem(id: .number(1), result: [2, 2]),
        JSONRPCV2.ResponseItem(id: .number(2), error: .invalidRequest),
    ]
)

let json = response.toJSON()
print(json) // SwiftyJSON.JSON type
```

## License
SwiftyJSONRPC is released under the MIT license. See LICENSE for details.
