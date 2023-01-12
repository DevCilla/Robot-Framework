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
Library    RPA.Windows
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault
Library    RPA.FileSystem

*** Variables ***
${PDF_TEMPLATE}    ${CURDIR}${/}receipt.template
${IMG_DIR}    ${CURDIR}${/}images${/}
${RECEIPT_DIR}    ${CURDIR}${/}receipts${/}
${ZIP_FILE_DIR}    ${CURDIR}${/}output${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc.  
    Open website    
    ${secret}=    Get credentials
    Log in and go to robot order page    ${secret}[username]    ${secret}[password]
    ${url}=    Ask user to provide URL to download orders
    Get orders    ${url}
    Fill the form using the data from the CSV file
    ZIP all PDF receipts
    [Teardown]    Log out and close the browser

*** Keywords ***
Open website
    Open Available Browser    https://robotsparebinindustries.com/    headless=True
    # Open Headless Chrome Browser    https://robotsparebinindustries.com/
Get credentials
    ${secret}=    Get Secret    credential
    RETURN    ${secret}
Log in and go to robot order page
    [Arguments]    ${username}    ${password}
    Input Text    username    ${username}
    Input Password    password    ${password}
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
Ask user to provide URL to download orders
    Add text input    downloadUrl    label=Download Url
    ${response}=    Run dialog
    RETURN    ${response.downloadUrl}
Get orders
    [Arguments]    ${url}
    # Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${url}    overwrite=True
    
Fill the form using the data from the CSV file
    ${orders}=    Read table from CSV    orders.csv   header=True   
    FOR    ${order}    IN    @{orders}           
        ${is_complete}    Set Variable    ${False}
        WHILE    ${is_complete} == ${False}
            ${is_complete}=    Fill and submit form for one order    ${order}
        END                              
    END
Fill and submit form for one order
    [Arguments]    ${order}
    TRY
        Click robot order page modal
        Select From List By Value    id:head    ${order}[Head]
        Select Radio Button    body    ${order}[Body]
        Input Text    css:input[type="number"]    ${order}[Legs]
        Input Text    id:address    ${order}[Address]
        Get preview image of robot    ${order}[Order number]
        ${receipt_html}=    Get receipt of order    ${order}[Order number]
        # Combine preview to receipt    ${order}[Order number]
        Create PDF record for the order    ${receipt_html}    ${order}[Order number]
        Order another robot
        RETURN    ${True}
    EXCEPT    AS    ${exception}
        Log    ${exception}
        Reload Page
        Fill and submit form for one order    ${order}
    END
    
Get preview image of robot
    [Arguments]    ${order_number}
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview
    Wait Until Element Is Visible    css:img[alt="Head"]
    Wait Until Element Is Visible    css:img[alt="Body"]
    Wait Until Element Is Visible    css:img[alt="Legs"]
    Scroll Element Into View    css:a.attribution
    Capture Element Screenshot    id:robot-preview-image    ${IMG_DIR}robot-${order_number}-preview.png
Get receipt of order
    [Arguments]    ${order_number}
    Click Button    id:order
    Wait Until Element Is Visible    id:order-completion
    ${order_result_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_result_html}    ${RECEIPT_DIR}robot-${order_number}-receipt.pdf
    RETURN    ${order_result_html}
Create PDF record for the order
    [Arguments]    ${receipt}    ${order_number}
    ${PDF_OUTPUT_PATH}    Set Variable    ${RECEIPT_DIR}robot-${order_number}-receipt.pdf
    ${data}=    Create Dictionary
    ...    receipt=${receipt}
    ...    screenshot=${IMG_DIR}robot-${order_number}-preview.png
    Log    'PDF output path: '${PDF_OUTPUT_PATH}
    Log    'Data: '${data}
    Template Html To Pdf    ${PDF_TEMPLATE}    ${PDF_OUTPUT_PATH}    variables=${data}
Combine preview to receipt
    [Arguments]    ${order_number}
    Open Pdf    ${RECEIPT_DIR}robot-${order_number}-receipt.pdf
    ${files}=    Create List
    ...    ${IMG_DIR}robot-${order_number}-preview.png:y=750,align=center
    Add Files To Pdf    ${files}    ${RECEIPT_DIR}robot-${order_number}-receipt.pdf
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
ZIP all PDF receipts
    ${dir_not_exists}=    Does Directory Not Exist    ${ZIP_FILE_DIR}
    IF    ${dir_not_exists}    Create Directory    ${ZIP_FILE_DIR}
    Archive Folder With Zip    ${RECEIPT_DIR}    ${ZIP_FILE_DIR}PDFs.zip
If error element appears
    [Arguments]    ${locator}
    ${no_error}=    Does Page Contain Element   css:div.alert.alert-danger
    IF    ${no_error} > 0
        Click Element When Visible    ${locator}
    END