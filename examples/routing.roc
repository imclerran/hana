app [Model, init!, respond!] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.11.0/yWHkcVUt_WydE1VswxKFmKFM5Tlu9uMn6ctPVYaas7I.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import hana.Hana

Model : {}

init! : {} => Result Model []
init! = \{} -> Ok {}

respond! : Request, Model -> Result Response [ServerErr Str]_
respond! = \req, _ ->

    response =
        when Hana.path_segments req.uri is
            # matches "/"
            [] -> Hana.status_response 200
            # matches "/flower"
            ["flower"] -> Hana.text_response 200 "this is the /flower route"
            # matches "/petal" for GET requests only
            ["petal"] -> handler req
            # matches "/flower/rose"
            ["flower", "rose"] -> Hana.text_response 200 "this is the /flower/rose route"
            # matches "/blossom/:colour"
            ["blossom", colour] -> blossomHandler req colour
            # matches all other paths
            _ -> Hana.status_response 404

    Ok response

## Handler for the "/petal" route.
handler = \req ->
    Hana.text_response 200 "this is the /petal route"
    |> Hana.require_method req GET

blossomHandler = \req, colour ->
    when req.method is
        GET -> Hana.text_response 200 "GET /blossom route with colour: $(colour)"
        POST -> Hana.text_response 200 "POST /blossom route with colour: $(colour)"
        _ -> Hana.method_not_allowed [GET, POST]
