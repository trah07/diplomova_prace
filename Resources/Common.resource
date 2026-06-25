*** Settings ***
Documentation       Automatizovaný test pro vyhledání a stažení Listu vlastnictví (LV) v aplikaci KN Proxy.

Library             Browser
Library             String
Library             OperatingSystem
Resource            ./Prihlaseni.resource


*** Variables ***
${URL}          https://knproxy-prs.csint.cz/knproxy/
${BROWSER}      chromium
${HEADLESS}     False


*** Keywords ***
Nastav Promenne Zavisle Na Systemu
    # Autor: CoE Testing
    [Documentation]  Nastaví hodnoty globálních proměnných:\n\n
    ...  - ``SYSTEM``: na kterém systému se nacházíme (_Windows_, _Linux_, ...)
    ...  - ``SERVER``: zda jsme na serveru ovládaném Jenkinsem (_True_ / _False_)
    ...  - ``KONTEJNER``: zda jsme na kontejneru ovládaném Kubernetes (_True_ / _False_)
    ${SYSTEM}=    Evaluate    platform.system()    platform
    Set Global Variable    ${SYSTEM}
    ${SERVER}=    Set Variable If    "%{NODE_NAME=}"    True    False
    Set Global Variable    ${SERVER}
    ${KONTEJNER}=    Set Variable If    "%{KUBERNETES_PORT=}"    True    False
    Set Global Variable    ${KONTEJNER}
    IF    ${KONTEJNER} and not ${HEADLESS}
        Log    Testy běží na kontejneru, proto proběhnou v režimu headless navzdory nastavení    level=WARN
        Set Global Variable    ${HEADLESS}    True
    END

Nastavit Prohlížeč A Prostředí
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Otevře prohlížeč s nastavenými parametry a připraví prostředí pro testování.
    Nastav Promenne Zavisle Na Systemu
    New Browser    browser=${BROWSER}    headless=${HEADLESS}
    New Context
    ...    httpCredentials={'username': '$user', 'password': '$pwd'}
    ...    ignoreHTTPSErrors=True
    ...    acceptDownloads=True

Otevřít Aplikaci KN Proxy
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Otevře hlavní stránku aplikace KN Proxy a provede přihlašovací proces.
    New Page    ${URL}    wait_until=domcontentloaded
    Wait For Elements State    body    visible
    Fill Text    input[type="email"]    ${user_email}
    Click With Options    input[type="submit"]
    Wait For Elements State    div[id="openingMessage"]
    Click    text="Active Directory"
    Wait For Elements State    text="Vyhledávání LV"

Přejít Do Sekce V Navigaci
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Naviguje do sekce vybrané v hlavním menu aplikace.
    [Arguments]    ${sekce}
    Click    a:has-text("${sekce}")
    Wait For Elements State    a:has-text("${sekce}")

Zvolit Metodu Vyhledávání
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Zvolí metodu vyhledávání v aplikaci.
    [Arguments]    ${metoda}
    Wait For Elements State    a:has-text("${metoda}")
    Click With Options    a:has-text("${metoda}")    clickCount=2    delay=1s
    Wait For Elements State    h2 >> nth=0

Vyplnit Pole S Našeptávačem
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Vyplní zadané pole v aplikaci a vybere odpovídající položku z našeptávače.
    [Arguments]    ${nazev_pole}    ${hodnota}
    ${regex_souhlasi}=    Run Keyword And Return Status
    ...    Should Match Regexp
    ...    ${hodnota}
    ...    ^[A-Za-zÀ-ž ]+ \\[[0-9]{6}\\]$
    IF    ${regex_souhlasi}
        ${nova_hodnota}=    Fetch From Left    ${hodnota}    [
        Type Text    tr:has-text("${nazev_pole}") input[type="text"]    ${nova_hodnota}
    ELSE
        Type Text    tr:has-text("${nazev_pole}") input[type="text"]    ${hodnota}
    END
    Wait For Elements State    tr[data-item-label*="${hodnota}"]
    # Klikneme na první odpovídající prvek v našeptávači
    Click    tr[data-item-label*="${hodnota}"] >> nth=0

Vyplnit Stringové Pole
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Vyplní zadané pole v aplikaci.
    [Arguments]    ${nazev_pole}    ${hodnota}
    Fill Text    tr:has-text("${nazev_pole}") input[type="text"]    ${hodnota}

Stáhnout Soubor
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Spustí proces stahování souboru a ověří jeho úspěšné stažení.
    [Arguments]    ${ocekavany_nazev}
    Click    button:has-text("Stáhnout")
    ${dl_promise}=    Promise To Wait For Download
    ...    saveAs=${OUTPUT_DIR}${/}${ocekavany_nazev}
    ...    download_timeout=30s
    Click With Options    button span:has-text("Zobrazit LV") >> nth=0    clickCount=2
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}=    Wait For    ${dl_promise}
    File Should Exist    ${file_obj.saveAs}
    ${size}=    Get File Size    ${file_obj.saveAs}
    Should Be True
    ...    ${size} > 1024
    ...    Zpráva: Stažený soubor je příliš malý (${size} bytes), pravděpodobně jde o chybu.

