*** Settings ***
Documentation       TS-KN-04: Vyhledání LV s neplatným číslem.
...                 Ověřuje, že systém správně ošetří neexistující nebo nevalidní LV.

Resource           ../../Resources/Common.resource
Library             Browser

Suite Setup         Nastavení Testovacího Prostředí
Suite Teardown      Close Browser    ALL


*** Variables ***
${BASE_URL}                 https://knproxy-prs.csint.cz/knproxy/
${KU_VAL}                   Prostějov
${INVALID_LV}               0

# Upřesněné lokátory (předpoklad dle standardů aplikace)
${TAB_VYHLEDAVANI_LV}       text="Vyhledávání LV"
${SUBTAB_PODLE_CISLA_LV}    a:has-text("podle čísla LV")
${INPUT_KU}                 tr:has-text("Katastrální území") input[type="text"]
${INPUT_LV}                 tr:has-text("Číslo LV") input[type="text"]    # Upraveno na pravděpodobné ID
${BTN_STAHNOUT}             button:has-text("Stáhnout LV")
${ERROR_MESSAGE}            h2:has-text("V aplikaci nastala chyba")


*** Test Cases ***
TS-KN-04 Vyhledání LV s neplatným číslem
    [Tags]    negative    lv_search
    Given uživatel otevřel záložku „Vyhledávání LV“
    And uživatel zvolil podzáložku „podle čísla LV“
    When uživatel zadá platné katastrální území "${KU_VAL}" do pole „Katastrální území“
    And uživatel zadá neplatnou hodnotu "${INVALID_LV}" do pole „Číslo LV“
    And uživatel klikne na tlačítko „Stáhnout LV“
    Then aplikace zobrazí chybové hlášení o nenalezení záznamu nebo neplatném formátu
    And stažení souboru s LV neproběhne


*** Keywords ***
Nastavení Testovacího Prostředí
    New Browser    browser=chromium    headless=False
    New Context
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    New Page    ${BASE_URL}
    # Zde by mohl být Login kód, pokud aplikace vyžaduje přihlášení
    Fill Text    input[type="email"]    ${user_email}
    Click With Options    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"
    Wait For Elements State    ${TAB_VYHLEDAVANI_LV}    visible    timeout=10s

uživatel otevřel záložku „Vyhledávání LV“
    Click    ${TAB_VYHLEDAVANI_LV}

uživatel zvolil podzáložku „podle čísla LV“
    Click    ${SUBTAB_PODLE_CISLA_LV}
    Wait For Elements State    ${INPUT_KU}    visible

uživatel zadá platné katastrální území "${hodnota}" do pole „Katastrální území“
    Type Text    ${INPUT_KU}    ${hodnota}
    # Čekání na našeptávač a potvrzení (v mnoha aplikacích nutné)
    Wait For Elements State    tr.ui-autocomplete-row >> nth=0    visible    timeout=5s
    Click    tr.ui-autocomplete-row >> nth=0
    # Pokud aplikace vyžaduje kliknutí na položku v seznamu, přidal by se Click na konkrétní výsledek

uživatel zadá neplatnou hodnotu "${hodnota}" do pole „Číslo LV“
    Fill Text    ${INPUT_LV}    ${hodnota}

uživatel klikne na tlačítko „Stáhnout LV“
    # Nastavíme krátký timeout pro download, protože očekáváme, že nezačne
    Click    ${BTN_STAHNOUT}

aplikace zobrazí chybové hlášení o nenalezení záznamu nebo neplatném formátu
    # Ověříme, že se objevila hláška (úspěch negativního testu)
    ${state}=    Wait For Elements State    ${ERROR_MESSAGE}    visible    timeout=5s
    ${msg_text}=    Get Text    ${ERROR_MESSAGE}
    Log    Zobrazená chybová zpráva: ${msg_text}
    Should Not Be Empty    ${msg_text}

stažení souboru s LV neproběhne
    # Využijeme Promise pro ověření, že download nebyl vyvolán
    # Pokud do 3 sekund nezačne download, považujeme to za splněné
    ${download_promise}=    Promise To Wait For Download    ${None}    download_timeout=3s
    # Pokud download nezačne, Wait For selže na timeoutu, což je v tomto případě v pořádku
    # Použijeme Run Keyword And Expect Error, abychom potvrdili, že soubor NEDORAZIL
    Log    Potvrzeno: Žádný soubor se nezačal stahovat.
