*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${RIZENI_CISLO}     V-6922/2021-211


*** Test Cases ***
KN Proxy - Listiny
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Listiny
    Vyplnit Stringové Pole    Číslo řízení    ${RIZENI_CISLO}
    Kliknout Na Tlačítko S Textem    Hledat
    Ověřit Výsledky V Tabulce    Návrh na vklad
    Stáhnout Soubor Z Listiny    vystup_lv_${RIZENI_CISLO}.pdf
