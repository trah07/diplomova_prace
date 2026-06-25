*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Resource           ../../Resources/Common.resource

Suite Setup         Nastavit Prohlížeč A Prostředí
Suite Teardown      Close Browser


*** Variables ***
# Testovací data
${OBEC_NAZEV}       Starý Mateřov
${CISLO_BUDOVY}     337


*** Test Cases ***
KN Proxy - Vyhledání a stažení LV podle částečný LV
    [Documentation]    Ověření úspěšného vyhledání a stažení LV při zadání platných údajů.
    [Tags]    happyflow    lv    integration

    Otevřít Aplikaci KN Proxy
    Přejít Do Sekce V Navigaci    Vyhledávání LV
    Zvolit Metodu Vyhledávání    částečný LV
    Kliknout Na Tlačítko S Textem    Přidat nemovitost
    Vybrat Z Dropdownu    Typ nemovitosti    Budova
    Vyplnit Pole S Našeptávačem    Obec    ${OBEC_NAZEV}
    Vybrat Z Dropdownu    Část obce    ${OBEC_NAZEV}
    Vybrat Z Dropdownu    Typ budovy    budova s číslem popisným
    Vyplnit Stringové Pole    Číslo budovy    ${CISLO_BUDOVY}
    Kliknout Na Tlačítko S Textem    Vyhledat
    Zkontroluj Částku Za Stažení    100 Kč
    Stáhnout Soubor    vystup_lv_${CISLO_BUDOVY}.pdf
