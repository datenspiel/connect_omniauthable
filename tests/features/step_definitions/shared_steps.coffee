sharedSteps = module.exports = ()->
  @.World = require('../support/world')

  @.Given /^I am on the home page$/, (next)->
    @.visit('/', next)

  @.Then /^I should see "([^"]*)"$/, (text, next)->
    #console.log this.browser.text('body')
    this.browser.text('body').should.include(text)
    next()

  @.Then /I click on "([^"]*)"$/, (link_text,next)->
    @browser.clickLink(link_text,next)

  @.Then /^I should see a button labeled "([^"]*)"$/, (button_label, next)->
    buttons = @browser.html('div.form-actions button')
    buttons.should.include(button_label)
    next()

  @.When /^I press "([^"]*)"$/, (button,next)->
    @browser.pressButton(button,next)

  @.Then /^states are equal$/, (next)->
    stateText = @browser.html('div.infos ul li.state')
    stateFromServerText = @browser.html('div.infos ul li.stateFromServer')

    state = stateText.split(":")[1].split("<")[0]
    stateFromServer = stateFromServerText.split(":")[1].split("<")[0]

    state.should.equal stateFromServer
    next()

  @.Then /^I should see "([^"]*)" as token type$/, (token_type,next)->
    text = @browser.html('div.result ul li.type')
    text.should.include(token_type)
    next()

  @.Then /^I get an access token$/, (next)->
    text = @browser.html('div.result ul li.token')
    token = text.split(":")[1].split("<")[0]
    token.should.not.be.empty
    next()
