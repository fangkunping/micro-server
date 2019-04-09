use Mix.Config

# Configure your database
  config :micro_server, MicroServer.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "micro_server",
  hostname: "localhost",
  pool_size: 10
