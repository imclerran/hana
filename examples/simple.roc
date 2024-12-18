app [Model, server] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import hana.Hana

Model : {}

server = { init: Task.ok {}, respond }

respond : Request, Model -> Task Response [ServerErr Str]_
respond = \_req, _ ->
    Task.ok (Hana.statusResponse 200)
