*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${LV_ID}    44378195010


*** Test Cases ***
KN Proxy - Vyhledání a stažení LV podle LV ID
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Vyhledávání LV
    Zvolit Metodu Vyhledávání    podle ID LV
    Vyplnit Stringové Pole    ID LV    ${LV_ID}
    Stáhnout Soubor    vystup_lv_${LV_ID}.pdf
