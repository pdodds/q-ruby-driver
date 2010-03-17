q-ruby-driver
=
  by Philip Dodds
  http://www.github.com/pdodds/q-ruby-driver

DESCRIPTION:
-
A ruby interface to a Q server from http://www.kx.com,  see http://code.kx.com for more
information.

FEATURES/PROBLEMS:
-

* Provides a pure Ruby implementation of the IPC protocol
* Very limited

SYNOPSIS:
-

Currently we have a very limited implementation that is just a proof of concept

A very simple example of its use:

        q_instance = QInstance.new 5001

        # Note we'll use the sync call (get)
        q_instance.get("a:`IBM`GOOG`APPL")
        response = q_instance.get("a")

        # Get the body of the response
        puts response.value.inspect
        

REQUIREMENTS:
-

Ruby 1.8+

INSTALL:
-

sudo gem install q-ruby-driver

LICENSE:
-

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
