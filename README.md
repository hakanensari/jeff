# Jeff

Jeff mixes in client behaviour for Amazon Web Services (AWS) that require
[Signature version 2 authentication][sig].

Jeff builds on [Excon][exc].

![jeff][jef]

## Usage

A minimal example:

```ruby
ProductsService = Struct.new(:aws_access_key_id, :aws_secret_access_key) do
  include Jeff

  PARSER = /Status>([^<]+)/

  def self.status
    new('foo', 'bar').status
  end

  def aws_endpoint
    'https://mws.amazonservices.com/Products/2011-10-01'
  end

  def status
    get(query: { 'Action' => 'GetServiceStatus' })
      .body
      .match(PARSER)
      .[](1)
  end
end

ProductsService.status
# => "GREEN"
```

[Vacuum][vac] and [Peddler][ped] implement Jeff.

[sig]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[exc]: https://github.com/geemus/excon
[jef]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[vac]: https://github.com/hakanensari/vacuum
[ped]: https://github.com/papercavalier/peddler
