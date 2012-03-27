## Utilities

### Underscore.js extensions

[Underscore.js](http://documentcloud.github.com/underscore) works very well with node.js.

In underscore_extension.coffee you find a collection of useful methods which are not included in
underscore.js by default:

Include the extensions (which will also provides the whole underscore.js library):

```coffeescript
_ = require("./lib/util/underscore_extension")._
```

* isValidUrl()

<code>isValidIUrl()</code> checks if an URL is valid based on the assumption of an www URL:

```coffeescript
url = "https://github.com/datenspiel/common_dwarf_mongoose/tree/master/lib"
_(url).isValidUrl() #=> true

ftp_url = "ftp://ftp.blah.co.uk:2828/blah%20blah.gif"
_(ftp_url).isValidUrl() #=> false

urlWithDot = "https://github.com/datenspiel/common_dwarf_mongoose/tree/master/lib."
_(urlWithDot).isValidUrl() #=> false

``` 
