*** Settings ***
Library     Browser
Library     OperatingSystem
Resource    ../../kn-proxy-prs/Resources/Prihlaseni.resource


*** Variables ***
${URL}                  https://knproxy-prs.csint.cz/knproxy/
${TYP_NEMOVITOSTI}      Pozemek
${KU_NAZEV}             Líšeň
${KU_KOD}               [612405]
${KMEN_CISLO}           702
${BROWSER_TIMEOUT}      30s


*** Test Cases ***
Úspěšné vyhledání a stažení LV podle nemovitosti
    [Setup]    Uživatel je na stránce aplikace KN Proxy
    Given Uživatel otevře záložku Vyhledávání LV a zvolí podzáložku podle nemovitosti
    When Uživatel vyplní povinná pole Typ nemovitosti, Katastrální území a Kmenové číslo platnými údaji
    And Uživatel spustí vyhledání a stažení LV
    Then Aplikace zobrazí výsledek vyhledávání odpovídající zadané nemovitosti
    And Stažený soubor LV je k dispozici v systému
    [Teardown]    Close Browser    ALL


*** Keywords ***
Uživatel je na stránce aplikace KN Proxy
    New Browser    browser=chromium    headless=True
    New Context
    ...    viewport={'width': 1920, 'height': 1080}
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    Set Browser Timeout    ${BROWSER_TIMEOUT}
    New Page    ${URL}
    Fill Text    input[type="email"]    ${user_email}
    Click    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]    visible    timeout=15s
    Click    text="Active Directory"
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=20s

Uživatel otevře záložku Vyhledávání LV a zvolí podzáložku podle nemovitosti
    Wait For Elements State    text="Vyhledávání LV"    visible
    Click    text="Vyhledávání LV"
    Wait For Elements State    text="podle nemovitosti"    visible
    Click With Options    text="podle nemovitosti"    clickCount=2    delay=1s

Uživatel vyplní povinná pole Typ nemovitosti, Katastrální území a Kmenové číslo platnými údaji
    ${selector}=    Set Variable
    ...    //label[text()="Typ nemovitosti"]/ancestor::*[2]//div[contains(@class,"ui-selectonemenu-trigger")]
    Wait For Elements State    ${selector}    visible
    Click    ${selector}
    Wait For Elements State    li[data-label*="${TYP_NEMOVITOSTI}"]    visible
    Click    li[data-label*="${TYP_NEMOVITOSTI}"]
    Wait For Elements State    tr:has-text("Katastrální území") input[type="text"]    visible
    Type Text    tr:has-text("Katastrální území") input[type="text"]    ${KU_NAZEV}
    Wait For Elements State    tr[data-item-label*="${KU_NAZEV} ${KU_KOD}"]    visible
    Click    tr[data-item-label*="${KU_NAZEV} ${KU_KOD}"]
    Fill Text    tr:has-text("Kmenové číslo") input[type="text"]    ${KMEN_CISLO}

Uživatel spustí vyhledání a stažení LV
    Wait For Elements State    button:has-text("Stáhnout LV")    enabled
    Click    button:has-text("Stáhnout LV")

Aplikace zobrazí výsledek vyhledávání odpovídající zadané nemovitosti
    Wait For Elements State    text=Historie    visible    timeout=15s

Stažený soubor LV je k dispozici v systému
    Wait For Elements State    button span:has-text("Zobrazit LV") >> nth=0    visible
    ${dl_promise}=    Promise To Wait For Download    saveAs=${OUTPUT_DIR}/vypis_lv.pdf    download_timeout=30s
    Click With Options    button span:has-text("Zobrazit LV") >> nth=0    clickCount=2
    ${file_info}=    Wait For    ${dl_promise}
    Should Not Be Empty    ${file_info.saveAs}
    File Should Exist    ${file_info.saveAs}
