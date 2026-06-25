*** Settings ***
Library             Browser
Resource            ../../kn-proxy-prs/Resources/Prihlaseni.resource

Test Teardown       Close Browser    ALL


*** Variables ***
${BASE_URL}     https://knproxy-prs.csint.cz/knproxy/
${KU_NAME}      Adamov
${KU_VALUE}     [600041]

${LV_NUMBER}    115


*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla LV a katastrálního území
    [Documentation]    Ověření stažení LV po zadání platného katastrálního území a čísla LV.
    Given Uživatel je přihlášen do aplikace KN Proxy
    When Uživatel otevře záložku Vyhledávání LV
    And Zvolí vyhledávání podle čísla LV
    And Vyplní pole Katastrální území a Číslo LV platnými údaji
    And Klikne na tlačítko Stáhnout LV
    Then Aplikace úspěšně zpracuje požadavek a zobrazí výsledek stažení LV


*** Keywords ***
Uživatel je přihlášen do aplikace KN Proxy
    New Browser    browser=chromium    headless=True
    New Context
    ...    viewport={'width': 1920, 'height': 1080}
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    New Page    ${BASE_URL}
    Fill Text    input[type="email"]    ${user_email}
    Click    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]    visible    timeout=15s
    Click    text="Active Directory"
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=20s

Uživatel otevře záložku Vyhledávání LV
    Click    h1, h2:has-text("Vyhledávání LV")
    Wait For Elements State    h1, h2:has-text("Vyhledávání LV")    visible    timeout=10s

Zvolí vyhledávání podle čísla LV
    Click    a:has-text("podle čísla LV")
    Wait For Elements State    label:has-text("Katastrální území")    visible    timeout=5s

Vyplní pole Katastrální území a Číslo LV platnými údaji
    Type Text    tr:has-text("Katastrální území") input[type="text"]    ${KU_NAME}
    Click    tr[data-item-label*="${KU_NAME} ${KU_VALUE}"]
    Fill Text    tr:has-text("Číslo LV") input[type="text"]    ${LV_NUMBER}

Klikne na tlačítko Stáhnout LV
    Wait For Elements State    button:has-text("Stáhnout LV")    enabled
    Click    button:has-text("Stáhnout LV")

Aplikace úspěšně zpracuje požadavek a zobrazí výsledek stažení LV
    ${dl_promise}    Promise To Wait For Download    saveAs=${OUTPUT_DIR}/vystup_lv.pdf    download_timeout=30s
    Click With Options    button span:has-text("Zobrazit LV") >> nth=0    clickCount=2
    Set Suite Variable    ${DL_PROMISE}    ${dl_promise}
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}    Wait For    ${DL_PROMISE}
    Log    Soubor byl úspěšně stažen do: ${file_obj.saveAs}
