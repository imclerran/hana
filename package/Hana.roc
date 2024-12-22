module [
    statusResponse,
    textResponse,
    jsonResponse,
    pathSegments,
    htmlResponse,
]

## Internal type based on the basic-webserver implementation.
Response : { status : U16, headers : List { name : Str, value : Str }, body : List U8 }

## Create a HTTP response with the required status code.
statusResponse : U16 -> Response
statusResponse = \status ->
    { status, headers: [], body: [] }

## Create a HTTP response with text content.
##
## The `content-type` header will be set to `text/plain`.
textResponse : U16, Str -> Response
textResponse = \status, body ->
    { status, headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }], body: Str.toUtf8 body }

## Create a HTTP response with JSON content.
##
## The `content-type` header will be set to `application/json`.
jsonResponse : U16, List U8 -> Response
jsonResponse = \status, body ->
    { status, headers: [{ name: "Content-Type", value: "application/json; charset=utf-8" }], body: body }

## Create a HTTP response with HTML content.
##
## The `content-type` header will be set to `text/html`.
htmlResponse : U16, List U8 -> Response
htmlResponse = \status, body ->
    { status, headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }], body: body }

## Get the path segments from the request url.
pathSegments : Str -> List Str
pathSegments = \url ->
    url
    |> Str.splitOn "/"
    # This handles trailing slashes so that pattern matching for routing is simpler
    |> List.dropIf Str.isEmpty

# Tests
expect
    actual = statusResponse 200
    expected = { status: 200, headers: [], body: [] }
    actual == expected

expect
    actual = textResponse 200 "Hello World!"
    expected = { status: 200, headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }], body: Str.toUtf8 "Hello World!" }
    actual == expected

expect
    actual = jsonResponse 200 (Str.toUtf8 "{\"message\": \"Hello from Hana!\"}")
    expected = { status: 200, headers: [{ name: "Content-Type", value: "application/json; charset=utf-8" }], body: Str.toUtf8 "{\"message\": \"Hello from Hana!\"}" }
    actual == expected

expect
    actual = htmlResponse 200 (Str.toUtf8 "<h1>Hello from Hana!</h1>")
    expected = { status: 200, headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }], body: Str.toUtf8 "<h1>Hello from Hana!</h1>" }
    actual == expected

expect
    actual = pathSegments "/"
    expected = []
    actual == expected

expect
    actual = pathSegments "/test"
    expected = ["test"]
    actual == expected

expect
    actual = pathSegments "/test/"
    expected = ["test"]
    actual == expected

expect
    actual = pathSegments "/test//"
    expected = ["test"]
    actual == expected
expect
    actual = pathSegments "/test/1"
    expected = ["test", "1"]
    actual == expected
