# Created:  13.11.2021  leo2022977
#
# Calculator tests
#
# Test requirements:
#   - perform a simple mathematical operation with 2 operands (for example “10 + 5”).
#   - type the numbers in the calculator, press the equal sign, fetch the result displayed by the web calculator and verify that this is correct.
#   - Operands are not limited to single digit (we should be able to calculate “100 – 20” expressions).
# Limitations:
#   - don’t care about decimal numbers and precision (when doing division)
#   - only cover operations that have unsigned integer result
#   - only cover addition, subtraction, multiplication and division
#   - use only unsigned integers as operands
#   - don't care about invalid operations (division by zero for example) and invalid characters (skip input data validation)
#
# Execution examples:
# EXECUTE TESTS WITH DEFAULT VALUES:    robot -d Results  Tests/LaskinTesti.robot
# EXECUTE TESTS WITH VALUES FROM COMMAND LINE:
# robot -d Results --variable BROWSER:chrome  --variable FIRST_OPERAND:200  --variable OPERATOR:+  --variable SECOND_OPERAND:3  Tests/LaskinTesti.robot
#
# Notes and limitations (suomeksi):
# - Suoritus on testattu toimivaksi firefox selaimella (v. 93)
# - Chromen WebDriverilla 95 tulee kasa erilaisia virheilmoituksia laskinsivulla.
#       * Em virheistä johtuen en pystynyt hyväksymään cookieita ko. sivulla enkä siksi päässyt itse laskimelle
#       * Versiolla 96 testit näyttäisi menevän läpi ja cookiet saa hyväkysyttyä, mutta lokiin tulee silti outoja virheitä mm. bluetoothista
#       * Seuraavaksi pitäisi kokeilla muuttaa webdriverin asetuksia
# - Oletuslaskintilassa en löytänyt sivun elementeistä operaation tulosta. Kiertotienä vaihdan alussa laskimen Math Formula Input (beta) moodiin
#       * selvitin myöhemmin devaajatutuilta, että tuloksen saa oletusmoodissa input-kentästä ainakin javascriptillä
# - Tehtävän palautusta varten koodi on kaikki yhdessä tiedostossa. Tosielämässä laittaisin
#       * low ja high level keywordit omiin resurssitiedostoihin ja jättäisin vain testikeissit tähän tiedostoon.
# - Joskus testi menee niin nopeasti, että laskin ei ole vielä ehtinyt luoda tulosta näytölle
#       * tarkistettavan tuloksen sijasta testi saa tarkistettavakseen operaation tekijät (esim. '1+5' koska 6 ei ole vielä näkyvissä)
#       * em vuoksi koodissa on yksi Sleep, minkä käytön tiedän huonoksi.
#       * yleensä pyrin käyttämään Wait kw:jä, mutta nyt en keksinyt mitä elementtiä tai sen argumenttia odottaisin
#

*** Settings ***
Library  SeleniumLibrary

*** Variables ***
${BROWSER}                      chrome
${URL}                          https://web2.0calc.com/
${FIRST_OPERAND}                15
${OPERATOR}                     *
${SECOND_OPERAND}               3
${ButtonAcceptCookiesXpath}     xpath=//button[@aria-label="Consent"]
${InputMethodSelectorXpath}     xpath=//div[@id="inputhelper"]
${InputMethodListXpath}         xpath=//ul[@id="inputhelpermenu"]
${ResultMathFieldXpath}         xpath=//span[@id="math-field"]
${ButtonResultXpath}            xpath=//button[@id="BtnCalc"]
${ButtonClearXpath}             xpath=//button[@id="BtnClear"]
${DivCalculatorXpath}           xpath=//div[@id="calccontainer"]


*** Keywords ***
##############################################
# LOW LEVEL KEYWORDS
##############################################

Begin Web Test
    [Documentation]  Opens a browser and maximizes the window
    Open Browser  about:blank   ${BROWSER}
    Maximize Browser Window


End Web Test
    [Documentation]  Closes the browser
    Close Browser

Check And Accept Cookie Alert
    [Documentation]  If cookie alert is visible it should be closed before calculation
    ${cookieAlertTrue}  Run Keyword And Return Status  Page Should Contain Button  ${ButtonAcceptCookiesXpath}
    Run Keyword If      '${cookieAlertTrue}'=='True'   Click Button    ${ButtonAcceptCookiesXpath}

Navigate To Calculator
    [Documentation]  Navigation to calculator page. When cookie popup is visible, cookieds are accepted.
    Go To  ${URL}
    Wait Until Page Contains Element    calccontainer
    Check And Accept Cookie Alert

