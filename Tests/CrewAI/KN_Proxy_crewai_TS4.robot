*** Settings ***
Library    Browser

*** Variables ***
${URL}             https://knproxy-prs.csint.cz/knproxy/
${KAT_UZEMI}       Praha
${CISLO_LV}        123

*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla
    Given Uživatel otevře aplikaci na adrese "${URL}"
    And Uživatel přejde do sekce Vyhledávání LV podle čísla
    When Uživatel vyplní katastrální území "${KAT_UZEMI}" a číslo LV "${CISLO_LV}"
    And Uživatel potvrdí vyhledání a stažení
    Then Výsledek vyhledávání musí být viditelný
    And Soubor s LV musí být úspěšně stažen

*** Keywords ***
Uživatel otevře aplikaci na adrese "${url}"
    New Browser    browser=chromium    headless=False
    New Context    acceptDownloads=True
    New Page       ${url}
    Wait For Elements State    body    visible

Uživatel přejde do sekce Vyhledávání LV podle čísla
    Wait For Elements State    text="Vyhledávání LV"    visible
    Click    text="Vyhledávání LV"
    Wait For Elements State    text="podle čísla LV"    visible
    Click    text="podle čísla LV"

Uživatel vyplní katastrální území "${uzemi}" a číslo LV "${lv}"
    Wait For Elements State    input[name="katastralniUzemi"]    visible
    Fill Text    input[name="katastralniUzemi"]    ${uzemi}
    Fill Text    input[name="cisloLV"]             ${lv}

Uživatel potvrdí vyhledání a stažení
    Wait For Elements State    button#search-and-download    enabled
    Click    button#search-and-download

Výsledek vyhledávání musí být viditelný
    Wait For Elements State    text="Výsledek vyhledávání"    visible    timeout=15s

Soubor s LV musí být úspěšně stažen
    Wait For Elements State    button#download    visible
    ${dl_promise}=    Promise To Wait For Download
    Click    button#download
    ${file_info}=     Wait For    ${dl_promise}