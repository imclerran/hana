app [Model, server] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.11.0/z45Wzc-J39TLNweQUoLw3IGZtkQiEN3lTBv3BXErRjQ.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import json.Json
import hana.Hana

Model : {}

server = { init: Task.ok {}, respond }

respond : Request, Model -> Task Response [ServerErr Str]_
respond = \req, _ ->

    response =
        when Hana.pathSegments req.url is
            [] -> Hana.statusResponse 200
            ["json"] -> handle_json req
            _ -> Hana.statusResponse 404

    Task.ok response

RequestPayload : { first_name : Str, last_name : Str }

handle_json : Request -> Response
handle_json = \req ->

    if req.method == Get then
        # Create a record of data
        data = { message: "Hello World!" }

        # Encode the record as utf-8
        encoded = Encode.toBytes data Json.utf8

        # Return the JSON response with the utf-8 encoded record as the body
        Hana.jsonResponse 200 encoded
    else if req.method == Post then
        # Decode the request body into the RequestPayload type
        decoded : Decode.DecodeResult RequestPayload
        decoded = Decode.fromBytesPartial req.body Json.utf8

        # Pattern match on the result to return the required response
        when decoded.result is
            Ok record -> Hana.jsonResponse 200 (Str.toUtf8 "{\"full_name\": \"$(record.first_name) $(record.last_name)\"}")
            Err e -> Hana.jsonResponse 401 (Str.toUtf8 "{\"error\": \"failed to decode: $(Inspect.toStr e)\"}")
    else
        Hana.methodNotAllowed [Get, Post]
