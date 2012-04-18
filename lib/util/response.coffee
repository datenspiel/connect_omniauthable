# A wrapper around the node/connect response object with 
# some useful methods.
class ResponseHeader
  constructor:(@response)->

  # Sets the response header to text/html.
  setHtml:->
    @response.setHeader("Content-Type", "text/html")

  # Sets the response header to application/json
  setJSON:->
    @response.setHeader("Content-Type", "application/json")

  # Sets the response status code to unauthorized
  setUnauthorized:->
    @response.statusCode = 401

  # Sets the response status code to any given code.
  # 
  # code -  The response HTTP status code as described in
  #         http://en.wikipedia.org/wiki/HTTP_status
  setStatus:(code)->
    @response.statusCode = code

  # Sets the response header to a given location and 
  # the status code to 302 (FOUND)
  #
  # url - An url to which the browser should be redirected.
  setLocation:(url)->
    @response.statusCode = 302
    @response.setHeader("Location", url)

  # Redirects the browser to the given URL.
  #
  # url - An url to which the browser should be redirected.
  redirectTo:(url)->
    @setLocation(url)
    @response.end()

module.exports = ResponseHeader