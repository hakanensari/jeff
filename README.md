# Jeff

**Jeff** is a light-weight module that mixes in client behaviour for
[Amazon Web Services (AWS)][aws]. It wraps [Excon][excon] and implements 
[Signature Version 2][sign].

![jeff][jeff]

## Usage

Build a hypothetical client.

```ruby
class Client
  include Jeff
end
```

Customise default headers and parameters.

```ruby
class Client
  params  'Service'    => 'Service',
          'Tag'        => -> { tag }

  attr_accessor :tag
end
```

Set AWS endpoint and credentials.

```ruby
client = Client.new.tap do |config|
  config.endpoint = 'http://example.com/path'
  config.key      = 'key'
  config.secret   = 'secret'
end
```

You should now be able to access the endpoint.

```ruby
client.post query: { 'Foo' => 'Bar' },
            body:  'data'
```

## Compatibility

**Jeff** is compatible with [Ruby 1.9 flavours][travis].

[aws]:    http://aws.amazon.com/
[excon]:  https://github.com/geemus/excon
[jeff]:   http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[sign]:   http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
[travis]: http://travis-ci.org/#!/hakanensari/jeff
