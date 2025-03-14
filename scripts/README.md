# Scripts

This directory contains utility scripts for the Escape the Dungeon game.

## Available Scripts

### migrate_entity.sh

A shell script to help with migrating traditional entities to ECS entities.

#### Usage

```
./scripts/migrate_entity.sh <entity_name>
```

Example:

```
./scripts/migrate_entity.sh player
```

This will create a new file at `entities/playerECS.lua` based on `entities/player.lua`.

The script creates a template for the ECS entity with placeholders for components and methods. You'll need to edit the file to implement the entity-specific logic.

#### How It Works

1. The script checks if the source file exists.
2. It creates a template for the ECS entity with the following:
   - Basic entity structure
   - Type component
   - Renderer component
   - Collision component (if needed)
   - Placeholder methods for update, draw, and onCollision
3. It writes the template to the target file.

#### Tips for Using the Script

1. Run the script from the root directory of the project.
2. After generating the template, review and edit the file to implement the entity-specific logic.
3. Use the existing ECS entity implementations as references.
4. Test the new ECS entity in isolation before integrating it into the main game.

### migrate_entity.lua (Deprecated)

A Lua script with the same functionality as migrate_entity.sh. This script is deprecated and may not work on all systems.

#### Usage

```
lua migrate_entity.lua <entity_name>
```

Example:

```
lua migrate_entity.lua player
```

This will create a new file at `entities/playerECS.lua` based on `entities/player.lua`.

The script creates a template for the ECS entity with placeholders for components and methods. You'll need to edit the file to implement the entity-specific logic.

#### How It Works

1. The script checks if the source file exists.
2. It creates a template for the ECS entity with the following:
   - Basic entity structure
   - Type component
   - Renderer component
   - Collision component (if needed)
   - Placeholder methods for update, draw, and onCollision
3. It writes the template to the target file.

#### Tips for Using the Script

1. Run the script from the root directory of the project.
2. After generating the template, review and edit the file to implement the entity-specific logic.
3. Use the existing ECS entity implementations as references.
4. Test the new ECS entity in isolation before integrating it into the main game.

## Adding New Scripts

When adding new scripts to this directory, please follow these guidelines:

1. Make the script executable (`chmod +x script_name.lua`).
2. Add a description of the script to this README.
3. Include usage instructions and examples.
4. Document any dependencies or requirements. 