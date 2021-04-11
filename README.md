# ch_digest

A custom tool for digesting exported data from Clubhouse for use by Shōgun.

## Ruby Requirements

This program was tested with Ruby 2.5.3 and should work with any Ruby 2.x version and likely with later versions.

## Running

Use a Ruby interpreter (2.5.3 or later) to run the file `ch_digest.rb`, passing it the source and destination file paths as command line arguments.  This program uses only Ruby Core and Standard Library components and does not require the installation of any additional gems.

## Testing

The testing environment uses [Bundler](https://bundler.io/) to ensure a reliable testing environment.  If you do not already have it installed, please install it with `gem install bundler`.

To install the gems used in testing, please run `bundle install`.

To test, run `rake` (or `rake spec`).
