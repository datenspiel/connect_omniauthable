path    = require 'path'
jade    = require 'jade'
fs      = require 'fs'

# A template class which compiles Jade templates with its locales 
# into valid html.
class Templater

  @setTemplateRoot:(path)->
    @templatesPath = path

  @getTemplatesRoot:->
    if @templatesPath? then @templatesPath else path.join(__dirname,'..','views')

  # Compiles a template and pass it to a callback.
  #
  # options - The argument options to compile the template.
  #     :template - name of the template (without *.jade extension)
  #     :locals   - contains the key/values for the variables in the template
  #     :cb       - a callback function which expects the compiled template
  #                 and a response object
  #     :res      - the response object
  @compile:(options)->
    callback = options.cb
    response = options.res
    compiledTemplate = jade.compile(@readTemplate(options.template))(options.locals)
    callback(compiledTemplate,response) if callback?
    return compiledTemplate unless callback?

  # Reads a template from templates root
  # 
  # name - name of the template without file extension
  #
  # Returns the content of the template.
  @readTemplate:(name)->
    return fs.readFileSync(path.join(@templatesPath,"#{name}.jade"))

module.exports = Templater