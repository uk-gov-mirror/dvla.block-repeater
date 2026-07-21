# Block Repeater

A way to repeat a block of code until either a given condition is met or a timeout has been reached

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'block_repeater'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install block_repeater

## Usage
Add the repeater and it's methods into a project
```ruby
include BlockRepeater
```

In order to maintain parity with existing Repeater implementations you may also need to expose the repeater class itself
```ruby 
Repeater = BlockRepeater::Repeater
```

### Repeat method
This is the preferred way to use the repeater. It requires two blocks, the one to be executed and the one which sets the exit condition. As these are ordinary ruby blocks they can be defined using either `{ }` or `do end` syntax.

```ruby
  repeat { call_database_method }.until{ |result| result.count.positive? }
```
```ruby
  repeat do
    call_database_method
  end.until do |result| 
    result.count.positive? 
  end
```
 
The repeater also takes two parameters:
 - `delay:` is how long in seconds the repeater will wait between attempts (defaults to 0.2 seconds)
 - `times:` is how many attempts the repeater will make before giving up (defaults to 25)
 ```ruby
   repeat (delay: 0.5, times: 10){ call_database_method }.until{ |result| result.count.positive? }
 ```

### Backoff method
This is a slightly different take on the preferred `repeat` method. It retries a call whilst exponentially increasing the wait time between each iteration until a timeout is reached.

```ruby
repeat do
  call_method
end.until do |result|
  result
end.backoff(timeout: 10, initial_wait: 0.5, multiplier: 2)
```

`backoff` takes three paramaters:
- `timeout:` is how long you want your repeater to run
- `initial_wait:` is how long you want to pause before your first retry
- `multiplier:` is the rate at which you increase the wait time between each iteration

### Exception Handling
Using the `catch` method you can define how the repeater should respond to specific exception types. To do this you need to provide a list of exceptions to catch, a block of code which will be performed, and an option for how to trigger than block of code.

**IMPORTANT: Any `catch` blocks must be declared _before_ the `until` block**

 The following code has custom behaviour for a variety of error types, stopping if it get's an IOError but otherwise continuing without halting the repeater:
```ruby
  repeat do
    call_database_method
  end.catch(exceptions: IOError, behaviour: :stop) do |e|
    puts "Error in IO operations: #{e}"
  end.catch(behaviour: :continue) do |e|
    puts "Error thrown: #{e}"
  end.until do |result|
    result.count.positive?
  end
```
`exceptions` can take either a single exception type or an array. If not provided it will default to `StandardError`.

There are three supported behaviours:
- `:continue` executes the provided block but doesn't stop the repeater
- `:stop` executes the provided block and then stops the repeater
- `:defer` only executes the provided block if the exception is still occurring on the final attempt. This is the default option.

If no block is provided it will default to attempting to raise the exception.

### Default Exception Handling Behaviour
You can also define default exception handling behaviour which all repeaters in a project will use. A `catch` block on a repeater will override default behaviour for the same exception type. In this following example all repeaters will automatically catch `IOErrors` and raise them if they're still occurring once the repeater has completed its attempts.

```ruby
BlockRepeater::Repeater.default_catch(exceptions: [IOError], behaviour: :defer) do |e|
  puts 'An IOError occurred'
  raise e
end
```
A common use-case for default exception handling is if using a gem such as RSpec, where you may want to handle failed expectations in a uniform manner. To do so you need define the default behaviour first, in a place such as a `env.rb` file or similar:
```ruby
BlockRepeater::Repeater.default_catch(exceptions: [RSpec::Expectations::ExpectationNotMetError], behaviour: :defer) do |e|
  raise e
end
```
Then an RSpec expectation can be used in the block for the `until` method. The expectation will be attempted each try, but the exception will only be raised if it has still failed once the number or attempts has been reached.
```ruby
  repeat do
    call_database_method
  end.until do |result| 
    expect(result.count).to be_positive, raise 'No result returned from databased'
  end
```
### Replay method
The `replay` method provides a retry-with-refresh mechanism for UI actions that may fail due to transient errors. It is designed for use with browser automation tools like Capybara.

```ruby
replay(exceptions: [Capybara::ElementNotFound], refresh: -> { page.refresh }) do
  find('#submit-button').click
end
```

`replay` takes five parameters:
- `times:` maximum retry attempts (defaults to 3)
- `delay:` seconds between retries (defaults to 0.5)
- `exceptions:` array of exception types to catch and retry on (defaults to [])
- `refresh:` a callable (Proc/lambda) to execute between retries for page refresh (defaults to nil)
- `logger:` any object responding to `#error` for error messages, or nil to silence logging (defaults to nil)

The block is executed and if a configured exception is raised, the error is logged, the refresh callable is invoked (if provided), and the block is retried. If the exception persists after all attempts, it is re-raised. The refresh is not called on the final attempt.

A typical setup with Capybara and locale handling:
```ruby
UI_ERRORS = [Capybara::ElementNotFound, Selenium::WebDriver::Error::ElementClickInterceptedError]

replay(exceptions: UI_ERRORS, refresh: -> { visit("#{current_path}?locale=#{I18n.locale}") }) do
  click_link_or_button('Continue')
end
```

To use a custom logger:
```ruby
replay(exceptions: UI_ERRORS, logger: Rails.logger) { perform_action }
```

To silence logging:
```ruby
replay(exceptions: UI_ERRORS, logger: nil) { perform_action }
```

### Non predefined condition methods
Very simple conditions can be utilised without using a block. This expects either one or two method names which will be called against the result of repeating the main block.
The required format is `until_<method name>` or `until_<method name>_becomes_<method name>`.
  
```ruby
  repeat { a_method_which_returns_a_number }.until_positive?
  #Attempts to call the :positive? method on the result of the method call

  repeat { a_method_which_returns_an_array }.until_count_becomes_positive?
  #Attempts to call :count on the result of the method call, then :positive? on that result
```
This supports up to two consecutive method calls, anything more complex should be written out in full in the standard manner.

### Direct class usage
It's also possible to directly access the Repeater class which has been left available as to provide backwards compatibility with older implementations of BlockRepeater. It's not recommended to combine this with the non predefined condition method pattern described above.
```ruby
  Repeater = BlockRepeater::Repeater

  Repeater.new do
    call_database_method
  end.until do |result| 
    expect(result.count).to be_positive, raise 'No result returned from databased'
  end.repeat(delay: 1, times: 5)
```
In this case any optional arguments (`times` or `delay`) must be sent to the method called `repeat`, which is called after the second block. The repeat method is mandatory to run the repeater when using it in this manner.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
