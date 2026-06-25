*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${KU_NAZEV}     Adamov [600041]
${LV_CISLO}     000


*** Test Cases ***
KN Proxy - Vyhledání a stažení LV podle čísla a katastrálního území
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Vyhledávání LV
    Zvolit Metodu Vyhledávání    podle čísla LV
    Vyplnit Pole S Našeptávačem    Katastrální území    ${KU_NAZEV}
    Vyplnit Stringové Pole    Číslo LV    ${LV_CISLO}
    Nepodaří Se Stáhnout Soubor
