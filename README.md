# Jeff

**Jeff** is a light-weight module that mixes in client behaviour for [Amazon
Web Services (AWS)][aws]. It wraps the HTTP adapter [Excon][excon] and
implements [Signature Version 2][sign].

![jeff][jeff]

## Usage

Here's a hypothetical client.

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
          'Tag'        => Proc.new { tag }

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
client.post query: {},
            body:  'data'
```

Make a chunked request.

```ruby
file = File.open 'data'
chunker = -> { file.read Excon::CHUNK_SIZE).to_s }

client.post query:         {},
            request_block: chunker
```

Stream a response.

```ruby
streamer = ->(chunk, remaining, total) { puts chunk }

client.get query:          {},
           response_block: streamer
```

HTTP connections are persistent.

[aws]:   http://aws.amazon.com/
[excon]: https://github.com/geemus/excon
[sign]:  http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[jeff]:  http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
