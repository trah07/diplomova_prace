*** Settings ***
Library         Browser
Resource           ../../Resources/Common.resource

Suite Setup     Open Application And Login
# Test Timeout    2 minutes


*** Variables ***
${URL}              https://knproxy-prs.csint.cz/knproxy/

# Testovací data
${KU_VALUE}         Adamov
${KU_NUM_VALUE}     [600041]
${LV_VALUE}         115


*** Test Cases ***
TS-KN-01: Úspěšné vyhledání a stažení LV podle čísla a k.ú.
    [Documentation]    Ověření, že uživatel může úspěšně vyhledat a stáhnout LV.
    [Tags]    happyflow    lv_search
    Given Uživatel se nachází na hlavní stránce aplikace
    When Uživatel přejde na záložku "Vyhledávání LV"
    And Zvolí metodu vyhledávání "podle čísla LV"
    And Vyplní platné "Katastrální území" "${KU_VALUE}" a "Číslo LV" "${LV_VALUE}"
    And Spustí akci stahování LV
    Then Systém úspěšně zahájí a dokončí stahování souboru


*** Keywords ***
Open Application And Login
    # Otevření prohlížeče (Chromium je nejstabilnější pro Playwright)
    New Browser    browser=chromium    headless=False
    New Context
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True

    New Page    ${URL}

    # --- Přihlašovací proces dle zadání ---
    Fill Text    input[type="email"]    ${user_email}
    Click With Options    input[type="submit"]

    # Čekání na openingMessage a výběr AD
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"

    # Ověření, že jsme se dostali do aplikace (hledáme unikátní prvek menu)
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=20s

Uživatel se nachází na hlavní stránce aplikace
    Get Title    contains    KN Proxy
    # Kontrola existence loga nebo hlavního nadpisu
    Wait For Elements State    # Bylo třeba opravit selektor (původně jen 'nav')
    ...    div.navigation-main-container
    ...    visible

Uživatel přejde na záložku "Vyhledávání LV"
    # Kliknutí na záložku v menu
    Click    text="Vyhledávání LV"
    Wait For Elements State    # Oprava selektoru, původně text="Vyhledávání LV"
    ...    h1, h2:has-text("Vyhledávání LV")
    ...    visible

Zvolí metodu vyhledávání "podle čísla LV"
    # Selektor cílí na radio button nebo tabulku přepínače
    Click    a:has-text("podle čísla LV")

Vyplní platné "Katastrální území" "${ku}" a "Číslo LV" "${lv}"
    # Vyplnění K.Ú. s potvrzením (často bývá našeptávač)
    Type Text    tr:has-text("Katastrální území") input[type="text"]    ${ku}
    Wait For Elements State    tr[data-item-label*="${ku} ${KU_NUM_VALUE}"]
    Click    tr[data-item-label*="${ku} ${KU_NUM_VALUE}"]
    # Vyplnění čísla LV
    Fill Text    tr:has-text("Číslo LV") input[type="text"]    ${lv}
    Keyboard Key    press    Enter

Spustí akci stahování LV
    Click    button:has-text("Stáhnout LV"), input[value="Stáhnout LV"]
    # Příprava na zachycení stahovaného souboru (Promise)
    # Tímto zajistíme, že test počká na dokončení downloadu
    ${dl_promise}    Promise To Wait For Download    saveAs=${OUTPUT_DIR}/vystup_lv.pdf    download_timeout=30s
    Click With Options    button span >> "Zobrazit LV" >> nth=0    clickCount=2
    Set Suite Variable    ${DL_PROMISE}    ${dl_promise}

Systém úspěšně zahájí a dokončí stahování souboru
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}    Wait For    ${DL_PROMISE}
    Log    Soubor byl úspěšně stažen do: ${file_obj.saveAs}
    # Kontrola, že se neobjevila chybová hláška (validace)
    Get Element Count    [class*="error"], [class*="alert-danger"]    ==    0
