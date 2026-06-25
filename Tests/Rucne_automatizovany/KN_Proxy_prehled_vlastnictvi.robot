*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${CLUID}    1999-01-25-20.05.26.621621


*** Test Cases ***
KN Proxy - Přehled vlastnictví
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Přehled vlastnictví
    Kliknout Na Tlačítko S Textem    Další možnosti hledání...
    Vyplnit Stringové Pole    Hledání přes CLUID    ${CLUID}
    Kliknout Na Tlačítko S Textem    Hledat
    Ověřit Výsledky Z Fieldsetu    Jméno    Zemanová Jaroslava
    Stáhnout Soubor Z Přehled Vlastnictví    vystup_lv_${CLUID}.pdf