Nepodaří Se Stáhnout Soubor
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]   Ověří, že při neúspěšném pokusu o stažení souboru se zobrazí správná chybová zpráva.
    Click    button:has-text("Stáhnout")
    Wait For Elements State    h2:has-text("V aplikaci nastala chyba")
    ${text_obrazovky}=    Get Text    div.content-full-width    contains    chyba
    ${error_zprava}=    Get Element States    div.errorMessage    evaluate    visible in value
    IF    ${error_zprava}
        ${zprava}=    Get Text    div.errorMessage    contains    Detail chyby
        Log    ${zprava}
    ELSE
        Log    ${text_obrazovky}
    END

Stáhnout Soubor Z Kontrolního Řízení
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Spustí proces stahování souboru z kontrolního řízení a ověří jeho úspěšné stažení.
    [Arguments]    ${ocekavany_nazev}
    Click    button:has-text("Stáhnout aktuální verzi z KN")
    Wait For Elements State    div.successMessage
    Zkontroluj Částku Za Stažení    10 Kč
    ${dl_promise}=    Promise To Wait For Download
    ...    saveAs=${OUTPUT_DIR}${/}${ocekavany_nazev}
    ...    download_timeout=60s
    Click With Options    button span:has-text("Zobrazit") >> nth=0    clickCount=2
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}=    Wait For    ${dl_promise}
    File Should Exist    ${file_obj.saveAs}
    ${size}=    Get File Size    ${file_obj.saveAs}
    Should Be True
    ...    ${size} > 1024
    ...    Zpráva: Stažený soubor je příliš malý (${size} bytes), pravděpodobně jde o chybu.

Stáhnout Soubor Z Listiny
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Spustí proces stahování souboru z listiny a ověří jeho úspěšné stažení.
    [Arguments]    ${ocekavany_nazev}
    Kliknout Na Tlačítko S Textem    Stáhnout z KN
    Wait For Elements State    h3:has-text("Identifikace LV")
    Zkontroluj Částku Za Stažení    80 Kč
    Kliknout Na Tlačítko S Textem    Stáhnout listinu za tuto cenu
    Wait For Elements State    div.successMessage
    ${dl_promise}=    Promise To Wait For Download
    ...    saveAs=${OUTPUT_DIR}${/}${ocekavany_nazev}
    ...    download_timeout=60s
    Click With Options    button span:has-text("Zobrazit") >> nth=0    clickCount=2
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}=    Wait For    ${dl_promise}
    File Should Exist    ${file_obj.saveAs}
    ${size}=    Get File Size    ${file_obj.saveAs}
    Should Be True
    ...    ${size} > 1024
    ...    Zpráva: Stažený soubor je příliš malý (${size} bytes), pravděpodobně jde o chybu.

