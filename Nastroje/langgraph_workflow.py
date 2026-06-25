import os
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langchain_google_genai import ChatGoogleGenerativeAI

# Konfigurace jazykového modelu

# Před spuštěním je potřeba mít nastavený API klíč:
# export GOOGLE_API_KEY="tvuj_api_klic"
#
# Případně můžeš odkomentovat tento řádek a vložit API klíč přímo:
# os.environ["GOOGLE_API_KEY"] = "tvuj_api_klic"

llm = ChatGoogleGenerativeAI(
    model="gemini-3-flash-preview",
    temperature=0.2
)

# Pomocná funkce pro extrakci čistého textu

def extract_text(response) -> str:
    """
    Funkce extrahuje pouze viditelný text z odpovědi jazykového modelu.
    Tím se odstraní metadata typu extras, signature nebo podobné interní údaje.
    """
    content = response.content

    if isinstance(content, str):
        return content.strip()

    if isinstance(content, list):
        texts = []

        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    texts.append(item.get("text", ""))
                elif "text" in item:
                    texts.append(item.get("text", ""))
            elif isinstance(item, str):
                texts.append(item)

        return "\n".join(texts).strip()

    return str(content).strip()


def invoke_llm(prompt: str) -> str:
    response = llm.invoke(prompt)
    return extract_text(response)

# Sdílený stav workflow

class TestWorkflowState(TypedDict):
    scenario_input: str
    workflow_status: str

    gherkin_output: str
    gherkin_validation_result: str
    gherkin_validation_feedback: str

    robot_output: str
    robot_validation_result: str
    robot_validation_feedback: str

    reviewed_robot_output: str
    reviewed_robot_validation_result: str
    reviewed_robot_validation_feedback: str

    github_actions_output: str
    github_actions_validation_result: str
    github_actions_validation_feedback: str

    coverage_output: str

    report_output: str
    report_validation_result: str
    report_validation_feedback: str

# Obecná funkce pro lidskou kontrolu výstupu

def human_review(output_title: str, output_content: str):
    print("\n" + "=" * 80)
    print(output_title)
    print("=" * 80)
    print(output_content)
    print("=" * 80)

    feedback = input("\nZadej OK / NEOK / KONEC: ").strip().upper()

    if feedback == "OK":
        return "OK", "", "RUNNING"

    if feedback == "KONEC":
        print("\nWorkflow bylo ukončeno uživatelským vstupem: KONEC")
        return "KONEC", "", "TERMINATED"

    feedback_detail = input("Co má být opraveno? ").strip()

    if feedback_detail.strip().upper() == "KONEC":
        print("\nWorkflow bylo ukončeno uživatelským vstupem: KONEC")
        return "KONEC", "", "TERMINATED"

    return "NEOK", feedback_detail, "RUNNING"

# Agent_Gherkin

def agent_gherkin(state: TestWorkflowState):
    feedback = state.get("gherkin_validation_feedback", "")

    if feedback:
        prompt = f"""
You are Agent_Gherkin.

Your task is to revise the previously generated Gherkin scenario according to the user's feedback.

Create exactly one happy flow Gherkin test scenario for the KN Proxy application.

Rules:
- Create only one scenario.
- Create only a happy flow scenario.
- Do not include negative validation scenarios.
- Focus only on successful search and download of LV.
- Use standard Gherkin keywords: Feature, Scenario, Given, When, Then, And.
- Do not use Markdown formatting.
- Output only the Gherkin scenario.
- The scenario steps may be written in Czech.
- Use clear and testable steps.

User feedback:
{feedback}

Original input:
{state["scenario_input"]}

Previous Gherkin output:
{state["gherkin_output"]}

Generate an improved Gherkin scenario.
"""
    else:
        prompt = f"""
You are Agent_Gherkin.

Your task is to create exactly one happy flow Gherkin test scenario for the KN Proxy application.

Rules:
- Create only one scenario.
- Create only a happy flow scenario.
- Do not include negative validation scenarios.
- Focus only on successful search and download of LV.
- Use standard Gherkin keywords: Feature, Scenario, Given, When, Then, And.
- Do not use Markdown formatting.
- Output only the Gherkin scenario.
- The scenario steps may be written in Czech.
- Use clear and testable steps.

User input:
{state["scenario_input"]}
"""

    return {
        "gherkin_output": invoke_llm(prompt),
        "gherkin_validation_feedback": ""
    }


