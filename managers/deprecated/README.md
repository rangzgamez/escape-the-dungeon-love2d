# Deprecated Managers

This directory contains deprecated manager implementations that were previously used in the game.

## Why Deprecated?

These implementations have been replaced by the new ECS-based systems located in the `lib/ecs/systems` directory. The new systems are more tightly integrated with the ECS architecture and provide better performance and flexibility.

## Files

- `collisionManager.lua`: The old collision detection system, replaced by `lib/ecs/systems/collisionSystem.lua`

## Migration

If you have code that still uses these deprecated implementations, you should migrate to the new ECS-based systems. See the documentation in `docs/ecs-architecture.md` and `docs/ecs-collision-system.md` for more information on how to use the new systems.

## Historical Reference

These files are kept for historical reference and may be removed in future versions of the game. 