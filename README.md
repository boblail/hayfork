# Hayfork

[![Gem Version](https://badge.fury.io/rb/hayfork.svg)](https://rubygems.org/gems/hayfork)
[![Build Status](https://travis-ci.org/boblail/hayfork.svg)](https://travis-ci.org/boblail/hayfork)

Full-Text search for ActiveRecord and Postgres.

Hayfork generates triggers to maintain a **Haystack** of all searchable fields that Postgres can index easily and efficiently.



<br/>

## About

##### How Hayfork works

You define the tables and fields to be watched. Hayfork defines triggers that watch those tables for INSERTs, UPDATEs, and DELETEs. In response, the triggers insert, update, or delete corresponding rows in the haystack: one row per searchable field.

They Haystack has a column named `search_vector` that can be indexed, optimizing searches.

Note that a query against the Haystack returns a list of **hits** — one result may have more than one hit (as when a search string is found in both the text and title of a book).


##### Why Hayfork?

Hayfork is designed to:

 - optimize searches by:
    - executing one query to search any number of fields or tables
    - writing `search_vector` when hits are inserted so that the column may be indexed
 - rebuild the haystack at the database level so that it works with bulk-inserted records
 - support extension so, by adding metadata to a hit, you can:
    - provide additional context about a result in the UI
    - search only within a particular field (e.g. enable users to search `author:Potok` to find books whether the author's name includes "Potok")
    - scope searches by a user or tenant or feature


<br/>

## Setup

Generate a haystack table and model for your application.

    $ rails generate hayfork:haystack

This will generate several files:

 - `app/models/haystack.rb` and `db/migrate/000_create_haystack.rb` define the Haystack
 - `app/models/query.rb` (and several models in the `Query` namespace) are responsible for parsing a query string and constructing the SQL to execute it.
 - `lib/haystack_triggers.rb` is where you will define the tables and fields to be added to the Haystack.


<br/>

## lib/haystack_triggers.rb

#### Basic Example

This basic example allows you to search all your employees and projects with one search box:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Employee) do
    insert(:full_name)
  end
  foreach(Project) do
    insert(:title)
  end
end
```

<br/>

#### Multiple Fields

To allow finding employees by multiple traits (e.g by name, job title, or short biography), you can define multiple `insert` statements per employee:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Employee) do
    insert(:full_name)
    insert(:position)
    insert(:short_bio)
  end
end
```

<br/>

#### Scoping Searches

Additional columns on `haystack` can also be useful for scoping searches. Suppose we're maintaining a database of employees for multiple companies. We would want to scope searches by company. If we've added `company_id` to our haystack, we can populate it like this:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Employee) do
    set :company_id, row[:company_id]

    insert(:full_name)
    insert(:position)
    insert(:short_bio)
  end
end
```

In this line,

```ruby
    set :company_id, row[:company_id]
```

1. `row` is an instance of `Arel::Table` that represents the row passed to the trigger; `row` is present in every `foreach` block.
2. `set` assigns a value that will be inserted in the haystack for all following `insert` statements.

<br/>

#### belongs_to

If a book `belongs_to :author`, you can find the book by _either_ its title or its author's name like this:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Book) do
    insert(:title)
    insert(author: :name)
  end
end
```

When a book is inserted, this will add an entry to the haystack for the book's title and another entry for its author's name. If `book.author_id` is changed, it'll replace the appropriate entry in the haystack; but what if `authors.name` is modified? We also need to watch the `authors` table for changes to modify the haystack:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Book) do
    insert(:title)
    insert(author: :name)
  end
  foreach(Author) do
    joins :books
    set :search_result_type, "Book"
    set :search_result_id, Book.arel_table[:id]

    insert(:name)
  end
end
```

In the examples seen before, we haven't set `search_result_type` and `search_result_id`. If these values aren't defined, Hayfork assumes that the model passed to `foreach` — the table being watched — is the search result; but for an associated record, we need to explicitly declare the result. In this case, an entry is added to the haystack for every book that belongs to an author.

<br/>

#### has_many

`has_many` and `has_many :through` associations work much the same way. If an article `has_many :comments`, you can find an article by any of its comments like this:

```ruby
Hayfork.maintain(Haystack) do
  foreach(Article) do
    insert(comments: :text)
  end
  foreach(Comment) do
    joins :article
    set :search_result_type, "Article"
    set :search_result_id, Article.arel_table[:id]

    insert(:text)
  end
end
```

<br/>

#### Rebuild Triggers

After making changes to `lib/haystack_triggers.rb` or to the default scopes of any of the models being used by the Triggers File, you'll need to replace the triggers in your database and rebuild the Haystack. Hayfork generates a migration to do that:

    $ rails generate hayfork:rebuild



<br/>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

<br/>

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cph/hayfork.

<br/>

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
