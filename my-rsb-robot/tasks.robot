*** Settings ***
Documentation       Template robot main suite.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.PDF

*** Keywords ***
Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/
Log in
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form
    Wait Until Page Contains Element    id:sales-form
Log out and close the browser
    Click Button     id:logout
    Close Browser
Fill and submit form
    Input Text    firstname    John
    Input Text    lastname    Smith
    Select From List By Value    salestarget    50000
    Input Text    salesresult    12345    
    Click Button    css:button[type="submit"]
Fill the form using the data from the Excel file
    Open Workbook    SalesData.xlsx
    ${sales_reps}=    Read Worksheet As Table    header=True    
    Close Workbook
    FOR    ${sales_rep}    IN    @{sales_reps}
        Fill and submit form for one person    ${sales_rep}
    END
Fill and submit form for one person
    [Arguments]    ${sales_rep}
    Input Text    firstname    ${sales_rep}[First Name]
    Input Text    lastname    ${sales_rep}[Last Name]
    Input Text    salesresult    ${sales_rep}[Sales]
    Select From List By Value    salestarget    ${sales_rep}[Sales Target]
    Click Button    Submit
Download the Excel file
    Download    https://robotsparebinindustries.com/SalesData.xlsx    overwrite=True
Collect the results
    Screenshot    css:div.sales-summary    ${OUTPUT_DIR}${/}sales_summary.png
Export the table as a PDF
    Wait Until Element Is Visible    id:sales-results
    ${sales_result_html}=    Get Element Attribute    id:sales-results    outerHTML
    Html To Pdf    ${sales_result_html}    ${OUTPUT_DIR}${/}sales_results.pdf

*** Tasks ***
Minimal task
    Log    Done.
    
Insert the sales data for the weel and export it as PDF
    Open the intranet website
    Log in
    Fill the form using the data from the Excel file
    Download the Excel file
    Collect the results
    Export the table as a PDF
    [Teardown]    Log out and close the browser