def human_validation_gherkin(state: TestWorkflowState):
    result, feedback, status = human_review(
        "Vygenerovaný Gherkin scénář",
        state["gherkin_output"]
    )

    return {
        "gherkin_validation_result": result,
        "gherkin_validation_feedback": feedback,
        "workflow_status": status
    }


def decide_after_gherkin_validation(state: TestWorkflowState):
    if state["workflow_status"] == "TERMINATED":
        return "end"

    if state["gherkin_validation_result"] == "OK":
        return "agent_gherkin_to_robot"

    return "agent_gherkin"

# Agent_GherkinToRobot

def agent_gherkin_to_robot(state: TestWorkflowState):
    feedback = state.get("robot_validation_feedback", "")

    if feedback:
        prompt = f"""
You are Agent_GherkinToRobot.

Your task is to revise the Robot Framework draft according to the user's feedback.

Rules:
- Convert the approved Gherkin scenario into Robot Framework syntax.
- Use Robot Framework Browser library where appropriate.
- Do not deeply optimize the test.
- Do not add negative test cases.
- Keep the test focused on the happy flow.
- Output only the Robot Framework code.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.

Approved Gherkin scenario:
{state["gherkin_output"]}

Previous Robot Framework draft:
{state["robot_output"]}

User feedback:
{feedback}

Generate an improved Robot Framework draft.
"""
    else:
        prompt = f"""
You are Agent_GherkinToRobot.

Your task is to convert the approved Gherkin scenario into a Robot Framework test case.

Rules:
- Convert the Gherkin scenario into Robot Framework syntax.
- Use Robot Framework Browser library where appropriate.
- Do not deeply optimize the test.
- Do not add negative test cases.
- Keep the test focused on the happy flow.
- Output only the Robot Framework code.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.

Approved Gherkin scenario:
{state["gherkin_output"]}
"""

    return {
        "robot_output": invoke_llm(prompt),
        "robot_validation_feedback": ""
    }


def human_validation_robot(state: TestWorkflowState):
    result, feedback, status = human_review(
        "Vygenerovaný návrh Robot Framework testu",
        state["robot_output"]
    )

    return {
        "robot_validation_result": result,
        "robot_validation_feedback": feedback,
        "workflow_status": status
    }


def decide_after_robot_validation(state: TestWorkflowState):
    if state["workflow_status"] == "TERMINATED":
        return "end"

    if state["robot_validation_result"] == "OK":
        return "agent_robot_framework"

    return "agent_gherkin_to_robot"

# Agent_RobotFramework

def agent_robot_framework(state: TestWorkflowState):
    feedback = state.get("reviewed_robot_validation_feedback", "")

    if feedback:
        prompt = f"""
You are Agent_RobotFramework.

Your task is to revise the reviewed Robot Framework test according to the user's feedback.

Focus on:
- Robot Framework syntax
- Browser library usage
- selector stability
- waiting strategy
- readability
- maintainability
- executable structure

Rules:
- Keep the test focused on the happy flow.
- Do not add negative test cases.
- Output only the revised Robot Framework code.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.

Original Robot Framework draft:
{state["robot_output"]}

Previous reviewed Robot Framework test:
{state["reviewed_robot_output"]}

User feedback:
{feedback}

Generate an improved reviewed Robot Framework test.
"""
    else:
        prompt = f"""
You are Agent_RobotFramework.

Your task is to review and improve the generated Robot Framework test case.

Focus on:
- Robot Framework syntax
- Browser library usage
- selector stability
- waiting strategy
- readability
- maintainability
- executable structure

Rules:
- Improve the test so that it is more stable and suitable for automated execution.
- Keep the test focused on the happy flow scenario.
- Do not add negative test cases.
- Output only the revised Robot Framework code.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.

Generated Robot Framework test:
{state["robot_output"]}
"""

    return {
        "reviewed_robot_output": invoke_llm(prompt),
        "reviewed_robot_validation_feedback": ""
    }


def human_validation_reviewed_robot(state: TestWorkflowState):
    result, feedback, status = human_review(
        "Revidovaný Robot Framework test",
        state["reviewed_robot_output"]
    )

    return {
        "reviewed_robot_validation_result": result,
        "reviewed_robot_validation_feedback": feedback,
        "workflow_status": status
    }


def decide_after_reviewed_robot_validation(state: TestWorkflowState):
    if state["workflow_status"] == "TERMINATED":
        return "end"

    if state["reviewed_robot_validation_result"] == "OK":
        return "agent_github_actions"

    return "agent_robot_framework"

