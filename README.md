# Tmpgem

Tmpgem is a temporary gem installer.

## What's this?

You install a gem by `rake install:local` when you develop the gem.
But the way has a problem. The way changes installed gem.

```bash
$ cd your/gem/dir/
# Editing code
$ vim lib/yourgem.rb
$ bundle exec rake install:local

# Checking yourgem behaviour
$ yourgem --some-option

# Run other gem that uses the yourgem as a library.
$ awesome-yourgem --foobar # => It run with changed yourgem!
```

If you add `binding.pry` to yourgem, the `awesome-yourgem` command executes pry. It is an unexpected behaviour.
You should restore original yourgem to prevent this bug.


This gem installs and restores a gem automatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tmpgem'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tmpgem

## Usage

```bash
$ cd your/gem/dir/
# Edit gem source code
$ tmpgem
tmpgem-0.1.0.gem is installed temporary. Please CTRL-C when you do not need this gem.
# You can use the edited gem until CTRL-C.
^C
Restoring the gem...
tmpgem is restored!

# You can use the original gem.
```
