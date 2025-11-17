Feature: Export Form Results to CSV
    As an Administrator
    I want to download a CSV file containing form results
    In order to evaluate class performance

    Background:
        Given that I am logged in as an administrator

    Scenario: Successfully download CSV file with form results
        Given that I am on the form results page
        And there are form results available
        When I click on "Download CSV"
        Then a CSV file should be downloaded
        And the file should be named "form_results.csv"
        And the CSV file should contain form result data

    Scenario: Download CSV file for a specific class
        Given that I am on the form results page
        And I select class "Turma A - 2024"
        When I click on "Download CSV"
        Then a CSV file should be downloaded
        And the file should be named "form_results_turma_a_2024.csv"
        And the CSV file should contain only results from "Turma A - 2024"

    Scenario: Verify CSV file content structure
        Given that I have downloaded a CSV file with form results
        When I open the CSV file
        Then the file should contain the following columns:
            | Student Name | Registration | Class | Form Score | Submission Date |
        And each row should represent a form submission
        And the data should be properly formatted

    Scenario: Download CSV when no form results are available
        Given that I am on the form results page
        And there are no form results available
        When I click on "Download CSV"
        Then I should see "No form results available for export"
        And no file should be downloaded

    Scenario: Download CSV without administrator permissions
        Given that I am logged in as a regular user
        When I try to access the form results page
        Then I should see "Access denied"
        And I should not see the "Download CSV" button

    Scenario: Download CSV with filtered results
        Given that I am on the form results page
        And I apply filters:
            | Filter Type | Value        |
            | Class       | Turma B      |
            | Date Range  | 2024-01-2024-03 |
        When I click on "Download CSV"
        Then a CSV file should be downloaded
        And the CSV file should contain only filtered results
        And the file should reflect the applied filters in its name

    Scenario: Download CSV with all classes performance data
        Given that I am on the form results page
        And I select "All Classes" option
        When I click on "Download CSV"
        Then a CSV file should be downloaded
        And the CSV file should contain results from all classes
        And the file should include class performance summary
        And the data should be organized by class

