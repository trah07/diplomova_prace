*** Settings ***
Library     Browser    timeout=00:00:30
Resource    ../../kn-proxy-prs/Resources/Prihlaseni.resource


*** Variables ***
${URL}          https://knproxy-prs.csint.cz/knproxy/
${BROWSER}      chromium
${HEADLESS}     False


*** Test Cases ***
Úspěšné vyhledání a stažení LV podle nemovitosti
    [Setup]    Uživatel je na stránce aplikace KN Proxy
    Given Uživatel otevře záložku Vyhledávání LV a zvolí podzáložku podle nemovitosti
    When Uživatel vyplní povinná pole Typ nemovitosti, Katastrální území a Kmenové číslo platnými údaji
    And Uživatel spustí vyhledání a stažení LV
    Then Aplikace zobrazí výsledek odpovídající zadané nemovitosti
    And Soubor s LV je úspěšně stažen
    [Teardown]    Close Browser


*** Keywords ***
Uživatel je na stránce aplikace KN Proxy
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    New Page    ${URL}
    Fill Text    input[type="email"]    ${user_email}
    Click    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]    visible    timeout=15s
    Click    text="Active Directory"

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
    Click    li[data-label*="Pozemek"]
    Wait For Elements State    tr:has-text("Katastrální území") input[type="text"]    visible
    Type Text    tr:has-text("Katastrální území") input[type="text"]    Líšeň
    Click    tr[data-item-label*="Líšeň [612405]"]
    Fill Text    tr:has-text("Kmenové číslo") input[type="text"]    702

Uživatel spustí vyhledání a stažení LV
    Wait For Elements State    button:has-text("Stáhnout LV")    enabled
    Click    button:has-text("Stáhnout LV")

Aplikace zobrazí výsledek odpovídající zadané nemovitosti
    Wait For Elements State    text=Historie    visible    timeout=15s

Soubor s LV je úspěšně stažen
    Wait For Elements State    button span:has-text("Zobrazit LV") >> nth=0    visible
    ${dl_promise}=    Promise To Wait For Download    saveAs=${OUTPUT_DIR}/vypis_lv.pdf
    Click With Options    button span:has-text("Zobrazit LV") >> nth=0    clickCount=2
    Wait For    ${dl_promise}