# Agent_GitHub_Actions

def agent_github_actions(state: TestWorkflowState):
    feedback = state.get("github_actions_validation_feedback", "")

    if feedback:
        prompt = f"""
You are Agent_GitHub_Actions.

Your task is to revise the GitHub Actions YAML workflow according to the user's feedback.

The workflow should include:
- checkout
- Python setup
- dependency installation
- Robot Framework Browser initialization
- Robot Framework test execution
- upload of test results as artifacts

Rules:
- Generate only YAML.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.
- Use a clear and realistic CI/CD structure.
- Assume the tests are stored in a repository.

Approved reviewed Robot Framework test:
{state["reviewed_robot_output"]}

Previous GitHub Actions workflow:
{state["github_actions_output"]}

User feedback:
{feedback}

Generate an improved GitHub Actions YAML workflow.
"""
    else:
        prompt = f"""
You are Agent_GitHub_Actions.

Your task is to generate a GitHub Actions YAML workflow for running the approved Robot Framework test.

The workflow should include:
- checkout
- Python setup
- dependency installation
- Robot Framework Browser initialization
- Robot Framework test execution
- upload of test results as artifacts

Rules:
- Generate only YAML.
- Do not use Markdown formatting.
- Do not wrap the output in code fences.
- Use a clear and realistic CI/CD structure.
- Assume the tests are stored in a repository.

Approved reviewed Robot Framework test:
{state["reviewed_robot_output"]}
"""

    return {
        "github_actions_output": invoke_llm(prompt),
        "github_actions_validation_feedback": ""
    }


def human_validation_github_actions(state: TestWorkflowState):
    result, feedback, status = human_review(
        "GitHub Actions workflow",
        state["github_actions_output"]
    )

    return {
        "github_actions_validation_result": result,
        "github_actions_validation_feedback": feedback,
        "workflow_status": status
    }


def decide_after_github_actions_validation(state: TestWorkflowState):
    if state["workflow_status"] == "TERMINATED":
        return "end"

    if state["github_actions_validation_result"] == "OK":
        return "agent_coverage"

    return "agent_github_actions"

# Agent_Coverage

def agent_coverage(state: TestWorkflowState):
    prompt = f"""
You are Agent_Coverage.

You are a coverage analyst.

Your task is to analyze whether the generated test artifacts cover the requirements
from the original test scenario.

Analyze coverage based on:
- original input scenario
- generated Gherkin scenario
- generated Robot Framework draft
- reviewed Robot Framework test

Rules:
- Do not ask for user validation.
- Do not wait for user input.
- Return only the coverage analysis.
- Output must be in Czech.
- Use a clear structure.
- Include:
  1. Přehled požadavků
  2. Matice pokrytí požadavků
  3. Zhodnocení pokrytí
  4. Případná rizika nebo mezery v pokrytí
  5. Krátké shrnutí

Original input scenario:
{state["scenario_input"]}

Generated Gherkin:
{state["gherkin_output"]}

Generated Robot Framework draft:
{state["robot_output"]}

Reviewed Robot Framework test:
{state["reviewed_robot_output"]}
"""

    return {
        "coverage_output": invoke_llm(prompt)
    }

# Agent_Reporter

def agent_reporter(state: TestWorkflowState):
    feedback = state.get("report_validation_feedback", "")

    if feedback:
        prompt = f"""
You are Agent_Reporter.

Your task is to revise the final technical summary according to the user's feedback.

Rules:
- Output must be in Czech.
- Use academic but understandable language.
- Keep the report concise.
- Do not use Markdown tables.
- Do not mention internal signatures, hashes, memory addresses or implementation metadata.

Input test scenario:
{state["scenario_input"]}

Generated Gherkin:
{state["gherkin_output"]}

Generated Robot Framework draft:
{state["robot_output"]}

Reviewed Robot Framework test:
{state["reviewed_robot_output"]}

GitHub Actions workflow:
{state["github_actions_output"]}

Coverage analysis:
{state["coverage_output"]}

Previous report:
{state["report_output"]}

User feedback:
{feedback}

Generate an improved final report.
"""
    else:
        prompt = f"""
You are Agent_Reporter.

Your task is to create a short technical summary of the completed test generation workflow.

Summarize:
- the input test scenario
- the generated Gherkin scenario
- the generated Robot Framework draft
- the reviewed Robot Framework test
- the GitHub Actions workflow
- the coverage analysis
- the role of human validation
- the overall purpose of the workflow

Rules:
- Output must be in Czech.
- Use academic but understandable language.
- Keep the report concise.
- Do not use Markdown tables.
- Do not mention internal signatures, hashes, memory addresses or implementation metadata.

Input test scenario:
{state["scenario_input"]}

Generated Gherkin:
{state["gherkin_output"]}

Generated Robot Framework draft:
{state["robot_output"]}

Reviewed Robot Framework test:
{state["reviewed_robot_output"]}

GitHub Actions workflow:
{state["github_actions_output"]}

Coverage analysis:
{state["coverage_output"]}
"""

    return {
        "report_output": invoke_llm(prompt),
        "report_validation_feedback": ""
    }


