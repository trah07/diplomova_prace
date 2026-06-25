*** Settings ***
Documentation       TS-KN-02 - Vyhledání a stažení LV podle nemovitosti.

Resource           ../../Resources/Common.resource
Library             Browser
Library             OperatingSystem

Suite Setup         Vytvořit testovací prostředí
Test Setup          New Context    httpCredentials={'username': '$user', 'password': '$pwd'}
...                     ignoreHTTPSErrors=True
...                     acceptDownloads=True
Test Teardown       Close Context


*** Variables ***
${URL}                      https://knproxy-prs.csint.cz/knproxy/
${TYP_NEMOVITOSTI}          Pozemek
${KATASTRALNI_UZEMI}        Líšeň    # Kód území je pro automatizaci stabilnější
${KATASTRALNI_UZEMI_KOD}    [612405]
${KMENOVE_CISLO}            702
${DOWNLOAD_PATH}            ${CURDIR}${/}downloads


*** Test Cases ***
TS-KN-02 - Vyhledání a stažení LV podle nemovitosti
    [Documentation]    Ověření funkčnosti vyhledání a následného stažení Listu vlastnictví (LV) skrze specifikaci konkrétní nemovitosti.
    Given uživatel je na úvodní stránce aplikace na adrese "${URL}"
    And jsou k dispozici platné identifikační údaje nemovitosti
    When uživatel klikne na záložku "Vyhledávání LV"
    And zvolí podzáložku "podle nemovitosti"
    And vybere "${TYP_NEMOVITOSTI}" z číselníku
    And vyplní pole "Katastrální území" s hodnotou "${KATASTRALNI_UZEMI}"
    And vyplní pole "Kmenové číslo" s hodnotou "${KMENOVE_CISLO}"
    And klikne na tlačítko pro vyhledání a stažení LV
    Then aplikace zobrazí potvrzení o nalezení a zpracování výsledku
    And dojde k úspěšnému stažení souboru s LV do lokálního zařízení


*** Keywords ***
Vytvořit testovací prostředí
    New Browser    browser=chromium    headless=False
    Empty Directory    ${DOWNLOAD_PATH}
    Create Directory    ${DOWNLOAD_PATH}

uživatel je na úvodní stránce aplikace na adrese "${url}"
    New Page    ${url}
    Fill Text    input[type="email"]    ${user_email}
    Click With Options    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"
    # Čekání na načtení hlavní stránky
    Wait For Elements State    text="Vyhledávání LV"    visible    timeout=10s

jsou k dispozici platné identifikační údaje nemovitosti
    Should Not Be Empty    ${TYP_NEMOVITOSTI}
    Should Not Be Empty    ${KATASTRALNI_UZEMI}

uživatel klikne na záložku "${tab_name}"
    # Hledáme odkaz nebo tlačítko v menu
    Click    xpath=//a[contains(., '${tab_name}')]

zvolí podzáložku "${sub_tab}"
    Click With Options
    ...    xpath=//button[contains(., '${sub_tab}')] | //a[contains(., '${sub_tab}')]
    ...    clickCount=2
    ...    delay=1s

vybere "${property_type}" z číselníku
    # Selektor pro PrimeNG nebo standardní select
    ${selector}=    Set Variable
    ...    //label[text()="Typ nemovitosti"]/ancestor::*[2]//div[contains(@class,"ui-selectonemenu-trigger")]
    Wait For Elements State    ${selector}    visible
    Click    ${selector}
    Click    li[data-label*="${property_type}"]

vyplní pole "Katastrální území" s hodnotou "${territory}"
    ${input_selector}=    Set Variable    tr:has-text("Katastrální území") input[type="text"]
    Type Text    ${input_selector}    ${territory}
    # Simulace výběru z našeptávače
    Sleep    1s    # Krátká pauza na zpracování našeptávače
    Wait For Elements State    tr[data-item-label*="${territory} ${KATASTRALNI_UZEMI_KOD}"]
    Click    tr[data-item-label*="${territory} ${KATASTRALNI_UZEMI_KOD}"]

vyplní pole "Kmenové číslo" s hodnotou "${number}"
    Fill Text    tr:has-text("Kmenové číslo") input[type="text"]    ${number}

klikne na tlačítko pro vyhledání a stažení LV
    # Příprava na download - musí být PŘED kliknutím
    ${dl_promise}=    Promise To Wait For Download    saveAs=${DOWNLOAD_PATH}/LV_vypis.pdf
    # Kliknutí na tlačítko "Vyhledat" nebo "Stáhnout"
    Click    xpath=//button[contains(., 'Vyhledat') or contains(., 'Stáhnout') or contains(., 'Generovat')]
    Click With Options    xpath=//button[contains(., 'Zobrazit LV')] >> nth=0    clickCount=2
    ${file_obj}=    Wait For    ${dl_promise}
    Set Suite Variable    ${DOWNLOADED_FILE}    ${file_obj.saveAs}

aplikace zobrazí potvrzení o nalezení a zpracování výsledku
    # Kontrola, že se neobjevila chyba a aplikace hlásí úspěch
    Wait For Elements State
    ...    xpath=//*[contains(@class, 'error') or contains(text(), 'Chyba')]
    ...    hidden
    ...    timeout=3s

dojde k úspěšnému stažení souboru s LV do lokálního zařízení
    File Should Exist    ${DOWNLOADED_FILE}
    ${size}=    Get File Size    ${DOWNLOADED_FILE}
    Should Be True    ${size} > 1000    msg=Soubor je příliš malý, pravděpodobně není validní.
