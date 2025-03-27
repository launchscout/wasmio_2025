---
marp: true
style: |

  section h1 {
    color: #6042BC;
  }

  section code {
    background-color: #e0e0ff;
  }

  footer {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 100px;
  }

  footer img {
    position: absolute;
    width: 120px;
    right: 20px;
    top: 0;

  }
  section #title-slide-logo {
    margin-left: -60px;
  }
---

# Supervising your WASM Components with wasmex
Chris Nelson
@superchris.launchscout.com (BlueSky)
github.com/superchris
![h:200](/images/full-color.png#title-slide-logo)

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
- Very mature
  - Started by Ericsson in the 80s
- OTP = Open Telecom Platforms
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

# wasmex and the component model
- component model support added in 0.10
- low level API
- "bindgenish" macro for idiomatic Elixir support
- supports:
  - all of the wasm types mapped to Elixir types
  - interfaces
  - imports implemented in Elixir
    - async message passing behind a sync veneer
- resources still TBD

---

# WIT type mappings

<table>
  <tr>
    <th>WIT</th>
    <th>Elixir</th>
  </tr>
  <tr>
    <td>String, UXX, SXX, FloatXX, bool, List</td>
    <td>direct equivalent in Elixir</td>
  </tr>
  <tr>
    <td>Record</td>
    <td>map (structs TBD)</td>
  </tr>
  <tr>
    <td>Variant</td>
    <td>{:atom, value}</td>
  </tr>
  <tr>
    <td>Result</td>
    <td>{:ok, value} or {:error, value}</td>
  </tr>
  <tr>
    <td>Flags</td>
    <td>map of booleans</td>
  </tr>
  <tr>
    <td>Enum</td>
    <td>atom</td>
  </tr>
  <tr>
    <td>Option</td>
    <td>value or nil</td>
  </tr>
</table>

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

export function addMessage(message) {
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
# Creating our ChatServer
```elixir
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
```
---
# Supervising our chat server
```elixir
defmodule Wasmio2025.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ...
      {Wasmio2025.ChatServer,
       name: Wasmio2025.ChatRoom,
       path: "wasm/chat-room.wasm",
       wasi: %Wasmex.Wasi.WasiP2Options{allow_http: true}},
    ]

    opts = [strategy: :one_for_one, name: Wasmio2025.Supervisor]
    Supervisor.start_link(children, opts)
  end
```
---

# Using ChatServer from LiveView
```elixir
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
```

---

# [Let's try it!!](/wasmex-chat)

---

# Let's break it!

---

# Wasmex future
- Implement resources
- Get people using it!
- **Extending SAAS platforms with wasm components**
- Polyglot LiveView (or similar)

---

# Thank You!

Questions?

---