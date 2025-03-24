---
marp: true
---

# Supervise Anything!

---

# Intro

---

# Agenda
- Elixir
- Erlang and OTP
- Wasmex
- Demo time!
- Future thoughts

---

# Elixir
- Functional language for the BEAM VM (Erlang)
- All datastructures are immutable
- Dynamically typed
  - gradual type system in-progress
- Friendly, Ruby inspired syntax
- Created by Jose Valim 

---

# What's so great about the BEAM?
- Very mature (started in the 80s)
- OTP = Open Telecom Platform
- Designed for telecommunications
  - highly concurrent
  - highly available

---

# Processes on the BEAM

- Extremely lightweight (< 2KB per process)
- Isolated memory (no shared state)
- Only communicate via message passing
- Can create millions of processes on a single machine
- **Concurrency without locks!**

---

# Supervising Processes

- Processes are organized in hierarchical **supervision trees**
- **Supervisors** monitor **workers** (and other supervisors)
- When a worker crashes, the supervisor can:
  - Restart it
  - Restart all its children
  - Escalate to its own supervisor
  - Shut everything down
- **Let It Crash**

---

# Phoenix LiveView
- Sub-project of Phoenix
- Server rendered app that quacks like a SPA
- Tiny processes maintain state for *every connected client*
- state updates pushed over a websocket connection
- Only works because of OTP
- Proven to scale to millions of connections per server

---

# LiveView [chat](/chat)
```elixir
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
```

---

# Chat continued..
```elixir
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
```

---

# LiveView chat demo

---

# wasmex
- elixir meets wasmtime
- started by Philip Tessenow in 2022
- uses rustler, the rust elixir bridge
- embraces the OTP model
  - runs WASM in separate, supervised processes
  - communicate via message passing

---

# wasmex status
- component model support added in 0.10
- supports:
  - all of the wasm types mapped to Elixir types
  - interfaces
  - imports implemented in Elixir
    - async message passing behind a sync veneer
- resources still TBD

---

# Let's make a chatserver wasm component!

---

# Our wit
```wit
package local:chat-room;

world chat-room {
  import publish-message: func(message: string) -> result<string, string>;
  export init: func() -> list<string>;
  export add-message: func(message: string) -> result<string, string>;
  export message-added: func(message: string, state: list<string>) -> list<string>;
}
```

---

# chat-room.js

```js
import publishMessage from 'publish-message';

const secretWord = 'WAT';

export function addMessage(message) {
  if (message === secretWord) {
    throw new Error('You said the secret word aaaaaa!!!');
  }
  publishMessage(message);
  publishMessage("And here is a message from a wasm component!!");
}

export function init() {
  return ["You joined the wasm component chat!"];
}

export function messageAdded(message, messages) {
  return [...messages, message];
}
```

---
# Supervising our chat room component
```elixir
defmodule Wasmio2025.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ...
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
    ]

    opts = [strategy: :one_for_one, name: Wasmio2025.Supervisor]
    Supervisor.start_link(children, opts)
  end
```
---

# wasmex chat
```elixir
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
```

---

# [Let's try it!!](/wasmex-chat)

---

# Wasmex future
- Implement resources
- Get people using it!
- **Extending SAAS platforms with wasm components**

---

# Thank You!

Questions?

---