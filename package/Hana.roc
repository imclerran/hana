module [
    statusResponse,
    textResponse,
    jsonResponse,
    pathSegments,
    htmlResponse,
    prependHeader,
    ok,
    badRequest,
    notFound,
    requireMethod,
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
prependHeader : Response, { name : Str, value : Str } -> Response
prependHeader = \response, header ->
    headers = List.prepend response.headers header
    { response & headers }

## Middleware that ensures the request has a specific HTTP method.
##
## Returns an empty response with status code 405: Method not allowed
## if the method is not correct.
requireMethod : Response, _, _ -> Response
requireMethod = \next, req, method ->
    if (req.method == method) then
        next
    else
        statusResponse 405

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

expect
    actual =
        statusResponse 200
        |> prependHeader { name: "Content-Type", value: "text/html; charset=utf-8" }
        |> prependHeader { name: "X-Roc-Package", value: "hana" }

    expected = {
        status: 200,
        headers: [
            { name: "X-Roc-Package", value: "hana" },
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ],
        body: [],
    }
    actual == expected
