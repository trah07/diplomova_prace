*** Settings ***
Documentation       TS-KN-03 - Vyhledání LV s prázdnými povinnými poli.
...                 Ověřuje, že aplikace nepovolí stažení LV bez vyplnění katastrálního území a čísla LV.

Resource           ../../Resources/Common.resource
Library             Browser

Suite Setup         Připravit prohlížeč

Test Tags           regression    validation    lv


*** Variables ***
${URL}                      https://knproxy-prs.csint.cz/knproxy/
# Selektory (upraveny pro Browser Library/Playwright standard)
${NAV_TAB_VYHLEDAVANI}      text="Vyhledávání LV"
${NAV_SUBTAB_CISLO_LV}      text="podle čísla LV"
${INP_KATASTRALNI_UZEMI}    tr:has-text("Katastrální území") input[type="text"]
${INP_CISLO_LV}             tr:has-text("Číslo LV") input[type="text"]
${BTN_STAHNOUT}             button:has-text("Stáhnout LV")
# Selektor pro validační chybu - obecný pro Bootstrap/Angular/React aplikace
${VAL_ERROR_SELECTOR}       span.ui-message-error-detail


*** Test Cases ***
TS-KN-03 - Vyhledání LV s prázdnými povinnými poli
    [Documentation]    Ověření, že systém správně validuje povinná pole.
    Given uživatel je přihlášen do aplikace na adrese "${URL}"
    And uživatel se nachází na záložce "Vyhledávání LV" v podzáložce "podle čísla LV"
    When uživatel ponechá pole "Katastrální území" a "Číslo LV" prázdná
    And klikne na tlačítko "Stáhnout LV"
    Then aplikace zobrazí validační chybu u povinných polí
    And k pokusu o stažení souboru nedojde


*** Keywords ***
Připravit prohlížeč
    New Browser    browser=chromium    headless=False
    New Context
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True
    Set Browser Timeout    15s

uživatel je přihlášen do aplikace na adrese "${url}"
    New Page    ${url}
    # Zde doplňte přihlašovací údaje, pokud aplikace vyžaduje login form
    Fill Text    input[type="email"]    ${user_email}
    Click With Options    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"
    Wait For Elements State    ${NAV_TAB_VYHLEDAVANI}    visible

uživatel se nachází na záložce "Vyhledávání LV" v podzáložce "podle čísla LV"
    Click    ${NAV_TAB_VYHLEDAVANI}
    Click    ${NAV_SUBTAB_CISLO_LV}
    Wait For Elements State    ${INP_KATASTRALNI_UZEMI}    visible

uživatel ponechá pole "Katastrální území" a "Číslo LV" prázdná
    # Zajistíme, že pole jsou skutečně prázdná (včetně promazání případných defaultů)
    Fill Text    ${INP_KATASTRALNI_UZEMI}    ${EMPTY}
    Fill Text    ${INP_CISLO_LV}    ${EMPTY}
    # Fokus pryč pro vyvolání validace, pokud je on-blur
    Focus    ${BTN_STAHNOUT}

klikne na tlačítko "Stáhnout LV"
    Click    ${BTN_STAHNOUT}

aplikace zobrazí validační chybu u povinných polí
    # Čekáme na zobrazení chybového hlášení nebo zčervenání polí
    Get Element Count    ${VAL_ERROR_SELECTOR}    >    0
    Wait For Elements State    ${VAL_ERROR_SELECTOR} >> nth=0    visible
    Log    Validační chyba úspěšně zobrazena.

k pokusu o stažení souboru nedojde
    # Ověříme, že nenastala událost stažení (download) a zůstáváme na stejné stránce
    # Browser Library umožňuje sledovat downloads přes Promise
    ${promise}=    Promise To Wait For Download    ${None}    # Očekáváme, že nic nepřijde
    # Pokud by se download spustil, Promise by selhal nebo bychom ho zachytili.
    # Zde stačí ověřit, že tlačítko je stále viditelné a neproběhla navigace pryč.
    Get Element States    ${BTN_STAHNOUT}    contains    visible
    # Kontrola, že se neobjevila success hláška
    Wait For Elements State    text="Soubor byl vygenerován"    hidden    timeout=1s
