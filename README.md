# Jeff

**Jeff** mixes in [authentication][sign] for [Amazon Web Services (AWS)][aws].

![jeff][jeff]

## Usage

Build a hypothetical client.

```ruby
class Client
  include Jeff
end
```

Set AWS endpoint and credentials.

```ruby
client = Client.new
client.endpoint = 'http://example.com/path'
client.key      = 'key'
client.secret   = 'secret'
```

Hit the endpoint.

```ruby
client.get query: { 'Foo' => 'Bar' }
```

Oh là là.

[aws]:  http://aws.amazon.com/
[jeff]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[sign]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
