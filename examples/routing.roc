app [Model, server] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import hana.Hana

Model : {}

server = { init: Task.ok {}, respond }

respond : Request, Model -> Task Response [ServerErr Str]_
respond = \req, _ ->

    response =
        when Hana.pathSegments req.url is
            # matches "/"
            [] -> Hana.statusResponse 200
            # matches "/flower"
            ["flower"] -> Hana.textResponse 200 "this is the /flower route"
            # matches "/petal" for GET requests only
            ["petal"] -> handler req
            # matches "/flower/rose"
            ["flower", "rose"] -> Hana.textResponse 200 "this is the /flower/rose route"
            # matches "/blossom/:colour"
            ["blossom", colour] -> Hana.textResponse 200 "this is the /blossom route with colour: $(colour)"
            # matches all other paths
            _ -> Hana.statusResponse 404

    Task.ok response

## Handler for the "/petal" route.
handler = \req ->
    Hana.textResponse 200 "this is the /petal route"
    |> Hana.requireMethod req Get
