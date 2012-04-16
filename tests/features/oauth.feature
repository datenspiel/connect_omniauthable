Feature: Authenticate at an OAuth Server
  As registered client
  I want to get an access token from the OAuth Server
  So that I have access to remote data

  Background:
    Given I am on the home page
    Then I should see "OAuth Test app"
    And I should see "Grant Access"
    When I click on "Grant Access"
    Then I should see "Access Grant for OAuth Test client"
    And I should see "OAuth Test client wants to access your data. You want to allow access?"
    And I should see a button labeled "Allow"

  Scenario: Invoking an access grant    
    When I press "Allow"
    Then I should see "AuthCode"
    And states are equal
    And I should see a button labeled "Request Access Token"
    When I press "Request Access Token"
    Then I should see "You could now access data."
    And I should see "bearer" as token type
    And I get an access token