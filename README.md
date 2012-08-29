# Jeff

[![travis][stat]][trav]

**Jeff** adds [authentication][sign] behaviour for some [Amazon Web Services (AWS)][aws].

![jeff][jeff]

## Usage

Mix in.

```ruby
class Client
  include Jeff
end
```

Set endpoint and credentials.

```ruby
client = Client.new

client.endpoint = 'http://example.com/path'
client.key      = 'key'
client.secret   = 'secret'
```

Request.

```ruby
client.get query: { 'Foo' => 'Bar' }
```

[stat]: https://secure.travis-ci.org/papercavalier/jeff.png
[trav]: http://travis-ci.org/papercavalier/jeff
[aws]:  http://aws.amazon.com/
[jeff]: http://f.cl.ly/items/0a3R3J0k1R2f423k1q2l/jeff.jpg
[sign]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
