defmodule Wasmio2025.Stack do
  use GenServer

  # Callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :stack)
  end

  def push(element) do
    GenServer.cast(:stack, {:push, element})
  end

  def pop() do
    GenServer.call(:stack, :pop)
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call(:pop, _from, state) do
    [to_caller | new_state] = state
    {:reply, to_caller, new_state}
  end

  def handle_cast({:push, element}, state) do
    new_state = [element | state]
    {:noreply, new_state}
  end

end
