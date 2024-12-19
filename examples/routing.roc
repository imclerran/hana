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
        when Hana.pathSegments req is
            [""] -> Hana.statusResponse 200
            ["flower"] -> Hana.textResponse 200 "this is the /flower route"
            ["flower", "rose"] -> Hana.textResponse 200 "this is the /flower/rose route"
            ["blossom", ..] -> Hana.textResponse 200 "this is the /blossom/* route"
            _ -> Hana.statusResponse 404

    Task.ok response
