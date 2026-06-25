*** Settings ***
Library    Browser

*** Variables ***
${URL}                  https://knproxy-prs.csint.cz/knproxy/
${KATASTRALNI_UZEMI}    Praha
${CISLO_LV}             123
${BROWSER}              chromium
${HEADLESS}             True

*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla
    [Documentation]    Ověřuje, že uživatel může vyhledat LV podle čísla a úspěšně stáhnout výsledný soubor.
    [Setup]    Inicializace prohlížeče a aplikace
    Given Uživatel přejde do sekce vyhledávání podle čísla LV
    When Uživatel zadá katastrální území "${KATASTRALNI_UZEMI}" a číslo LV "${CISLO_LV}"
    Then Aplikace vyhledá záznam a stáhne soubor LV
    [Teardown]    Close Context

*** Keywords ***
Inicializace prohlížeče a aplikace
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context    acceptDownloads=True
    New Page       ${URL}
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=10s

Uživatel přejde do sekce vyhledávání podle čísla LV
    Click    text="Vyhledávání LV"
    Wait For Elements State    text="podle čísla LV"    visible    timeout=5s
    Click    text="podle čísla LV"
    Wait For Elements State    input[name="katastralniUzemi"]    visible    timeout=5s

Uživatel zadá katastrální území "${uzemi}" a číslo LV "${lv}"
    Fill Text    input[name="katastralniUzemi"]    ${uzemi}
    Fill Text    input[name="cisloLV"]             ${lv}

Aplikace vyhledá záznam a stáhne soubor LV
    ${dl_promise}=    Promise To Wait For Download
    Click    button#search-download
    ${file_info}=    Wait For    ${dl_promise}
    Should Not Be Empty    ${file_info.saveAs}
    Should Not Be Empty    ${file_info.suggestedFilename}