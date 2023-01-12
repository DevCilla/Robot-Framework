# Robot to enter weekly sales data into the RobotSpareBin Industries Intranet.

import os

from Browser import Browser
from Browser.utils.data_types import SelectAttribute
from RPA.Excel.Files import Files
from RPA.HTTP import HTTP
from RPA.PDF import PDF


browser = Browser()


def open_the_intranet_website():
    browser.new_page("https://robotsparebinindustries.com/")


def log_in():
    browser.type_text("css=#username", "maria")
    browser.type_secret("css=#password", "thoushallnotpass")
    browser.click("text=Log in")


def download_the_excel_file():
    http = HTTP()
    http.download(
        url="https://robotsparebinindustries.com/SalesData.xlsx",
        overwrite=True)


def fill_and_submit_the_form_for_one_person(sales_rep):
    browser.type_text("css=#firstname", sales_rep["First Name"])
    browser.type_text("css=#lastname", sales_rep["Last Name"])
    browser.type_text("css=#salesresult", str(sales_rep["Sales"]))
    browser.select_options_by(
        "css=#salestarget",
        SelectAttribute["value"],
        str(sales_rep["Sales Target"]))
    browser.click("text=Submit")


def fill_the_form_using_the_data_from_the_excel_file():
    excel = Files()
    excel.open_workbook("SalesData.xlsx")
    sales_reps = excel.read_worksheet_as_table(header=True)
    excel.close_workbook()
    for sales_rep in sales_reps:
        fill_and_submit_the_form_for_one_person(sales_rep)


def collect_the_results():
    browser.take_screenshot(
        filename=f"{os.getcwd()}/output/sales_summary.png",
        selector="css=div.sales-summary")


def export_the_table_as_a_pdf():
    sales_results_html = browser.get_property(
        selector="css=#sales-results", property="outerHTML")
    pdf = PDF()
    pdf.html_to_pdf(sales_results_html, "output/sales_results.pdf")


def log_out():
    browser.click("text=Log out")


def main():
    try:
        open_the_intranet_website()
        log_in()
        download_the_excel_file()
        fill_the_form_using_the_data_from_the_excel_file()
        collect_the_results()
        export_the_table_as_a_pdf()
    finally:
        log_out()
        browser.playwright.close()


if __name__ == "__main__":
    main()