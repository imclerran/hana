app [Model, init!, respond!] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.11.0/yWHkcVUt_WydE1VswxKFmKFM5Tlu9uMn6ctPVYaas7I.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.11.0/z45Wzc-J39TLNweQUoLw3IGZtkQiEN3lTBv3BXErRjQ.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import json.Json
import hana.Hana

Model : {}

init! : {} => Result Model []
init! = \{} -> Ok {}

respond! : Request, Model -> Result Response [ServerErr Str]_
respond! = \req, _ ->

    response =
        when Hana.path_segments req.uri is
            [] -> Hana.status_response 200
            ["json"] -> handle_json req
            _ -> Hana.status_response 404

    Ok response

RequestPayload : { first_name : Str, last_name : Str }

handle_json : Request -> Response
handle_json = \req ->

    if req.method == GET then
        # Create a record of data
        data = { message: "Hello World!" }

        # Encode the record as utf-8
        encoded = Encode.toBytes data Json.utf8

        # Return the JSON response with the utf-8 encoded record as the body
        Hana.json_response 200 encoded
    else if req.method == POST then
        # Decode the request body into the RequestPayload type
        decoded : Decode.DecodeResult RequestPayload
        decoded = Decode.fromBytesPartial req.body Json.utf8

        # Pattern match on the result to return the required response
        when decoded.result is
            Ok record -> Hana.json_response 200 (Str.toUtf8 "{\"full_name\": \"$(record.first_name) $(record.last_name)\"}")
            Err e -> Hana.json_response 401 (Str.toUtf8 "{\"error\": \"failed to decode: $(Inspect.toStr e)\"}")
    else
        Hana.method_not_allowed [GET, POST]
