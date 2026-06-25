*** Settings ***
Library    Browser    timeout=30s

*** Variables ***
${URL}    https://knproxy-prs.csint.cz/knproxy/
${KATASTRALNI_UZEMI}    731285
${CISLO_LV}    100
${BROWSER}    chromium
${HEADLESS}    ${True}

*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla
    [Documentation]    Ověření procesu vyhledání a stažení LV podle čísla v aplikaci KN Proxy.
    [Setup]    Inicializace prohlížeče a aplikace
    Given Uživatel je na úvodní stránce aplikace
    When Uživatel otevře záložku Vyhledávání LV a zvolí podzáložku podle čísla LV
    And Uživatel vyplní povinná pole Katastrální území a Číslo LV platnými údaji
    And Uživatel klikne na tlačítko pro vyhledání a stažení LV
    Then Aplikace úspěšně vyhledá záznam a zahájí stahování souboru LV
    [Teardown]    Close Browser    ALL

*** Keywords ***
Inicializace prohlížeče a aplikace
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context    acceptDownloads=${True}
    New Page    ${URL}

Uživatel je na úvodní stránce aplikace
    Wait For Elements State    body    visible    timeout=10s

Uživatel otevře záložku Vyhledávání LV a zvolí podzáložku podle čísla LV
    Wait For Elements State    text="Vyhledávání LV"    visible
    Click    text="Vyhledávání LV"
    Wait For Elements State    text="Podle čísla LV"    visible
    Click    text="Podle čísla LV"

Uživatel vyplní povinná pole Katastrální území a Číslo LV platnými údaji
    Wait For Elements State    id=katastralniUzemi    visible
    Fill Text    id=katastralniUzemi    ${KATASTRALNI_UZEMI}
    Wait For Elements State    id=cisloLv    visible
    Fill Text    id=cisloLv    ${CISLO_LV}

Uživatel klikne na tlačítko pro vyhledání a stažení LV
    Wait For Elements State    id=search-button    enabled
    Click    id=search-button

Aplikace úspěšně vyhledá záznam a zahájí stahování souboru LV
    Wait For Elements State    id=download-button    visible    timeout=15s
    ${dl_promise}=    Promise To Wait For Download
    Click    id=download-button
    ${file_info}=    Wait For    ${dl_promise}
    Should Not Be Empty    ${file_info}[saveAs]