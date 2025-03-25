defmodule Wasmio2025.ChatServer do
  use Wasmex.Components.ComponentServer,
    wit: "wasm/chat-room.wit",
    imports: %{
      "publish-message" => {:fn, &publish_message/1}
    },
    wasi: %Wasmex.Wasi.WasiP2Options{allow_http: true}


  def publish_message(message) do
    Phoenix.PubSub.broadcast(Wasmio2025.PubSub, "chat", message)
    {:ok, "#{message} published"}
  end
end
