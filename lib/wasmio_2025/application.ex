defmodule Wasmio2025.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Wasmio2025Web.Telemetry,
      Wasmio2025.Repo,
      {DNSCluster, query: Application.get_env(:wasmio_2025, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wasmio2025.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Wasmio2025.Finch},
      # Start a worker by calling: Wasmio2025.Worker.start_link(arg)
      # {Wasmio2025.Worker, arg},
      {Wasmio2025.Stack, "1,2,3"},
      {Wasmex.Components,
       name: Wasmio2025.ChatRoom,
       path: "wasm/chat-room.wasm",
       imports: %{
         "publish-message" =>
           {:fn,
            fn message ->
              Phoenix.PubSub.broadcast(Wasmio2025.PubSub, "chat", message)
              {:ok, "#{message} published"}
            end}
       },
       wasi: %Wasmex.Wasi.WasiP2Options{allow_http: true}},
      # Start to serve requests, typically the last entry
      Wasmio2025Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wasmio2025.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Wasmio2025Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
