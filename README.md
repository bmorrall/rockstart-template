# bmorrall/rockstart-template

## Installation

*Optional.*

To make this the default Rails application template on your system, create a `~/.railsrc` file with these contents:

```
-d postgresql
-m https://raw.githubusercontent.com/bmorrall/rockstart-template/main/template.rb
```

## Usage

This template assumes you will store your project in a remote git repository (e.g. Bitbucket or GitHub) and that you will deploy to a production environment. It will prompt you for this information in order to pre-configure your app, so be ready to provide:

1. The git URL of your (freshly created and empty) Bitbucket/GitHub repository
2. The hostname of your production server

To generate a Rails application using this template, pass the `-m` option to `rails new`, like this:

```
rails new blog \
  -d postgresql \
  -m https://raw.githubusercontent.com/bmorrall/rockstart-template/main/template.rb \
  --skip-test
```

*Remember that options must go after the name of the application.* The only database supported by this template is `postgresql`.

If you’ve installed this template as your default (using `~/.railsrc` as described above), then all you have to do is run:

```
rails new blog
```

## What is included?

#### These gems are added to the standard Rails stack

* Core
    * [high_voltage][] - for static pages
* Configuration
    * [dotenv][] – for local configuration
* Utilities
    * [rubocop][] – enforces Ruby code style
* Security
    * [brakeman][] and [bundler-audit][] – detect security vulnerabilities
* Testing
    * [shoulda][] – shortcuts for common ActiveRecord tests

[dotenv]:https://github.com/bkeepers/dotenv
[high_voltage]:https://github.com/thoughtbot/high_voltage
[rubocop]:https://github.com/bbatsov/rubocop
[brakeman]:https://github.com/presidentbeef/brakeman
[bundler-audit]:https://github.com/rubysec/bundler-audit
[shoulda]:https://github.com/thoughtbot/shoulda
