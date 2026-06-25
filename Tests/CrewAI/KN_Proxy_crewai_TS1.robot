*** Settings ***
Library             Browser
Resource           ../../Resources/Common.resource

Suite Setup         Open Application
Suite Teardown      Close Browser


*** Variables ***
${URL}          https://knproxy-prs.csint.cz/knproxy/
${USERNAME}     ${user}
${PASSWORD}     ${pwd}
${KU_VALUE}     Adamov
${LV_VALUE}     115
${BROWSER}      chromium
${HEADLESS}     True


*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla a katastrálního území
    Given Uživatel je přihlášen do aplikace KN Proxy
    And Uživatel se nachází na záložce Vyhledávání LV
    When Uživatel zvolí vyhledávání podle čísla LV
    And Uživatel vyplní pole Katastrální území a Číslo LV platnými údaji
    And Uživatel klikne na tlačítko Stáhnout LV
    Then Aplikace úspěšně zpracuje požadavek a zobrazí výsledek stažení LV


*** Keywords ***
Open Application
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    ...    httpCredentials={'username': '$USERNAME', 'password': '$PASSWORD'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    New Page    ${URL}
    Wait For Load State    networkidle
    Set Browser Timeout    30s
    Fill Text    input[type="email"]    ${user_email}
    Click    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"
    Wait For Elements State    text="Vyhledávání LV"

Uživatel je přihlášen do aplikace KN Proxy
    Wait For Elements State    css=span.user    visible    timeout=10s
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=15s

Uživatel se nachází na záložce Vyhledávání LV
    Click    text="Vyhledávání LV"
    Wait For Elements State    css=a:has-text("podle čísla LV")    visible    timeout=10s

Uživatel zvolí vyhledávání podle čísla LV
    Click    css=a:has-text("podle čísla LV")

Uživatel vyplní pole Katastrální území a Číslo LV platnými údaji
    Wait For Elements State    css=tr:has-text("Katastrální území") input[type="text"]    attached    timeout=5s
    Type Text    css=tr:has-text("Katastrální území") input[type="text"]    ${KU_VALUE}
    Wait For Elements State    tr[data-item-label*="${KU_VALUE}"] >> nth=0
    Click    tr[data-item-label*="${KU_VALUE}"] >> nth=0
    Fill Text    css=tr:has-text("Číslo LV") input[type="text"]    ${LV_VALUE}

Uživatel klikne na tlačítko Stáhnout LV
    Click    css=button:has-text("Stáhnout LV")

Aplikace úspěšně zpracuje požadavek a zobrazí výsledek stažení LV
    ${dl_promise}    Promise To Wait For Download    saveAs=${OUTPUT_DIR}/vystup_lv.pdf    download_timeout=30s
    Click    css=button span:has-text("Zobrazit LV") >> nth=0
    Set Suite Variable    ${DL_PROMISE}    ${dl_promise}
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}    Wait For    ${DL_PROMISE}
    Log    Soubor byl úspěšně stažen do: ${file_obj.saveAs}
