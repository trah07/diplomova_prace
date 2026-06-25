*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${KU_NAZEV}         Líšeň [612405]
${KMEN_CISLO}       702


*** Test Cases ***
KN Proxy - Vyhledání a stažení LV podle nemovitosti
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Vyhledávání LV
    Zvolit Metodu Vyhledávání    podle nemovitosti
    Vybrat Z Dropdownu    Typ nemovitosti    Pozemek
    Vyplnit Pole S Našeptávačem    Katastrální území    ${KU_NAZEV}
    Vyplnit Stringové Pole    Kmenové číslo    ${KMEN_CISLO}
    Stáhnout Soubor    vystup_lv_${KMEN_CISLO}.pdf
