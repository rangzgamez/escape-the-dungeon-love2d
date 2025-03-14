# Deprecated Spatial Partitioning Implementations

This directory contains deprecated spatial partitioning implementations that were previously used in the game.

## Why Deprecated?

These implementations have been replaced by the new ECS-based spatial partitioning system located at `lib/ecs/spatialPartition.lua`. The new system is more tightly integrated with the ECS architecture and provides better performance and flexibility.

## Files

- `spatialHash.lua`: The old spatial hash grid implementation
- `quadtree.lua`: A quadtree implementation that was not fully integrated

## Migration

If you have code that still uses these deprecated implementations, you should migrate to the new ECS-based spatial partitioning system. See the documentation in `docs/spatial_partitioning.md` for more information on how to use the new system.

## Historical Reference

These files are kept for historical reference and may be removed in future versions of the game. 