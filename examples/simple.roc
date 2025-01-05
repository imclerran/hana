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
respond! = \_req, _ ->
    Ok (Hana.status_response 200)
