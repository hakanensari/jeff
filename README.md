# Jeff

Jeff mixes in client behaviour for Amazon Web Services (AWS) which require
[Signature version 2 authentication][sig].

![jeff][jef]

## Usage

A minimal example:

```ruby
Request = Struct.new(:aws_access_key_id, :aws_secret_access_key) do
  include Jeff

  def aws_endpoint; 'https://mws.amazonservices.com/Products/2011-10-01'; end
end

req = Request.new('foo', 'bar')
res = req.get(query: { 'Action' => 'GetServiceStatus' })

puts res.body.match(/Status>([^<]+)/)[1]
```

[Vacuum][vac] provides an example implementation.

[sig]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[vac]: https://github.com/hakanensari/vacuum
[jef]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
