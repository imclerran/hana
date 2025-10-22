module [
    status_response,
    text_response,
    json_response,
    path_segments,
    html_response,
    prepend_response_header,
    prepend_request_header,
    set_method,
    ok,
    bad_request,
    not_found,
    method_not_allowed,
    require_method,
    handle_head,
]

## Internal types based on the basic-webserver implementation.
Response : { status : U16, headers : List Header, body : List U8 }

Request : {
    method : Method,
    headers : List Header,
    uri : Str,
    body : List U8,
    timeout_ms : [TimeoutMilliseconds U64, NoTimeout],
}

Method : [OPTIONS, GET, POST, PUT, DELETE, HEAD, TRACE, CONNECT, PATCH, EXTENSION Str]

Header : {
    name : Str,
    value : Str,
}

## Create a HTTP response with the required status code.
status_response : U16 -> Response
status_response = |status|
    { status, headers: [], body: [] }

## Create a HTTP response with text content.
##
## The `content-type` header will be set to `text/plain`.
text_response : U16, Str -> Response
text_response = |status, body|
    { status, headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }], body: Str.to_utf8(body) }

## Create a HTTP response with JSON content.
##
## The `content-type` header will be set to `application/json`.
json_response : U16, List U8 -> Response
json_response = |status, body|
    { status, headers: [{ name: "Content-Type", value: "application/json; charset=utf-8" }], body: body }

## Create a HTTP response with HTML content.
##
## The `content-type` header will be set to `text/html`.
html_response : U16, List U8 -> Response
html_response = |status, body|
    { status, headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }], body: body }

## Create an empty response with status code 404: Not found.
not_found : Response
not_found = { status: 404, body: [], headers: [] }

## Create an empty response with status code 400: Bad request.
bad_request : Response
bad_request = { status: 400, body: [], headers: [] }

## Create an empty response with status code 200: OK.
ok : Response
ok = { status: 200, body: [], headers: [] }

## Create an empty response with status code 405: Method Not Allowed.
##
## The `allow` header will be set to a comma separated list of the permitted methods.
method_not_allowed : List Method -> Response
method_not_allowed = |allowed|
    methods =
        allowed
        |> List.map method_to_str
        |> Str.join_with ", "

    status_response(405)
    |> prepend_response_header({ name: "allow", value: methods })

## Convert a HTTP Method to an uppercase string.
method_to_str : Method -> Str
method_to_str = |method|
    when method is
        OPTIONS -> "OPTIONS"
        GET -> "GET"
        POST -> "POST"
        PUT -> "PUT"
        DELETE -> "DELETE"
        HEAD -> "HEAD"
        TRACE -> "TRACE"
        CONNECT -> "CONNECT"
        PATCH -> "PATCH"
        EXTENSION extension -> extension

## Get the path segments from the request url.
path_segments : Str -> List Str
path_segments = |url|
    url
    |> Str.split_on("/")
    # This handles trailing slashes so that pattern matching for routing is simpler
    |> List.drop_if(Str.is_empty)

## Prepend to the list of response headers.
##
## No validation is done to check for duplicate headers.
prepend_response_header : Response, Header -> Response
prepend_response_header = |response, header|
    headers = List.prepend(response.headers, header)
    { response & headers }

## Prepend to the list of request headers.
##
## No validation is done to check for duplicate headers.
prepend_request_header : Request, Header -> Request
prepend_request_header = |request, header|
    headers = List.prepend(request.headers, header)
    { request & headers }

## Middleware that ensures the request has a specific HTTP method.
##
## Returns an empty response with status code 405: Method not allowed
## if the method is not correct.
require_method : Response, Request, Method -> Response
require_method = |next, req, method|
    if (req.method == method) then
        next
    else
        method_not_allowed([method])

## Set the method of the request.
##
set_method : Request, Method -> Request
set_method = |request, method|
    { request & method }

## Middleware that converts `HEAD` requests to `GET` requests.
##
## The `X-Original-Method` header is set to `"HEAD"` for requests that were
## originally `HEAD` requests.
handle_head : Request -> Request
handle_head = |request|
    when request.method is
        HEAD ->
            request
            |> set_method(GET)
            |> prepend_request_header({ name: "X-Original-Method", value: "HEAD" })

        _ -> request

# Tests

# Response tests
expect
    actual = status_response(200)
    expected = { status: 200, headers: [], body: [] }
    actual == expected

expect
    actual = text_response(200, "Hello World!")
    expected = { status: 200, headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }], body: Str.to_utf8("Hello World!") }
    actual == expected

expect
    actual = json_response(200, Str.to_utf8("{\"message\": \"Hello from Hana!\"}"))
    expected = { status: 200, headers: [{ name: "Content-Type", value: "application/json; charset=utf-8" }], body: Str.to_utf8("{\"message\": \"Hello from Hana!\"}") }
    actual == expected

expect
    actual = html_response(200, Str.to_utf8("<h1>Hello from Hana!</h1>"))
    expected = { status: 200, headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }], body: Str.to_utf8("<h1>Hello from Hana!</h1>") }
    actual == expected

expect
    actual = not_found
    expected = { status: 404, headers: [], body: [] }
    actual == expected

expect
    actual = bad_request
    expected = { status: 400, headers: [], body: [] }
    actual == expected

expect
    actual = ok
    expected = { status: 200, headers: [], body: [] }
    actual == expected

# pathSegments tests
expect
    actual = path_segments("/")
    expected = []
    actual == expected

expect
    actual = path_segments("/test")
    expected = ["test"]
    actual == expected

expect
    actual = path_segments("/test/")
    expected = ["test"]
    actual == expected

expect
    actual = path_segments("/test//")
    expected = ["test"]
    actual == expected
expect
    actual = path_segments("/test/1")
    expected = ["test", "1"]
    actual == expected

# prepend headers tests
expect
    actual =
        status_response(200)
        |> prepend_response_header({ name: "Content-Type", value: "text/html; charset=utf-8" })
        |> prepend_response_header({ name: "X-Roc-Package", value: "hana" })

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
            method: GET,
            headers: [{ name: "Content-Type", value: "text/plain; charset=utf-8" }],
            uri: "",
            body: [],
            timeout_ms: NoTimeout,
        }
        |> prepend_request_header({ name: "X-Roc-Package", value: "hana" })

    expected = {
        method: GET,
        headers: [
            { name: "X-Roc-Package", value: "hana" },
            { name: "Content-Type", value: "text/plain; charset=utf-8" },
        ],
        uri: "",
        body: [],
        timeout_ms: NoTimeout,
    }
    actual == expected

# setMethod tests
expect
    actual =
        {
            method: HEAD,
            headers: [],
            uri: "",
            body: [],
            timeout_ms: NoTimeout,
        }
        |> set_method(GET)

    expected = {
        method: GET,
        headers: [],
        uri: "",
        body: [],
        timeout_ms: NoTimeout,
    }
    actual == expected

# handleHead tests
expect
    actual =
        {
            method: HEAD,
            headers: [],
            uri: "",
            body: [],
            timeout_ms: NoTimeout,
        }
        |> handle_head

    expected = {
        method: GET,
        headers: [
            { name: "X-Original-Method", value: "HEAD" },
        ],
        uri: "",
        body: [],
        timeout_ms: NoTimeout,
    }
    actual == expected
