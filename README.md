# Jeff

**Jeff** is a light-weight module that mixes in client behaviour for
[Amazon Web Services (AWS)][aws]. It wraps [Excon][excon], parses
responses with [Nokogiri][nokogiri], and implements [Signature Version
2][sign].

![jeff][jeff]

## Usage

Build a a hypothetical client.

```ruby
class Client
  include Jeff
end
```

Customise default headers and parameters.

```ruby
class Client
  headers 'User-Agent' => 'Client'
  params  'Service'    => 'SomeService',
          'Tag'        => -> { tag }

  attr_accessor :tag
end
```

Set an AWS endpoint and credentials.

```ruby
client = Client.new.tap do |config|
  config.endpoint = 'http://example.com/path'
  config.key      = 'key'
  config.secret   = 'secret'
end
```

You should now be able to access the endpoint.

```ruby
res = client.post query: {},
                  body:  'data'

puts res.status    # => 200
puts res.body.root # => { 'Foo' => 'Bar' }
```

### Chunked Requests

You can upload large files performantly by passing a proc that delivers
chunks.

```ruby
file = File.open 'data'
chunker = -> { file.read Excon::CHUNK_SIZE).to_s }

client.post query:         {},
            request_block: chunker
```

## Compatibility

**Jeff** is compatible with [all Ruby 1.9 flavours][travis].

[aws]:      http://aws.amazon.com/
[excon]:    https://github.com/geemus/excon
[jeff]:     http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[nokogiri]: http://nokogiri.org/
[sign]:     http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[travis]:   http://travis-ci.org/#!/hakanensari/jeff
