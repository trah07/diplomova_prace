*** Settings ***
Library    Browser    timeout=00:00:30

*** Variables ***
${URL}               https://knproxy-prs.csint.cz/knproxy/
${KU_CODE}           731285
${LV_ID}             123
${SELECTOR_KU}       input[name="katastralniUzemi"]
${SELECTOR_LV}       input[name="cisloLV"]
${SELECTOR_SUBMIT}   button#vyhledat-stahnout

*** Test Cases ***
Úspěšné vyhledání a stažení LV podle čísla
    [Setup]    Otevřít prohlížeč a aplikaci
    Given Uživatel přejde do sekce Vyhledávání LV podle čísla
    When Uživatel zadá katastrální území "${KU_CODE}" a číslo LV "${LV_ID}"
    Then Systém zahájí stahování a potvrdí úspěšné vyhledání
    [Teardown]    Close Browser

*** Keywords ***
Otevřít prohlížeč a aplikaci
    New Browser    browser=chromium    headless=True
    New Context    acceptDownloads=True
    New Page       ${URL}

Uživatel přejde do sekce Vyhledávání LV podle čísla
    Wait For Elements State    text="Vyhledávání LV"    visible
    Click    text="Vyhledávání LV"
    Wait For Elements State    text="podle čísla LV"    visible
    Click    text="podle čísla LV"

Uživatel zadá katastrální území "${ku}" a číslo LV "${lv}"
    Wait For Elements State    ${SELECTOR_KU}    visible
    Fill Text    ${SELECTOR_KU}    ${ku}
    Fill Text    ${SELECTOR_LV}    ${lv}

Systém zahájí stahování a potvrdí úspěšné vyhledání
    ${dl_promise}=    Promise To Wait For Download
    Click    ${SELECTOR_SUBMIT}
    ${file_info}=    Wait For    ${dl_promise}
    Wait For Elements State    text="Vyhledávání proběhlo úspěšně"    visible    timeout=15s