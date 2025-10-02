# Contribution guidelines

## Pull Requests

Give descriptive names to PR branches, e.g. `spawn-trigger-crash-fix` instead of `fix`.
This also goes for PR names.
Group PRs by topic, e.g. a single feature or a fix.

## Scripts

### Style guide

Follow [Godot's GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
Unfortunately, Godot doesn't come with a formatter or a linter, so if you see code that isn't formatted correctly, feel free to open a PR.

Give scripts class names unless you're sure you won't need to refer to it and it won't have more than 1 instance.

Avoid node paths that go up in the hierarchy, e.g. `^"../../Node"` (the worst offender is a "grandparent" path like `^"../.."` which doesn't tell anything about what the referred node actually is).
Instead, use references stored in exported variables, e.g. `@export var side_panel: PanelContainer`.
If the script is only meant to be instantiated from code, use a public variable and initialize it in `_init`, e.g.

```gdscript
# from AddKeybindButton.gd
var keybind_loader: KeybindLoader


func _init(_keybind_loader: KeybindLoader) -> void:
	keybind_loader = _keybind_loader
```

If the class is only there to categorize subclasses, [mark it as `@abstract`](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#abstract-classes-and-methods).

Connect signals from code using `signal.connect(function)` (`Signal.connect()`) instead of `connect("signal", function)` (`Node.connect()`).

### Commented-out code

Don't include code that's commented out in PRs.

### File naming conventions

Name folders in `snake_case` and files and scripts in `PascalCase`.