Stáhnout Soubor Z Přehled Vlastnictví
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Spustí proces stahování souboru z přehledu vlastnictví a ověří jeho úspěšné stažení.
    [Arguments]    ${ocekavany_nazev}
    Kliknout Na Tlačítko S Textem    Stáhnout aktuální verzi z KN
    Wait For Elements State    div.successMessage
    ${dl_promise}=    Promise To Wait For Download
    ...    saveAs=${OUTPUT_DIR}${/}${ocekavany_nazev}
    ...    download_timeout=60s
    Click With Options    button span:has-text("Zobrazit") >> nth=0    clickCount=2
    # Vyčkání na dokončení stahování z předchozího kroku
    ${file_obj}=    Wait For    ${dl_promise}
    File Should Exist    ${file_obj.saveAs}
    ${size}=    Get File Size    ${file_obj.saveAs}
    Should Be True
    ...    ${size} > 1024
    ...    Zpráva: Stažený soubor je příliš malý (${size} bytes), pravděpodobně jde o chybu.

Kliknout Na Tlačítko S Textem
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Klikne na tlačítko obsahující zadaný text.
    [Arguments]    ${text}
    Wait For Elements State    h3, button >> "${text}" >> nth=0
    Click    h3, button >> "${text}" >> nth=0

Vybrat Z Dropdownu
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Vybere zadanou položku z dropdown menu.
    [Arguments]    ${nazev_dropdownu}    ${hodnota}
    ${trigger}=    Set Variable
    ...    //label[text()="${nazev_dropdownu}"]/ancestor::*[2]//div[contains(@class,"ui-selectonemenu-trigger")]
    Wait For Elements State    //label[text()="${nazev_dropdownu}"]
    WHILE    True    limit=3
        Click With Options    ${trigger}
        ${polozka_viditelna}=    Run Keyword And Return Status
        ...    Wait For Elements State    li[data-label*="${hodnota}"]
        IF    ${polozka_viditelna}    BREAK
    END
    Click With Options    li[data-label*="${hodnota}"]

Zkontroluj Částku Za Stažení
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Ověří, že částka za stažení LV je správná a zobrazuje se v aplikaci.
    [Arguments]    ${ocekavana_castka}
    Wait For Elements State    div label:has-text("cena")
    ${castka_text}=    Get Text    label:has-text("cena") >> ..
    IF    '${ocekavana_castka}' not in '${castka_text}'
        ${castka_text}=    Get Text    td:has-text("cena") >> ..
    END
    Should Contain    ${castka_text}    ${ocekavana_castka}

Ověřit Výsledky V Tabulce
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Ověří, že výsledky zobrazené v tabulce odpovídají očekávaným hodnotám.
    [Arguments]    ${ocekavany_vysledek}
    Wait For Elements State    form table
    Get Text    table >> td:has-text("${ocekavany_vysledek}")    contains    ${ocekavany_vysledek}

Ověřit Výsledky Z Fieldsetu
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Ověří, že výsledky zobrazené ve fieldsetu odpovídají očekávaným hodnotám.
    [Arguments]    ${nazev_fieldsetu}    ${ocekavany_vysledek}
    Wait For Elements State    fieldset
    Get Text    fieldset tr >> td:has-text("${nazev_fieldsetu}") >> ..    contains    ${ocekavany_vysledek}

Ověřit Chybovou Hlášku Povinného Pole
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Ověří, že při nevyplnění povinného pole se zobrazí správná chybová hláška.
    [Arguments]    ${ocekavana_hlaska}
    ${pocet_povinnych_poli}=    Get Element Count    span.ui-outputlabel-rfi
    FOR    ${index}    IN RANGE    ${pocet_povinnych_poli}
        ${nazev_pole}=    Get Text    span.ui-outputlabel-rfi >> .. >> nth=${index}
        ${nazev_pole}=    Fetch From Left    ${nazev_pole}    *
        Log    ${nazev_pole}
        Get Text    //label[contains(text(),"${nazev_pole}")]/../..//span[@class="ui-message-error-detail"]
        ...    ==
        ...    ${ocekavana_hlaska}
    END

Nedojde Ke Stažení Souboru
    # Autor: Hoang Anh Tran Nguyenová
    [Documentation]    Ověří, že při neúspěšném pokusu o stažení souboru se zobrazí správná chybová zpráva.
    Kliknout Na Tlačítko S Textem    Stáhnout LV
    Run Keyword And Ignore Error    Promise To Wait For Download    ${None}
    Wait For Elements State    button >> "Zobrazit LV" >> nth=0    hidden
