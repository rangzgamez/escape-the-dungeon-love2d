# Entity System Deprecation Plan

This document outlines the plan for deprecating the old entity system in favor of the new Entity Component System (ECS) architecture.

## Timeline

| Phase | Description | Estimated Completion |
|-------|-------------|----------------------|
| 1 | Initial ECS Implementation | Completed |
| 2 | Player ECS Implementation | Completed |
| 3 | Basic Entity Migration | 2 weeks |
| 4 | Manager Updates | 2 weeks |
| 5 | Full Integration | 2 weeks |
| 6 | Testing & Refinement | 2 weeks |
| 7 | Legacy Code Removal | 1 week |

## Phase 1: Initial ECS Implementation (Completed)

- ✅ Create basic ECS architecture
- ✅ Implement core systems (Collision, Physics, Render)
- ✅ Create ECSEntity base class
- ✅ Set up Bridge module for compatibility

## Phase 2: Player ECS Implementation (Completed)

- ✅ Create PlayerECS class
- ✅ Implement player movement and controls
- ✅ Add collision handling
- ✅ Test in isolated environment

## Phase 3: Basic Entity Migration

- [ ] Create ECS versions of all remaining entities:
  - [ ] EnemyECS (with variants)
  - [ ] ProjectileECS
  - [ ] PowerupECS
  - [ ] TriggerECS
  - [ ] HazardECS
- [ ] Update EntityFactoryECS to create all entity types
- [ ] Test each entity type in isolation

## Phase 4: Manager Updates

- [ ] Update EnemyManager to work with ECS entities
- [ ] Update CollisionManager to use ECS collision system
- [ ] Update ParticleManager for ECS compatibility
- [ ] Update World manager to handle ECS entities
- [ ] Update Camera to work with ECS entities

## Phase 5: Full Integration

- [ ] Update main game loop to use ECS world
- [ ] Integrate ECS entities into level loading
- [ ] Update UI to work with ECS components
- [ ] Implement save/load system for ECS entities
- [ ] Update event system to handle ECS entities

## Phase 6: Testing & Refinement

- [ ] Test all game systems with ECS entities
- [ ] Benchmark performance
- [ ] Fix any compatibility issues
- [ ] Optimize ECS systems
- [ ] Update documentation

## Phase 7: Legacy Code Removal

- [ ] Mark old entity classes as deprecated
- [ ] Remove references to old entity system
- [ ] Clean up unused code
- [ ] Final testing

## Deprecation Notices

Starting in Phase 3, the following classes will be marked as deprecated:

```lua
-- @deprecated Use PlayerECS instead
local Player = require("entities/player")

-- @deprecated Use EnemyECS instead
local Enemy = require("entities/enemy")

-- @deprecated Use PlatformECS instead
local Platform = require("entities/platform")
```

## Compatibility Layer

During the transition, a compatibility layer will be maintained to ensure that existing code continues to work:

1. The Bridge module will handle conversion between old and new entities
2. Managers will support both entity types
3. Events will include both old and new entity references

## Potential Issues

1. **Save/Load Compatibility**: Saved games may need conversion between formats
2. **Performance Impact**: Initial implementation may have performance overhead
3. **Plugin Compatibility**: Third-party plugins may need updates

## Fallback Plan

If critical issues are encountered, we can:

1. Revert to the old entity system for specific entity types
2. Maintain dual implementations for problematic areas
3. Extend the transition period for specific components

## Documentation

Throughout the transition, the following documentation will be maintained:

1. ECS Migration Guide
2. Component Reference
3. System Reference
4. Troubleshooting Guide

## Conclusion

By following this plan, we will gradually transition from the old entity system to the new ECS architecture, ensuring a smooth migration with minimal disruption to development and gameplay. 