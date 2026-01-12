# ActionManager - Godot 4.5 Advanced Input Manager

![icon](screenshots/icon_400.png)

## Overview

**ActionManager** is an advanced input manager for Godot 4.5 that provides:

- Long press and long press hold
- Double tap
- Action toggle and oneshot
- Configurable input repetition
- Action or group blocking
- Manual input injection (UI, touch, replay, AI)
- Signals for mouse, keyboard, and gamepad events

It offers a unified API for reliable input handling with full state control. It automatically respects **device-specific Input Actions** configured in Godot.

---

## Signals

| Signal                                             | Description                         |
| -------------------------------------------------- | ----------------------------------- |
| `all_event(event: InputEvent)`                     | Emitted for any input event.        |
| `mouse_motion_event(event: InputEventMouseMotion)` | Emitted for mouse motion events.    |
| `mouse_button_event(event: InputEventMouseButton)` | Emitted for mouse button events.    |
| `key_event(event: InputEventKey)`                  | Emitted for keyboard key events.    |
| `joy_button_event(event: InputEventJoypadButton)`  | Emitted for joystick button events. |
| `joy_motion_event(event: InputEventJoypadMotion)`  | Emitted for joystick motion events. |

---

## Public Properties

| Property          | Type  | Default | Description                                         |
| ----------------- | ----- | ------- | --------------------------------------------------- |
| `long_press_time` | float | 0.5     | Time in seconds required for a long press.          |
| `double_tap_time` | float | 0.25    | Maximum time between taps to register a double tap. |
| `repeat_delay`    | float | 0.8     | Delay before action repeat starts.                  |
| `repeat_interval` | float | 0.8     | Interval between repeated action triggers.          |

---

## Usage Examples

### Basic Action Checks

```gdscript
if action_manager.get_action_pressed("jump"):
    print("Jump button pressed")

if action_manager.get_action_oneshot("shoot"):
    fire_weapon()

if action_manager.get_action_long_press("run"):
    start_sprinting()

if action_manager.get_action_double_tap("dash"):
    perform_dash()
```

### Toggle and Repeat Actions

```gdscript
if action_manager.get_action_toggle("flashlight"):
    toggle_flashlight()

if action_manager.get_action_repeat("fire"):
    fire_bullet()

action_manager.set_action_repeat("fire", 0.5, 0.1)  # custom delay & interval
```

### Blocking Actions

```gdscript
action_manager.block_action("jump")
action_manager.unblock_action("jump")

# Groups
action_manager.register_action_group("movement", ["left", "right", "up", "down"])
action_manager.block_group("movement")
action_manager.unblock_group("movement")
```

### Manual Input Injection

```gdscript
action_manager.inject_action("jump", true)   # press action
action_manager.inject_action("jump", false)  # release action
```

### Getting Axis or Vector

```gdscript
# Vector2 from actions
var move_vec = action_manager.get_vector("left", "right", "up", "down", 0.2)

# Single axis (horizontal)
var horizontal = action_manager.get_axis("left", "right", 0.15)
```

### Resetting Actions

```gdscript
action_manager.reset_action("jump")
action_manager.reset_all(true)  # also clears repeat config
```

---

## API Reference

| Method                                                                   | Arguments                   | Return Type | Description                                             |
| ------------------------------------------------------------------------ | --------------------------- | ----------- | ------------------------------------------------------- |
| `get_action_pressed(action: StringName)`                                 | action                      | bool        | Returns true while the action is pressed.               |
| `get_action_hold(action: StringName)`                                    | action                      | bool        | Same as `get_action_pressed`.                           |
| `get_action_oneshot(action: StringName)`                                 | action                      | bool        | Returns true only once until next press.                |
| `get_action_toggle(action: StringName)`                                  | action                      | bool        | Toggles true/false each press.                          |
| `get_action_long_press(action: StringName)`                              | action                      | bool        | Returns true once when a long press is detected.        |
| `get_action_long_press_hold(action: StringName)`                         | action                      | bool        | Returns true while the button is held after long press. |
| `get_action_double_tap(action: StringName)`                              | action                      | bool        | Returns true once if a double tap occurs.               |
| `get_action_repeat(action: StringName)`                                  | action                      | bool        | Returns true repeatedly after repeat delay & interval.  |
| `set_action_repeat(action: StringName, delay: float, interval: float)`   | action, delay, interval     | void        | Configure custom repeat for an action.                  |
| `inject_action(action: StringName, pressed: bool)`                       | action, pressed             | void        | Manually inject press/release events.                   |
| `set_input_enabled(enabled: bool)`                                       | enabled                     | void        | Enables or disables input globally.                     |
| `block_action(action: StringName)`                                       | action                      | void        | Blocks a specific action.                               |
| `unblock_action(action: StringName)`                                     | action                      | void        | Unblocks a specific action.                             |
| `register_action_group(group: StringName, actions: Array[StringName])`   | group, actions              | void        | Registers a group of actions.                           |
| `block_group(group: StringName)`                                         | group                       | void        | Blocks all actions in the group.                        |
| `unblock_group(group: StringName)`                                       | group                       | void        | Unblocks all actions in the group.                      |
| `clear_action_repeat(action: StringName)`                                | action                      | void        | Clears custom repeat config.                            |
| `reset_action(action: StringName)`                                       | action                      | void        | Resets action state.                                    |
| `reset_all(reset_actions_repeat_config: bool = false)`                   | reset_actions_repeat_config | void        | Resets all actions, optionally clears repeat config.    |
| `get_vector(neg_x, pos_x, neg_y, pos_y, dead_zone: float = 0.0)`         | action names                | Vector2     | Returns a normalized vector with deadzone applied.      |
| `get_axis(neg_action, pos_action, dead_zone: float = 0.15)`              | action names                | float       | Returns a float axis value -1.0 to 1.0 with deadzone.   |
| `is_action_just_released(action: StringName, exact_match: bool = false)` | action, exact_match         | bool        | Returns true if action was just released.               |

---

## Notes

- Actions are automatically blocked based on `_blocked_actions` and `_blocked_groups`.
- Long press and double tap timers are handled internally.
- `get_vector` and `get_axis` respect the deadzone.
- Manual injection is useful for AI, replays, or touch UI.
- Signals allow hooking directly into input events if needed.
- **Device filtering** is handled by Godot InputMap, no manual filtering is required in ActionManager.

---

## Example: Movement

```gdscript
var velocity := Vector2.ZERO
velocity = action_manager.get_vector("left", "right", "up", "down", 0.2)
move_character(velocity)
```

## Example: Shooting with Repeat

```gdscript
if action_manager.get_action_repeat("shoot"):
    fire_bullet()
```

---

!["screenshot 1](screenshots/1.png)

---

ActionManager provides a **robust, unified input API** for complex games, handling both simple presses and advanced actions like repeat, long press, and double tap.
