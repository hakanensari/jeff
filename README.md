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

By setting the minimum credentials, you should be able to access a compatible
AWS endpoint.

```ruby
client = Class.new.tap do |config|
  config.endpoint = 'http://aws-url.com/path'
  config.key      = 'key'
  config.secret   = 'secret'
end

client.post body: 'data'
```

Make a chunked request.

```ruby
file = File.open 'data'
chunker = -> { file.read Excon::CHUNK_SIZE).to_s }

client.post request_block: chunker
```

Stream a response.

```ruby
streamer = ->(chunk, remaining, total) { puts chunk }

client.get response_block: streamer
```

HTTP connections are persistent.

## DSL

**Jeff** comes with a minimal DSL to set default headers and parameters.

```ruby
class Client
  include Jeff

  params 'Tag'     => Proc.new { tag },
         'Service' => 'SomeService'

  attr_accessor :tag
end
```

Use procs to populate dynamic values.

```ruby
client = Client.new
client.tag = 'foo'

client.default_params.fetch 'Tag'
# => 'foo'
```

[aws]:   http://aws.amazon.com/
[excon]: https://github.com/geemus/excon
[sign]:  http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[jeff]:  http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
