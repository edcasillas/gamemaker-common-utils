# Singleton

`Singleton` provides one small Create-event helper for persistent manager
objects that must exist only once.

## Quickstart

Use `gmcu_singleton()` at the top of an object's Create event:

```gml
// Destroy later duplicates and keep the surviving instance persistent.
if (gmcu_singleton()) {
	return;
}
```

After that guard returns false, continue normal initialization:

```gml
if (gmcu_singleton()) {
	return;
}

queue = ds_list_create();
```

## Resources

- `scripts/gmcu_singleton`

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Core`](core.md) | Supplies safe object-name diagnostics. |
| [`Logging`](logging.md) | Reports duplicate singleton instances through `gmcu_log_warn`. |

## API

| Item | Kind | Description |
| --- | --- | --- |
| `gmcu_singleton()` | Function | Destroys later duplicates of the current object, logs the duplicate, and marks the surviving instance as persistent. |

## Notes

This helper is intentionally simple. It is appropriate for manager/controller
objects whose singleton behavior is part of their identity.

If an object should not be persistent, or if duplicate handling needs different
policy, do not force that behavior through this helper.

## Contributing

Keep `scripts/gmcu_singleton/gmcu_singleton.yy` as the local consumer path and
symlink its folder to Common Utils.