def human_validation_report(state: TestWorkflowState):
    result, feedback, status = human_review(
        "Finální report",
        state["report_output"]
    )

    return {
        "report_validation_result": result,
        "report_validation_feedback": feedback,
        "workflow_status": status
    }


def decide_after_report_validation(state: TestWorkflowState):
    if state["workflow_status"] == "TERMINATED":
        return "end"

    if state["report_validation_result"] == "OK":
        return "end"

    return "agent_reporter"

# Sestavení LangGraph workflow

graph = StateGraph(TestWorkflowState)

graph.add_node("agent_gherkin", agent_gherkin)
graph.add_node("human_validation_gherkin", human_validation_gherkin)

graph.add_node("agent_gherkin_to_robot", agent_gherkin_to_robot)
graph.add_node("human_validation_robot", human_validation_robot)

graph.add_node("agent_robot_framework", agent_robot_framework)
graph.add_node("human_validation_reviewed_robot", human_validation_reviewed_robot)

graph.add_node("agent_github_actions", agent_github_actions)
graph.add_node("human_validation_github_actions", human_validation_github_actions)

graph.add_node("agent_coverage", agent_coverage)

graph.add_node("agent_reporter", agent_reporter)
graph.add_node("human_validation_report", human_validation_report)

# Nastavení počátečního uzlu workflow

graph.add_edge(START, "agent_gherkin")

# Validace výstupu agenta Agent_Gherkin

graph.add_edge("agent_gherkin", "human_validation_gherkin")

graph.add_conditional_edges(
    "human_validation_gherkin",
    decide_after_gherkin_validation,
    {
        "agent_gherkin": "agent_gherkin",
        "agent_gherkin_to_robot": "agent_gherkin_to_robot",
        "end": END
    }
)

# Validace výstupu agenta Agent_GherkinToRobot

graph.add_edge("agent_gherkin_to_robot", "human_validation_robot")

graph.add_conditional_edges(
    "human_validation_robot",
    decide_after_robot_validation,
    {
        "agent_gherkin_to_robot": "agent_gherkin_to_robot",
        "agent_robot_framework": "agent_robot_framework",
        "end": END
    }
)

# Validace výstupu agenta Agent_RobotFramework

graph.add_edge("agent_robot_framework", "human_validation_reviewed_robot")

graph.add_conditional_edges(
    "human_validation_reviewed_robot",
    decide_after_reviewed_robot_validation,
    {
        "agent_robot_framework": "agent_robot_framework",
        "agent_github_actions": "agent_github_actions",
        "end": END
    }
)

# Validace výstupu agenta Agent_GitHub_Actions

graph.add_edge("agent_github_actions", "human_validation_github_actions")

graph.add_conditional_edges(
    "human_validation_github_actions",
    decide_after_github_actions_validation,
    {
        "agent_github_actions": "agent_github_actions",
        "agent_coverage": "agent_coverage",
        "end": END
    }
)

# Agent_Coverage nečeká na uživatelskou validaci a pokračuje přímo na report

graph.add_edge("agent_coverage", "agent_reporter")

# Validace výstupu agenta Agent_Reporter

graph.add_edge("agent_reporter", "human_validation_report")

graph.add_conditional_edges(
    "human_validation_report",
    decide_after_report_validation,
    {
        "agent_reporter": "agent_reporter",
        "end": END
    }
)

# Kompilace workflow

compiled_graph = graph.compile()

# Vygenerování vizualizace workflow

try:
    graph_png = compiled_graph.get_graph().draw_mermaid_png()

    with open("langgraph_workflow_graph.png", "wb") as file:
        file.write(graph_png)

    print("Graf workflow byl uložen do souboru: langgraph_workflow_graph.png")

