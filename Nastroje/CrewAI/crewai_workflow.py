import os
from crewai import Agent, LLM

# -------------------------------------------------
# Vypnutí CrewAI telemetry
# -------------------------------------------------
os.environ["CREWAI_DISABLE_TELEMETRY"] = "true"
os.environ["OTEL_SDK_DISABLED"] = "true"
os.environ["CREWAI_DISABLE_TRACKING"] = "true"

from crewai import Agent, LLM


# -------------------------------------------------
# Konfigurace jazykového modelu
# -------------------------------------------------
# Před spuštěním je potřeba mít nastavený API klíč:
# export GOOGLE_API_KEY="tvuj_api_klic"
#
# Případně můžeš odkomentovat tento řádek a vložit API klíč přímo:
# os.environ["GOOGLE_API_KEY"] = "tvuj_api_klic"

llm = LLM(
    model="gemini/gemini-3-flash-preview",
    temperature=0.2
)


# -------------------------------------------------
# Pomocná funkce pro extrakci čistého textu z výstupu CrewAI
# -------------------------------------------------
def extract_text(output) -> str:
    """
    Funkce se snaží vrátit pouze čistý textový výstup agenta.
    CrewAI může vracet objekt s atributem raw, string nebo jiný typ objektu.
    """
    if output is None:
        return ""

    if isinstance(output, str):
        return output.strip()

    if hasattr(output, "raw"):
        return str(output.raw).strip()

    return str(output).strip()


# -------------------------------------------------
# Pomocná funkce pro spuštění konkrétního agenta
# -------------------------------------------------
def run_agent(agent: Agent, prompt: str) -> str:
    result = agent.kickoff(prompt)
    return extract_text(result)


# -------------------------------------------------
# Obecná funkce pro lidskou kontrolu výstupu
# -------------------------------------------------
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


