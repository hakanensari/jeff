# Jeff

Jeff mixes in client behaviour for Amazon Web Services (AWS) which require
[Signature version 2 authentication][sig].

Monsieur Jeff couples with [Excon][exc].

![jeff][jef]

## Usage

A somewhat contrived example:

```ruby
Service = Struct.new(:aws_access_key_id, :aws_secret_access_key) do
  include Jeff

  def aws_endpoint
    'https://mws.amazonservices.com/Products/2011-10-01'
  end

  def status
    get(query: { 'Action' => 'GetServiceStatus' })
      .body
      .match(/Status>([^<]+)/)
      .[](1)
  end
end

srv = Service.new('key', 'secret')
srv.status # => "GREEN"
```

[Vacuum][vac] and [Peddler][ped] implement Jeff.

[sig]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[exc]: https://github.com/geemus/excon
[jef]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[vac]: https://github.com/hakanensari/vacuum
[ped]: https://github.com/papercavalier/peddler
