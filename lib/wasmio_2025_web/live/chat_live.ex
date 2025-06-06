defmodule Wasmio2025Web.ChatLive do
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
    {:ok, socket |> assign(:messages, [])}
  end

  def handle_event("add_message", %{"message" => message}, socket) do
    Phoenix.PubSub.broadcast(Wasmio2025.PubSub, "chat", message)
    {:noreply, socket}
  end

  def handle_info(message, socket) do
    {:noreply, socket |> assign(:messages, [message | socket.assigns.messages])}
  end
end
