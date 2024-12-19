module [
    statusResponse,
    textResponse,
    jsonResponse,
    pathSegments,
]

import pf.Http exposing [Request, Response]
import pf.Url

## HTTP Response with the specified status code.
statusResponse : U16 -> Response
statusResponse = \status ->
    { status, headers: [], body: [] }

## HTTP Response with the specified status code and body.
## "text/plain; charset=utf-8" content type header is added.
textResponse : U16, Str -> Response
textResponse = \status, body ->
    { status, headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }], body: Str.toUtf8 body }

## Create a JSON response.
##
## The `content-type` header will be set to `application/json`.
jsonResponse : U16, List U8 -> Response
jsonResponse = \status, body ->
    { status, headers: [{ name: "Content-Type", value: "application/json; charset=utf-8" }], body: body }

## Get the path segments from the request url.
pathSegments : Request -> List Str
pathSegments = \req ->
    req.url
    |> Url.fromStr
    |> Url.path
    |> Str.splitOn "/"
    # First item is always an empty string so drop it
    |> List.dropFirst 1

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