except Exception as error:
    print(f"PNG graf se nepodařilo vygenerovat: {error}")

# Uložení Mermaid diagramu workflow

mermaid_code = compiled_graph.get_graph().draw_mermaid()

with open("langgraph_workflow_graph.mmd", "w", encoding="utf-8") as file:
    file.write(mermaid_code)

print("Mermaid diagram workflow byl uložen do souboru: langgraph_workflow_graph.mmd")

# Pevně zadaný vstup stejný jako v AutoGen Studiu

scenario_input = """
TS4 Vyhledání LV s neplatnými hodnotami

Cíl: Ověřit, že aplikace správně reaguje na zadání neplatných vstupních hodnot.

Předpoklady: Uživatel je přihlášen do aplikace.

Postup:
1. Otevřít záložku „Vyhledávání LV" a zvolit podzáložku „podle čísla LV".
2. Vyplnit platné pole „Katastrální území" a pole „Číslo LV" neplatným číslem.
3. Spustit vyhledání a stažení LV.

Očekávaný výsledek: Aplikace zobrazí chybovou hlášku nebo informaci o nenalezení záznamu a stažení neproběhne.

Zadání: Vytvoř mi jeden testovací scénář pro aplikaci kn proxy na stránce https://knproxy-prs.csint.cz/knproxy/.
"""

# Inicializační stav workflow

initial_state = {
    "scenario_input": scenario_input,
    "workflow_status": "RUNNING",

    "gherkin_output": "",
    "gherkin_validation_result": "",
    "gherkin_validation_feedback": "",

    "robot_output": "",
    "robot_validation_result": "",
    "robot_validation_feedback": "",

    "reviewed_robot_output": "",
    "reviewed_robot_validation_result": "",
    "reviewed_robot_validation_feedback": "",

    "github_actions_output": "",
    "github_actions_validation_result": "",
    "github_actions_validation_feedback": "",

    "coverage_output": "",

    "report_output": "",
    "report_validation_result": "",
    "report_validation_feedback": ""
}

# Spuštění workflow

result = compiled_graph.invoke(
    initial_state,
    config={"recursion_limit": 50}
)

# Výpis finálních výstupů do konzole

print("\n\n" + "=" * 80)
print("FINÁLNÍ VÝSTUPY")
print("=" * 80)

print(f"\nStav workflow: {result['workflow_status']}")

print("\n--- Finální Gherkin scénář ---")
print(result["gherkin_output"])

print("\n--- Finální návrh Robot Framework testu ---")
print(result["robot_output"])

print("\n--- Finální revidovaný Robot Framework test ---")
print(result["reviewed_robot_output"])

print("\n--- Finální GitHub Actions workflow ---")
print(result["github_actions_output"])

print("\n--- Finální analýza pokrytí požadavků ---")
print(result["coverage_output"])

print("\n--- Finální report ---")
print(result["report_output"])

# Uložení všech výstupů do textového souboru

output_file = "langgraph_workflow_outputs.txt"

with open(output_file, "w", encoding="utf-8") as file:
    file.write("=" * 80 + "\n")
    file.write("VÝSTUPY LANGGRAPH WORKFLOW\n")
    file.write("=" * 80 + "\n\n")

    file.write(f"Stav workflow: {result['workflow_status']}\n\n")

    file.write("=" * 80 + "\n")
    file.write("VSTUPNÍ TESTOVACÍ SCÉNÁŘ\n")
    file.write("=" * 80 + "\n")
    file.write(result["scenario_input"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ GHERKIN SCÉNÁŘ\n")
    file.write("=" * 80 + "\n")
    file.write(result["gherkin_output"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ NÁVRH ROBOT FRAMEWORK TESTU\n")
    file.write("=" * 80 + "\n")
    file.write(result["robot_output"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ REVIDOVANÝ ROBOT FRAMEWORK TEST\n")
    file.write("=" * 80 + "\n")
    file.write(result["reviewed_robot_output"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ GITHUB ACTIONS WORKFLOW\n")
    file.write("=" * 80 + "\n")
    file.write(result["github_actions_output"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ ANALÝZA POKRYTÍ POŽADAVKŮ\n")
    file.write("=" * 80 + "\n")
    file.write(result["coverage_output"])
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ REPORT\n")
    file.write("=" * 80 + "\n")
    file.write(result["report_output"])
    file.write("\n\n")

print(f"\nVšechny výstupy byly uloženy do souboru: {output_file}")
