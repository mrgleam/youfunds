import gleam/erlang/process
import mist
import wisp
import gleam/pgo
import gleam/option.{Some}
import app/router
import app/web.{Context}

pub fn main() {
  // Start a database connection pool.
  // Typically you will want to create one pool for use in your program
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "youfunds",
        password: Some("mysecretpassword"),
        pool_size: 15,
      ),
    )
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let handle_request = fn(req) {
    let ctx = Context(db: db)
    router.handle_request(req, ctx)
  }

  let assert Ok(_) =
    wisp.mist_handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
