---
marp: true
---

# Supervise Anything!

---

# Elixir
- Functional language for the BEAM VM (Erlang)
- Friendly, Ruby inspired syntax
- Created by Jose Valim 

---

# What's so great about 
---
# OTP

---

# LiveView

---
# Erlang/OTP: A Brief Introduction

- **Erlang**: Programming language designed for concurrency and reliability
- **OTP (Open Telecom Platform)**: Collection of middleware, libraries, and tools
- Created at Ericsson in the 1980s for telecom systems
- Designed for systems that are:
  - Concurrent
  - Distributed
  - Fault-tolerant
  - Highly available (99.9999% uptime = 31 seconds downtime per year)

---

# Key Concepts in Elixir/OTP

- **Processes**: Lightweight, isolated units of computation
- **Message Passing**: Processes communicate by sending messages
- **Pattern Matching**: Elegant way to process data and messages
- **Functional Programming**: Immutable data, no shared state
- **Distribution**: Built-in support for distributed computing
- **Hot Code Swapping**: Update code without stopping the system

---

# The Process Model

- Processes are the fundamental building blocks
- Extremely lightweight (< 2KB per process)
- Isolated memory (no shared state)
- Can create millions of processes on a single machine
- Each process has its own:
  - Mailbox for messages
  - Stack
  - Heap
  - Process ID (PID)

---

# Example GenServer
```elixir
defmodule Stack do
  use GenServer

  # Callbacks

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call(:pop, _from, state) do
    [to_caller | new_state] = state
    {:reply, to_caller, new_state}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    new_state = [element | state]
    {:noreply, new_state}
  end
end
```

---

# Concurrency Without Locks

---

# OTP Supervision: The Big Idea

- Processes are organized in hierarchical **supervision trees**
- **Supervisors** monitor **workers** (and other supervisors)
- When a worker crashes, the supervisor can:
  - Restart it
  - Restart all its children
  - Escalate to its own supervisor
  - Shut everything down

---

# Let It Crash Philosophy

> "The error handling philosophy of Erlang is different: *Let some processes crash*"

- Don't try to prevent all errors with defensive programming
- Focus on error recovery instead of error prevention
- Embrace failure as a normal part of the system
- Isolate failures to prevent cascading effects
- Recover from failures through restarts

---

# Supervision Strategies

- **one_for_one**: Restart only the failed child
- **one_for_all**: Restart all children if one fails
- **rest_for_one**: Restart the failed child and all children started after it
- **simple_one_for_one**: For dynamic child processes

---

# Example Supervision Tree

---

# Benefits of Supervision

- **Fault Isolation**: Failures are contained
- **Self Healing**: System can recover automatically
- **Predictable Behavior**: Clear strategies for handling failures
- **Simplified Error Handling**: No need for complex try/catch in business logic
- **Design for Failure**: Forces you to think about failure scenarios

---

# Real-World Applications

- **WhatsApp**: Scaled to billions of users with Erlang
- **Discord**: Uses Elixir (built on BEAM/Erlang) for real-time communication
- **RabbitMQ**: Message broker written in Erlang
- **Riak**: Distributed database

---

# Phoenix LiveView
- Huge productivity boost for web apps
- App is all elixir, state updates pushed to client
- Tiny processes maintain state for *every connected client*
- Only works because of OTP
- Proven to scale to millions of connections per server

---

# wasmex
- elixir meets wasmtime
- uses rustler, the rust elixir bridge
- Added support for component model in XXX
- Supports all types except resources
- Supports imported functions from Elixir

---

# What if we put them together?

---

# Thank You!

Questions?

---