Verify Calculator Is Visible
    [Documentation]  Checking the calculator visibility after accessing the page
    Page Should Not Contain Element     ${ButtonAcceptCookiesXpath}
    Page Should Contain Element         ${DivCalculatorXpath}
    Element Should Be Visible           ${ButtonResultXpath}

Change Calculator Type
    [Documentation]  Changes Calculator type into Math Formula Input, in order to view the user input in elements
    Page Should Contain Element     ${InputMethodSelectorXpath}
    Click Element                   ${InputMethodSelectorXpath}
    Wait Until Element Is Visible   ${InputMethodListXpath}
    Click Element                   ${InputMethodListXpath}/li[1]/form/button


Verify That Calculator Is Resetted
    [Documentation]  Checks that calculator input field is empty
    Page Should Contain Element                 ${ResultMathFieldXpath}
    ${AttributeValue}=  Get Element Attribute   ${ResultMathFieldXpath}/span[2]/span  class
    Should Match  ${AttributeValue}  pattern=mq-cursor*


Insert Multidigit Number Into Calculator
    [Documentation]  Splits the multidigit number into separate digits with Javascript and enters those into Calculator
    [Arguments]  ${multidigitOperand}  ${OperandLenght}
    @{listOfNumbers}  Execute Javascript  return (${multidigitOperand}).toString(10).split("");
    FOR  ${i}  IN RANGE  ${OperandLenght}
        Click Button  id=Btn${listOfNumbers}[${i}]
    END

Perform A Given Operation
    [Documentation]  Performs an operation on Calculator.
                     ...  Arguments:
                     ...  firstOperand = operation's first number
                     ...  secondOperand = operation's second number
                     ...  operator = operator. Either - Minus, + Plus, / Div or * Mult
    [Arguments]  ${firstOperand}  ${operator}  ${secondOperand}
    ${OperationCode}    Set Variable If
    ...                '${operator}'=='+'  Plus
    ...                '${operator}'=='-'  Minus
    ...                '${operator}'=='/'  Div
    ...                '${operator}'=='*'  Mult
    ${firstOperandLenght}   Get Length  ${firstOperand}
    ${secondOperandLenght}  Get Length  ${secondOperand}

    Run Keyword If  ${firstOperandLenght} > 1  Insert Multidigit Number Into Calculator  ${firstOperand}  ${firstOperandLenght}
    ...       ELSE  Click Button  id=Btn${firstOperand}

    Click Button    id=Btn${OperationCode}

    Run Keyword If  ${secondOperandLenght} > 1  Insert Multidigit Number Into Calculator  ${secondOperand}  ${secondOperandLenght}
    ...       ELSE  Click Button  id=Btn${secondOperand}

    Click Button        ${ButtonResultXpath}
    ${operationResult}  Evaluate  ${firstOperand}${operator}${secondOperand}
    [Return]  ${operationResult}

Verify Correct Result
    [Documentation]  Gets the Calculator results and verifies that result is correct
    [Arguments]  ${operationResult}
    Sleep  600ms
    Page Should Contain Element         xpath=//span[@id="math-field"]
    ${count}            Get Element Count   xpath=//span[@id="math-field"]/span[2]/span
    ${roundCount}       Evaluate  ${count}-1
    ${CalcResult}       Set Variable  ${EMPTY}
    FOR  ${index}       IN RANGE    ${roundCount}
        ${index}        Evaluate    ${index} + 1
        ${CalcResult1}  Get Text  xpath=//span[@id="math-field"]/span[2]/span[${index}]
        ${CalcResult}   Catenate   ${CalcResult}${CalcResult1}
    END
    Should Be Equal As Numbers  ${operationResult}  ${CalcResult}

Reset Calculator
    [Documentation]  Resets the Calculator
    Click Button    ${ButtonClearXpath}
    Verify That Calculator Is Resetted


*** Test Cases ***
User can perform an operation with calculator
    [Documentation]  Test expects two positive integer numbers and operator from user, performs a calculation and checks the result.
    ...              Tests starts by opening the browser, navigating to calc page and accepting cookies.
    ...              After vefifying the calc is visible operation if performed and result verified.
    ...              In the end the browser is closed.
    ...              Variables:
    ...              ${FIRST_OPERAND} =  operation's first number, can be any positive integer
    ...              ${OPERATOR}  = operator either +, -, / or *
    ...              ${SECOND_OPERAND} =  second number. Can be any positive integer, which does not lead to decimal or negative result.
    Begin Web Test
    Navigate To Calculator
    Verify Calculator Is Visible
    Change Calculator Type
    Verify That Calculator Is Resetted
    ${operationResult} =  Perform A Given Operation  ${FIRST_OPERAND}  ${OPERATOR}  ${SECOND_OPERAND}
    Verify Correct Result  ${operationResult}
    Reset Calculator
    End Web Test

