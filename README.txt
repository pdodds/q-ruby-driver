q-ruby-driver
  by Philip Dodds and John Shields
  http://www.github.com/pdodds/q-ruby-driver

== DESCRIPTION:

A ruby interface to a Q server from Kx Systems (http://www.kx.com). See: http://code.kx.com for more information.

== FEATURES:

* Provides a pure Ruby implementation of the IPC protocol
* Supports single-pass read/write for all main Q-types (19 atom types, 19 vector types, lists, dicts, flips, exceptions)
* Converts Q types to/from native Ruby types, including Array, Hash, Bignum, Float, Symbol, and TrueClass/FalseClass. Date/Time types are not yet natively supported.

== EXAMPLE USAGE:

        q_connection = QConnection.new 'localhost', 5001

        # Note we'll use the sync call (get)
        q_connection.get("a:`IBM`GOOG`APPL")
        response = q_connection.get("a")

        # Get the body of the response
        puts response.inspect


== REQUIREMENTS:

Ruby 1.8+

== INSTALL:

sudo gem install q-ruby-driver

== LICENSE:

(The MIT License)

Copyright (c) 2009 Philip Dodds

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
