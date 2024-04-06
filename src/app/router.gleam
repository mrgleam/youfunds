import app/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Post}
import gleam/json
import gleam/pgo
import gleam/result
import wisp.{type Request, type Response}

pub type Fund {
  Fund(symbol: String, amount: Float)
}

fn decode_fund(json: Dynamic) -> Result(Fund, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode2(
      Fund,
      dynamic.field("symbol", dynamic.string),
      dynamic.field("amount", dynamic.float),
    )
  decoder(json)
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  use <- wisp.require_method(req, Post)

  use json <- wisp.require_json(req)

  let result = {
    use fund <- result.try(decode_fund(json))

    let sql =
      "
      insert into transaction
        (symbol, amount) 
      values 
        ($1, $2)
      returning
        id
    "

    let assert Ok(_id) =
      pgo.execute(
        sql,
        ctx.db,
        [pgo.text(fund.symbol), pgo.float(fund.amount)],
        dynamic.element(0, dynamic.int),
      )

    let object =
      json.object([
        #("symbol", json.string(fund.symbol)),
        #("amount", json.float(fund.amount)),
        #("saved", json.bool(True)),
      ])
    Ok(json.to_string_builder(object))
  }

  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(_) -> wisp.unprocessable_entity()
  }
}
