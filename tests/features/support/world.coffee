zombie = require('zombie')
HTML5  = require('html5')
should = require('should')

World = module.exports = (callback)->
  @browser = new zombie.Browser(runScripts:true, debug:false, htmlParser: HTML5)

  @page = (path)->
    return "http://localhost:3000#{path}"

  @visit = (url,callback)->
    @browser.visit(@page(url),callback)
  callback() if callback?
