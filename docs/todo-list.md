# Vertical Jumper - Development TODO List

## High Priority Tasks

### Code Organization
- [ ] Create folder structure according to project documentation
- [ ] Move files into appropriate directories
- [ ] Create `conf.lua` file for Love2D settings
- [ ] Add license file (MIT recommended)

### Bug Fixes & Optimizations
- [ ] Fix `refreshJumps()` references in player states (currently using `refreshDash()`)
- [ ] Review collision handling to prevent falling through platforms at high speeds
- [ ] Optimize particle system management (object pooling)
- [ ] Fix bat wing scaling issues in `bat.lua`

### Core Features
- [ ] Add basic menu system (start game, settings, credits)
- [ ] Implement proper game over screen with restart option
- [ ] Create simple tutorial for new players
- [ ] Add basic sound effects and background music

## Medium Priority Tasks

### Game Enhancement
- [ ] Add more enemy types (slime, bird, etc.)
- [ ] Implement power-up system (health, extra jumps, temporary abilities)
- [ ] Add breakable platforms
- [ ] Create moving/floating platforms
- [ ] Implement simple background parallax effect

### Visual Polish
- [ ] Replace rectangle graphics with proper sprites
- [ ] Add animation system for player and enemies
- [ ] Improve particle effects
- [ ] Add screen transitions
- [ ] Implement HUD improvements (health bar, combo meter)

### User Experience
- [ ] Add settings persistence
- [ ] Implement high score system
- [ ] Add achievement system
- [ ] Create more feedback for player actions (screen shake, flash effects)
- [ ] Improve touch controls responsiveness

## Low Priority / Future Enhancements

### Content Expansion
- [ ] Create boss enemy encounters
- [ ] Design level progression system
- [ ] Add themed zones with different visuals
- [ ] Implement story elements
- [ ] Create special challenge modes

### Advanced Features
- [ ] Add character customization
- [ ] Implement online leaderboards
- [ ] Create daily challenges
- [ ] Add social sharing features
- [ ] Design achievement system

### Technical Improvements
- [ ] Upgrade to newer Love2D features
- [ ] Create better documentation with LuaDoc
- [ ] Implement automated testing
- [ ] Support for additional platforms
- [ ] Optimize for various screen sizes

## Project Management
- [ ] Set up version control (if not already done)
- [ ] Create proper release builds
- [ ] Write contribution guidelines
- [ ] Plan update roadmap
- [ ] Prepare for distribution/publishing

## Notes
- Remember to continuously test on both desktop and mobile targets
- Consider getting early feedback from playtesters
- Balance difficulty progression carefully
- Focus on core gameplay feel before expanding features