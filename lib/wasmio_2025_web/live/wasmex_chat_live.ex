defmodule Wasmio2025Web.WasmexChatLive do
alias Phoenix.PubSub
  use Wasmio2025Web, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <h1>Chat</h1>
      <ul>
        <li :for={message <- @messages}>
          {message}
        </li>
      </ul>
      <form phx-submit="add_message">
        <input type="text" name="message" />
        <button type="submit">Add</button>
      </form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    PubSub.subscribe(Wasmio2025.PubSub, "chat")
    {:ok, state} = Wasmex.Components.call_function(Wasmio2025.ChatRoom, "init", [])
    {:ok, socket |> assign(:messages, state)}
  end

  def handle_event("add_message", %{"message" => message}, socket) do
    {:ok, _result} = Wasmex.Components.call_function(Wasmio2025.ChatRoom, "add-message", [message])
    {:noreply, socket}
  end

  def handle_info(message, socket) do
    {:ok, messages} = Wasmex.Components.call_function(Wasmio2025.ChatRoom, "message-added", [message, socket.assigns.messages])
    {:noreply, socket |> assign(:messages, messages)}
  end
end
