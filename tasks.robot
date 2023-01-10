*** Settings ***
Documentation     Template robot main suite.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.RobotLogListener

*** Keywords ***
Open website
    Open Available Browser    https://robotsparebinindustries.com/    headless=True    maximized=True
    # Open Headless Chrome Browser    https://robotsparebinindustries.com/
Log in and go to robot order page
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form
    Click Element    css:a[href="#/robot-order"]
Log out and close the browser
    ${modal}=    Is Element Visible    css:div.modal-content
    IF    ${modal} == True
        Click robot order page modal
    END
    Click Button     id:logout
    Close Browser  
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
Fill the form using the data from the CSV file
    ${orders}=    Read table from CSV    orders.csv   header=True   
    FOR    ${order}    IN    @{orders}
        Click robot order page modal
        Fill and submit form for one order    ${order}        
        Order another robot
    END
Fill and submit form for one order
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[type="number"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    ${screenshot}=    Get preview image of robot    ${order}[Order number]    
    ${receipt}=    Get receipt of order    ${order}[Order number]
    # Combine preview to receipt    ${order}[Order number]
    Create PDF record for the order    ${receipt}    ${screenshot}    ${order}[Order number]
Get preview image of robot
    [Arguments]    ${order_number}
    Click Button    id:preview
    If error element appears    id:preview
    Wait Until Element Is Visible    css:img[alt="Head"]
    Wait Until Element Is Visible    css:img[alt="Body"]
    Wait Until Element Is Visible    css:img[alt="Legs"]
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot-${order_number}-preview.png
    ${image_path}    Set Variable    ${OUTPUT_DIR}${/}robot-${order_number}-preview.png
    #${image}=    Get Element Attribute    id:robot-preview-image    innerHTML
    RETURN    ${image_path}
Get receipt of order
    [Arguments]    ${order_number}
    Click Button    id:order
    If error element appears   css:button.btn.btn-primary
    If order not completed
    ${order_result_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_result_html}    ${OUTPUT_DIR}${/}robot-${order_number}-receipt.pdf
    ${pdf_path}    Set Variable    ${OUTPUT_DIR}${/}robot-${order_number}-receipt.pdf
    RETURN    ${pdf_path}
Create PDF record for the order
    [Arguments]    ${receipt}    ${image}    ${order_number}
    ${files}=    Create List
    ...    ${receipt}
    ...    ${image}
    # Html To Pdf    ${html}    ${OUTPUT_DIR}${/}robot-${order_number}-receipt.pdf
    Add Files To Pdf    ${files}    ${receipt}
Combine preview to receipt
    [Arguments]    ${order_number}
    Open Pdf    ${OUTPUT_DIR}${/}robot-${order_number}-receipt.pdf
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}robot-${order_number}-preview.png:y=50,align=center
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}robot-${order_number}-receipt.pdf
    Close Pdf
Order another robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    If error element appears    css:button.btn.btn-primary
    Wait Until Page Contains Element    id:head
Click robot order page modal
    Wait Until Element Is Visible    css:div.modal-content
    Click Button    css:button.btn.btn-warning
    Wait Until Page Contains Element    id:head
If error element appears
    [Arguments]    ${locator}
    ${no_error}=    Does Page Contain Element   css:div.alert.alert-danger
    IF    ${no_error} > 0
        Click Element When Visible    ${locator}
    END
If order not completed
    ${completed}=    Does Page Contain Element   id:order-completion
    WHILE    ${completed} < 1
        Click Element When Visible    css:button.btn.btn-primary    
        ${completed}=    Does Page Contain Element   id:order-completion
        IF    ${completed} > 0    BREAK
    END
            
*** Tasks ***
Order robots from RobotSpareBin Industries Inc.
    Set Selenium Speed    1 second
    Open website
    Log in and go to robot order page
    Get orders
    Fill the form using the data from the CSV file
    # [Teardown]    Log out and close the browser




