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
respond = \_req, _ ->

    # Create a record of data
    data = { message: "Hello World!" }

    # Encode the record as utf-8
    encoded = Encode.toBytes data Json.utf8

    # Return the JSON response with the utf-8 encoded record as the body
    Task.ok (Hana.jsonResponse 200 encoded)
