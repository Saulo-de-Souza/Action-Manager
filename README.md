# Action Manager

`Action Manager` is an advanced input manager for Godot 4.5 that provides:

- Long press and long press hold
- Double tap
- Action toggle and oneshot
- Configurable input repetition
- Action or group blocking
- Manual input injection (UI, touch, replay, AI)
- Signals for mouse, keyboard, and gamepad events

It offers a unified API for reliable input handling with full state control.

---

## ⚠️ Important Note about Long Press, Double Tap, and Repeat

The following methods:

- `get_action_long_press()`
- `get_action_double_tap()`
- `get_action_repeat()`

**consume the event**, meaning calling the getter resets the state.

If you call them multiple times in the same frame:

```gdscript
if input_manager.get_action_long_press("ui_up"):
    do_something()
if input_manager.get_action_long_press("ui_up"):
    do_something_else()
```

The second `if` will **not trigger**, because the first call already consumed the event.

✅ Correct usage:

```gdscript
var lp = input_manager.get_action_long_press("ui_up")
if lp:
    do_something()
if lp:
    do_something_else()
```

---

## Signals

| Signal                                       | Event                                   |
| -------------------------------------------- | --------------------------------------- |
| `unhandled_input(event: InputEvent)`         | Captures any unhandled input from Godot |
| `mouse_motion(event: InputEventMouseMotion)` | Mouse movement                          |
| `mouse_button(event: InputEventMouseButton)` | Mouse button clicks                     |
| `key(event: InputEventKey)`                  | Keyboard keys                           |
| `joy_button(event: InputEventJoypadButton)`  | Gamepad buttons                         |
| `joy_motion(event: InputEventJoypadMotion)`  | Gamepad movement                        |

---

## Configuration

- `long_press_time: float = 0.5` → Minimum time for long press
- `double_tap_time: float = 0.25` → Maximum interval between taps for double tap
- `repeat_delay: float = 0.8` → Delay before repeat starts
- `repeat_interval: float = 0.8` → Interval between repeated actions

---

## Main API

### ## get_action_pressed(action: StringName) -> bool

Returns `true` while the action is being pressed.
Does not consume the event.

```gdscript
if input_manager.get_action_pressed("ui_up"):
    print("Holding up")
```

---

### ## get_action_hold(action: StringName) -> bool

Identical to `get_action_pressed()`. Returns `true` while pressed.

---

### ## get_action_oneshot(action: StringName) -> bool

Returns `true` only once, when the action is first pressed.
The state is consumed when calling the getter.

```gdscript
if input_manager.get_action_oneshot("ui_accept"):
    print("Pressed once")
```

---

### ## get_action_toggle(action: StringName) -> bool

Toggles between `true` and `false` each time the action is pressed.
State is **not automatically consumed**.

```gdscript
if input_manager.get_action_toggle("ui_up"):
    print("Toggled ON")
else:
    print("Toggled OFF")
```

---

### ## get_action_long_press(action: StringName) -> bool

Returns `true` once when the action exceeds `long_press_time`.
State is consumed when calling the getter.

```gdscript
var lp = input_manager.get_action_long_press("ui_up")
if lp:
    print("Long press detected")
```

### ## get_action_long_press_hold(action: StringName) -> bool

Returns `true` while the key is held after reaching `long_press_time`.
State is **not consumed** automatically.

```gdscript
if input_manager.get_action_long_press_hold("ui_up"):
    print("Holding long press")
```

---

### ## get_action_double_tap(action: StringName) -> bool

Returns `true` if the action was pressed twice quickly within `double_tap_time`.
State is consumed when calling the getter.

```gdscript
if input_manager.get_action_double_tap("ui_up"):
    print("Double tap!")
```

---

### ## get_action_repeat(action: StringName) -> bool

Returns `true` at configurable intervals (`repeat_delay` + `repeat_interval`).
State is consumed when calling the getter.

```gdscript
input_manager.set_action_repeat("ui_up", 0.5, 0.2)
if input_manager.get_action_repeat("ui_up"):
    print("Repeating action")
```

---

### ## inject_action(action: StringName, pressed: bool)

Manually inject input (UI, touch, AI, replay).

```gdscript
input_manager.inject_action("ui_up", true)  # Press
input_manager.inject_action("ui_up", false) # Release
```

---

### ## Action Blocking

```gdscript
input_manager.block_action("ui_up")   # Block specific action
input_manager.unblock_action("ui_up") # Unblock
input_manager.register_action_group("movement", ["ui_up", "ui_down"])
input_manager.block_group("movement")
input_manager.unblock_group("movement")
```

---

### ## Reset

```gdscript
input_manager.reset_action("ui_up")  # Reset a single action
input_manager.reset_all()             # Reset all actions
```
