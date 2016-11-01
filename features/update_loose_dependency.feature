Feature: Update loose dependency

  As a developer
  In order to avoid needless work
  I want Bundler AutoUpdate to check the currently locked version

  Background:
    Given a gem 'foo' at version 0.0.2
    And a gem 'foo' at version 0.0.4
    And a Gemfile specifying:
    """
    gem 'foo', '~> 0.0.2'
    """
    When I run `bundle update`
    Then the output should contain "foo 0.0.4"
    Then the output should contain "updated!"
    When I run `git init`
    When I run `git add .`
    When I run `git commit -a -m "Initial Commit"`

  Scenario: Auto Update with succeeding custom command
    When I run `bundle-auto-update -c echo Hello`
    Then the output should contain:
      """
      Updating foo
        - Current gem already at latest patch version. Passing this update
      """
