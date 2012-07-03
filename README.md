# Jeff

Jeff is a light-weight module that mixes in client behaviour for [Amazon Web
Services (AWS)][aws]. It wraps [Excon][excon] and implements [Signature Version
2][sign].

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
  config.endpoint = 'http://aws-url.com'
  config.key      = 'key'
  config.secret   = 'secret'
end

client.post body: 'data'
```

Make a chunked request.

```ruby
file = File.open 'data'
chunker = -> file.read Excon::CHUNK_SIZE).to_s

client.post request_block: chunker
```

Stream a response.

```ruby
streamer = ->(chunk, remaining, total) { puts chunk }

client.get response_block: streamer
```

[aws]: http://aws.amazon.com/
[excon]: https://github.com/geemus/excon
[sign]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
