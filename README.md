# esql

Esql is a library for ActiveRecord scoping using simple expressions.

## Installation

Add this line to your application's Gemfile:

```rb
gem 'esql'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install esql

## Usage

This gem is easy to use: all you need is an ActiveRecord scope and an
expression. The result is a scope with any necessary joins applied, to which
you can use to generate columns, sort results, or apply filters.

One of the primary goals is to allow your applications to unlock the full
power of SQL without having to hard-code queries or fret about SQL injection.

```rb
ast = Esql::Parser.new.parse('concat(first_name, " ", last_name)')
scope, sql = ast.evaluate(Employee.all)
```

Esql is a minimalist gem. A common use case is generating columns using
formulas or aggregates. By default they won't be `SELECT`ed (because you
might want to use your expressions to filter results instead); you will need
to do that yourself. You can monkey patch the following method to allow
adding a new column to your `SELECT` list instead of having to write the
entire list again:

```rb
# Put this in an initializer
module ActiveRecord
  class Relation
    def select_append(*fields)
      fields.unshift(arel_table[Arel.star]) if !select_values.any?
      select(*fields)
    end
  end
end
```

Another great example of how you can use Esql is as a way to support
dynamic queries in your REST APIs:

```rb
class EmployeesController < ApplicationRecord
  # GET /employees?filter[]=...
  def index
    scope = Employee.all
    filters = request.params.fetch('filter', [])
    filters.each { |expr|
      ast = Esql::Parser.new.parse(expr)
      scope, sql = ast.evaluate(scope)
      scope = scope.where(sql)
    }
    render # ...
  end
end
```

Yes, you will receive a raw SQL string when your expression is evaluated.
Esql is basically a SQL transpiler—a memoizing parsing expression grammar is
used behind the scenes to ensure e.g. string literals are always properly
quoted before being inserted into the resulting SQL.

## Expressions

The expression syntax is simple and unopinionated. As a transpiler, Esql
basically defers to SQL's rules. It just provides syntactic sugar for things
like joins and aggregates.

In most cases, Esql can catch issues like improper use of a related
attributes (i.e. attributes of related records). It does this by evaluating
the ActiveRecord reflections, so you will need to make sure you properly
define your relationships in your model classes.

Errors that get past this simple check layer (like type mismatches or even
query runtime errors) will bubble up as ActiveRecord exceptions that you'll
have to handle yourself.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/paulholden2/esql.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
