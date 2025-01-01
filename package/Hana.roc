module [
    statusResponse,
    textResponse,
    jsonResponse,
    pathSegments,
    htmlResponse,
    prependResponseHeader,
    prependRequestHeader,
    setMethod,
    ok,
    badRequest,
    notFound,
    requireMethod,
    handleHead,
]

## Internal types based on the basic-webserver implementation.
Response : { status : U16, headers : List Header, body : List U8 }

Request : {
    method : Method,
    headers : List Header,
    url : Str,
    mimeType : Str,
    body : List U8,
    timeout : TimeoutConfig,
}

TimeoutConfig : [TimeoutMilliseconds U64, NoTimeout]

Method : [Options, Get, Post, Put, Delete, Head, Trace, Connect, Patch, Extension Str]

Header : {
    name : Str,
    value : Str,
}

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

## Create an empty response with status code 404: Not found.
notFound : Response
notFound = { status: 404, body: [], headers: [] }

## Create an empty response with status code 400: Bad request.
badRequest : Response
badRequest = { status: 400, body: [], headers: [] }

## Create an empty response with status code 200: OK.
ok : Response
ok = { status: 200, body: [], headers: [] }

## Get the path segments from the request url.
pathSegments : Str -> List Str
pathSegments = \url ->
    url
    |> Str.splitOn "/"
    # This handles trailing slashes so that pattern matching for routing is simpler
    |> List.dropIf Str.isEmpty

## Prepend to the list of response headers.
##
## No validation is done to check for duplicate headers.
prependResponseHeader : Response, Header -> Response
prependResponseHeader = \response, header ->
    headers = List.prepend response.headers header
    { response & headers }

## Prepend to the list of request headers.
##
## No validation is done to check for duplicate headers.
prependRequestHeader : Request, Header -> Request
prependRequestHeader = \request, header ->
    headers = List.prepend request.headers header
    { request & headers }

## Middleware that ensures the request has a specific HTTP method.
##
## Returns an empty response with status code 405: Method not allowed
## if the method is not correct.
requireMethod : Response, Request, Method -> Response
requireMethod = \next, req, method ->
    if (req.method == method) then
        next
    else
        statusResponse 405

## Set the method of the request.
##
setMethod : Request, Method -> Request
setMethod = \request, method ->
    { request & method }

## Middleware that converts `Head` requests to `Get` requests.
##
## The `X-Original-Method` header is set to `"HEAD"` for requests that were
## originally `HEAD` requests.
handleHead : Request -> Request
handleHead = \request ->
    when request.method is
        Head ->
            request
            |> setMethod Get
            |> prependRequestHeader { name: "X-Original-Method", value: "HEAD" }

        _ -> request

# Tests

# Response tests
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
    actual = notFound
    expected = { status: 404, headers: [], body: [] }
    actual == expected

expect
    actual = badRequest
    expected = { status: 400, headers: [], body: [] }
    actual == expected

expect
    actual = ok
    expected = { status: 200, headers: [], body: [] }
    actual == expected

# pathSegments tests
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

# prepend headers tests
expect
    actual =
        statusResponse 200
        |> prependResponseHeader { name: "Content-Type", value: "text/html; charset=utf-8" }
        |> prependResponseHeader { name: "X-Roc-Package", value: "hana" }

    expected = {
        status: 200,
        headers: [
            { name: "X-Roc-Package", value: "hana" },
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ],
        body: [],
    }
    actual == expected

expect
    actual =
        {
            method: Get,
            headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }],
            url: "",
            mimeType: "",
            body: [],
            timeout: NoTimeout,
        }
        |> prependRequestHeader { name: "X-Roc-Package", value: "hana" }

    expected = {
        method: Get,
        headers: [
            { name: "X-Roc-Package", value: "hana" },
            { name: "Content-Type", value: "text/plain; charset=utf-8" },
        ],
        url: "",
        mimeType: "",
        body: [],
        timeout: NoTimeout,
    }
    actual == expected

# setMethod tests
expect
    actual =
        {
            method: Head,
            headers: [],
            url: "",
            mimeType: "",
            body: [],
            timeout: NoTimeout,
        }
        |> setMethod Get

    expected = {
        method: Get,
        headers: [],
        url: "",
        mimeType: "",
        body: [],
        timeout: NoTimeout,
    }
    actual == expected

# handleHead tests
expect
    actual =
        {
            method: Head,
            headers: [],
            url: "",
            mimeType: "",
            body: [],
            timeout: NoTimeout,
        }
        |> handleHead

    expected = {
        method: Get,
        headers: [
            { name: "X-Original-Method", value: "HEAD" },
        ],
        url: "",
        mimeType: "",
        body: [],
        timeout: NoTimeout,
    }
    actual == expected
