app [Model, init!, respond!] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.13.0/fSNqJj3-twTrb0jJKHreMimVWD7mebDOj0mnslMm2GM.tar.br",
    hana: "../package/main.roc",
}

import pf.Http exposing [Request, Response]
import hana.Hana

Model : {}

init! : {} => Result Model []
init! = |{}| Ok({})

respond! : Request, Model => Result Response [ServerErr Str]
respond! = |_req, _|
    Ok(Hana.status_response(200))
