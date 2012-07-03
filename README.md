# Jeff

Jeff is a minimum-viable client for [Amazon Web Services (AWS) APIs][aws] that
support [Signature Version 2][sign].

## Usage

```ruby
client = Jeff.new 'http://some-aws-url.com/'
client << params
client << data

client.request
```

Stream responses.

```ruby
client << ->(chunk, remaining, total) { puts chunk }

client.request
```

[aws]: http://aws.amazon.com/
[sign]: http://docs.amazonwebservices.com/general/latest/gr/signature-version-2.html
