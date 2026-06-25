from langgraph.graph import StateGraph, END
from typing import TypedDict

class State(TypedDict):
    message: str

def hello(state: State) -> State:
    state["message"] = "LangGraph is working!"
    return state

builder = StateGraph(State)
builder.add_node("hello", hello)
builder.set_entry_point("hello")
builder.add_edge("hello", END)

graph = builder.compile()
result = graph.invoke({"message": ""})
print(result["message"])