defmodule Wasmio2025Web.WasmexChatLive do
alias Phoenix.PubSub
  use Wasmio2025Web, :live_view
  alias Wasmio2025.ChatServer

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
    {:ok, state} = ChatServer.init(Wasmio2025.ChatRoom)
    {:ok, socket |> assign(:messages, state)}
  end

  def handle_event("add_message", %{"message" => message}, socket) do
    {:ok, _message} = ChatServer.add_message(Wasmio2025.ChatRoom, message)
    {:noreply, socket}
  end

  def handle_info(message, %{assigns: %{messages: messages}} = socket) do
    {:ok, messages} = ChatServer.message_added(Wasmio2025.ChatRoom, message, messages)
    {:noreply, socket |> assign(:messages, messages)}
  end
end
