# Jeff

Jeff mixes in client behaviour for [Amazon Web Services (AWS)][aws] that
require [Signature version 2 authentication][sig].

![jeff][jef]

## Usage

The following is a minimal example:

```ruby
Request = Struct.new(:key, :secret) do
  include Jeff
end

req = Request.new('key', 'secret')
res = req.get(query: { 'Foo' => 'Bar' })
```

Read the source code of [Vacuum][vac] for a more material implementation.

[aws]:  http://aws.amazon.com/
[sig]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[vac]: https://github.com/hakanensari/vacuum
[jef]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
