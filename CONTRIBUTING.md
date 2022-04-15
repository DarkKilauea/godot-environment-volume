# Guidelines for contributing

Thanks for your interest in contributing! Before contributing, be sure to know
about these few guidelines:

- Follow the
  [GDScript style guide](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_styleguide.html).
- Use [GDScript static typing](https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/static_typing.html) whenever possible.
  - Also use type inference whenever possible (`:=`) for more concise code.
- Make sure to update the changelog for any user-facing changes, keeping the
  [changelog format](http://keepachangelog.com/en/1.0.0/) in use.
- Don't bump the version yourself. Maintainers will do this when necessary.
- Try to keep your PRs as specific as possible.  The larger the PR, the more time it will take to approve (and the greater chance it may be rejected).

## Design goals

This add-on aims to:

- Provide a quick and easy way to apply particular environment settings to parts of a scene.

## Non-goals

For technical or simplicity reasons, this add-on has no plans to:

- Replace existing Godot nodes for configuring environment settings, such as `WorldEnvironment`.