# -------------------------------------------------
# Definice agentů CrewAI
# -------------------------------------------------
agent_gherkin = Agent(
    role="Agent_Gherkin",
    goal="Převést vstupní testovací scénář do jednoho happy flow Gherkin scénáře.",
    backstory=(
        "Jsi agent specializovaný na tvorbu testovacích scénářů v Gherkin syntaxi. "
        "Umíš převést textové zadání na jasný, testovatelný a stručný scénář."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)

agent_gherkin_to_robot = Agent(
    role="Agent_GherkinToRobot",
    goal="Převést schválený Gherkin scénář do návrhu Robot Framework Browser testu.",
    backstory=(
        "Jsi agent specializovaný na převod Gherkin scénářů do Robot Framework testů. "
        "Tvoříš první technický návrh testu bez hluboké optimalizace."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)

agent_robot_framework = Agent(
    role="Agent_RobotFramework",
    goal="Zrevidovat a zlepšit Robot Framework Browser test z hlediska syntaxe, stability a spustitelnosti.",
    backstory=(
        "Jsi technický reviewer Robot Framework testů. Zaměřuješ se na syntaxi, stabilitu selektorů, "
        "čekání na prvky, čitelnost, udržovatelnost a praktickou spustitelnost testu."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)

agent_github_actions = Agent(
    role="Agent_GitHub_Actions",
    goal="Vytvořit GitHub Actions YAML workflow pro spuštění Robot Framework testů v CI/CD.",
    backstory=(
        "Jsi agent specializovaný na CI/CD konfiguraci. Připravuješ GitHub Actions workflow "
        "pro instalaci závislostí, inicializaci Robot Framework Browser a spuštění testů."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)

agent_coverage = Agent(
    role="Agent_Coverage",
    goal="Analyzovat pokrytí požadavků na základě vstupního scénáře, Gherkin scénáře a Robot Framework testů.",
    backstory=(
        "Jsi Coverage analytik. Kontroluješ, zda vytvořené testovací artefakty pokrývají požadavky "
        "ze vstupního scénáře. Nečekáš na uživatelskou validaci a pouze vracíš analýzu pokrytí."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)

agent_reporter = Agent(
    role="Agent_Reporter",
    goal="Vytvořit stručný finální report shrnující průběh a výstupy workflow.",
    backstory=(
        "Jsi agent specializovaný na tvorbu technických shrnutí v akademickém, ale srozumitelném stylu. "
        "Shrnuješ vstup, výstupy agentů, validaci a celkový účel workflow."
    ),
    llm=llm,
    verbose=True,
    allow_delegation=False
)


# -------------------------------------------------
# Funkce pro jednotlivé kroky workflow
# -------------------------------------------------
def generate_gherkin(scenario_input: str, previous_output: str = "", feedback: str = "") -> str:
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
{scenario_input}

Previous Gherkin output:
{previous_output}

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
{scenario_input}
"""

    return run_agent(agent_gherkin, prompt)


def generate_robot_draft(gherkin_output: str, previous_output: str = "", feedback: str = "") -> str:
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
{gherkin_output}

Previous Robot Framework draft:
{previous_output}

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
{gherkin_output}
"""

    return run_agent(agent_gherkin_to_robot, prompt)


def review_robot_test(robot_output: str, previous_output: str = "", feedback: str = "") -> str:
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
{robot_output}

Previous reviewed Robot Framework test:
{previous_output}

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
{robot_output}
"""

    return run_agent(agent_robot_framework, prompt)


def generate_github_actions(reviewed_robot_output: str, previous_output: str = "", feedback: str = "") -> str:
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
{reviewed_robot_output}

Previous GitHub Actions workflow:
{previous_output}

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
{reviewed_robot_output}
"""

    return run_agent(agent_github_actions, prompt)


def analyze_coverage(
    scenario_input: str,
    gherkin_output: str,
    robot_output: str,
    reviewed_robot_output: str
) -> str:
    prompt = f"""
You are Agent_Coverage.

You are a coverage analyst.

Your task is to analyze whether the generated test artifacts cover the requirements from the original test scenario.

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
{scenario_input}

Generated Gherkin:
{gherkin_output}

Generated Robot Framework draft:
{robot_output}

Reviewed Robot Framework test:
{reviewed_robot_output}
"""

    return run_agent(agent_coverage, prompt)


def generate_report(
    scenario_input: str,
    gherkin_output: str,
    robot_output: str,
    reviewed_robot_output: str,
    github_actions_output: str,
    coverage_output: str,
    previous_output: str = "",
    feedback: str = ""
) -> str:
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
{scenario_input}

Generated Gherkin:
{gherkin_output}

Generated Robot Framework draft:
{robot_output}

Reviewed Robot Framework test:
{reviewed_robot_output}

GitHub Actions workflow:
{github_actions_output}

Coverage analysis:
{coverage_output}

Previous report:
{previous_output}

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
{scenario_input}

Generated Gherkin:
{gherkin_output}

Generated Robot Framework draft:
{robot_output}

Reviewed Robot Framework test:
{reviewed_robot_output}

GitHub Actions workflow:
{github_actions_output}

Coverage analysis:
{coverage_output}
"""

    return run_agent(agent_reporter, prompt)


# -------------------------------------------------
# Pevně zadaný vstup stejný jako v AutoGen Studiu
# -------------------------------------------------
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


# -------------------------------------------------
# Vygenerování textové vizualizace workflow jako Mermaid diagram
# -------------------------------------------------
mermaid_code = """flowchart TD
    START([START]) --> Agent_Gherkin[Agent_Gherkin]
    Agent_Gherkin --> Human_Gherkin{Human validation\nOK / NEOK / KONEC}
    Human_Gherkin -->|OK| Agent_GherkinToRobot[Agent_GherkinToRobot]
    Human_Gherkin -->|NEOK| Agent_Gherkin
    Human_Gherkin -->|KONEC| END([END])

    Agent_GherkinToRobot --> Human_Robot{Human validation\nOK / NEOK / KONEC}
    Human_Robot -->|OK| Agent_RobotFramework[Agent_RobotFramework]
    Human_Robot -->|NEOK| Agent_GherkinToRobot
    Human_Robot -->|KONEC| END

    Agent_RobotFramework --> Human_ReviewedRobot{Human validation\nOK / NEOK / KONEC}
    Human_ReviewedRobot -->|OK| Agent_GitHub_Actions[Agent_GitHub_Actions]
    Human_ReviewedRobot -->|NEOK| Agent_RobotFramework
    Human_ReviewedRobot -->|KONEC| END

    Agent_GitHub_Actions --> Human_GitHub{Human validation\nOK / NEOK / KONEC}
    Human_GitHub -->|OK| Agent_Coverage[Agent_Coverage]
    Human_GitHub -->|NEOK| Agent_GitHub_Actions
    Human_GitHub -->|KONEC| END

    Agent_Coverage --> Agent_Reporter[Agent_Reporter]
    Agent_Reporter --> Human_Report{Human validation\nOK / NEOK / KONEC}
    Human_Report -->|OK| END
    Human_Report -->|NEOK| Agent_Reporter
    Human_Report -->|KONEC| END
"""

with open("crewai_workflow_graph.mmd", "w", encoding="utf-8") as file:
    file.write(mermaid_code)

print("Mermaid diagram workflow byl uložen do souboru: crewai_workflow_graph.mmd")


# -------------------------------------------------
# Spuštění CrewAI workflow
# -------------------------------------------------
workflow_status = "RUNNING"

gherkin_output = ""
gherkin_feedback = ""

while workflow_status == "RUNNING":
    gherkin_output = generate_gherkin(
        scenario_input=scenario_input,
        previous_output=gherkin_output,
        feedback=gherkin_feedback
    )

    validation_result, gherkin_feedback, workflow_status = human_review(
        "Vygenerovaný Gherkin scénář",
        gherkin_output
    )

    if validation_result == "OK":
        break

if workflow_status == "RUNNING":
    robot_output = ""
    robot_feedback = ""

    while workflow_status == "RUNNING":
        robot_output = generate_robot_draft(
            gherkin_output=gherkin_output,
            previous_output=robot_output,
            feedback=robot_feedback
        )

        validation_result, robot_feedback, workflow_status = human_review(
            "Vygenerovaný návrh Robot Framework testu",
            robot_output
        )

        if validation_result == "OK":
            break
else:
    robot_output = ""

if workflow_status == "RUNNING":
    reviewed_robot_output = ""
    reviewed_robot_feedback = ""

    while workflow_status == "RUNNING":
        reviewed_robot_output = review_robot_test(
            robot_output=robot_output,
            previous_output=reviewed_robot_output,
            feedback=reviewed_robot_feedback
        )

        validation_result, reviewed_robot_feedback, workflow_status = human_review(
            "Revidovaný Robot Framework test",
            reviewed_robot_output
        )

        if validation_result == "OK":
            break
else:
    reviewed_robot_output = ""

if workflow_status == "RUNNING":
    github_actions_output = ""
    github_actions_feedback = ""

    while workflow_status == "RUNNING":
        github_actions_output = generate_github_actions(
            reviewed_robot_output=reviewed_robot_output,
            previous_output=github_actions_output,
            feedback=github_actions_feedback
        )

        validation_result, github_actions_feedback, workflow_status = human_review(
            "GitHub Actions workflow",
            github_actions_output
        )

        if validation_result == "OK":
            break
else:
    github_actions_output = ""

if workflow_status == "RUNNING":
    coverage_output = analyze_coverage(
        scenario_input=scenario_input,
        gherkin_output=gherkin_output,
        robot_output=robot_output,
        reviewed_robot_output=reviewed_robot_output
    )
else:
    coverage_output = ""

if workflow_status == "RUNNING":
    report_output = ""
    report_feedback = ""

    while workflow_status == "RUNNING":
        report_output = generate_report(
            scenario_input=scenario_input,
            gherkin_output=gherkin_output,
            robot_output=robot_output,
            reviewed_robot_output=reviewed_robot_output,
            github_actions_output=github_actions_output,
            coverage_output=coverage_output,
            previous_output=report_output,
            feedback=report_feedback
        )

        validation_result, report_feedback, workflow_status = human_review(
            "Finální report",
            report_output
        )

        if validation_result == "OK":
            break
else:
    report_output = ""


# -------------------------------------------------
# Výpis finálních výstupů do konzole
# -------------------------------------------------
print("\n\n" + "=" * 80)
print("FINÁLNÍ VÝSTUPY")
print("=" * 80)

print(f"\nStav workflow: {workflow_status}")

print("\n--- Finální Gherkin scénář ---")
print(gherkin_output)

print("\n--- Finální návrh Robot Framework testu ---")
print(robot_output)

print("\n--- Finální revidovaný Robot Framework test ---")
print(reviewed_robot_output)

print("\n--- Finální GitHub Actions workflow ---")
print(github_actions_output)

print("\n--- Finální analýza pokrytí požadavků ---")
print(coverage_output)

print("\n--- Finální report ---")
print(report_output)


# -------------------------------------------------
# Uložení všech výstupů do textového souboru
# -------------------------------------------------
output_file = "crewai_workflow_outputs.txt"

with open(output_file, "w", encoding="utf-8") as file:
    file.write("=" * 80 + "\n")
    file.write("VÝSTUPY CREWAI WORKFLOW\n")
    file.write("=" * 80 + "\n\n")

    file.write(f"Stav workflow: {workflow_status}\n\n")

    file.write("=" * 80 + "\n")
    file.write("VSTUPNÍ TESTOVACÍ SCÉNÁŘ\n")
    file.write("=" * 80 + "\n")
    file.write(scenario_input)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ GHERKIN SCÉNÁŘ\n")
    file.write("=" * 80 + "\n")
    file.write(gherkin_output)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ NÁVRH ROBOT FRAMEWORK TESTU\n")
    file.write("=" * 80 + "\n")
    file.write(robot_output)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ REVIDOVANÝ ROBOT FRAMEWORK TEST\n")
    file.write("=" * 80 + "\n")
    file.write(reviewed_robot_output)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ GITHUB ACTIONS WORKFLOW\n")
    file.write("=" * 80 + "\n")
    file.write(github_actions_output)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ ANALÝZA POKRYTÍ POŽADAVKŮ\n")
    file.write("=" * 80 + "\n")
    file.write(coverage_output)
    file.write("\n\n")

    file.write("=" * 80 + "\n")
    file.write("FINÁLNÍ REPORT\n")
    file.write("=" * 80 + "\n")
    file.write(report_output)
    file.write("\n\n")

print(f"\nVšechny výstupy byly uloženy do souboru: {output_file}")
