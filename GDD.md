**📝 THE FINAL GAME DESIGN DOCUMENT (GDD)**

**Project Title:** Don't Drop The Coin\! *(Working Title)*  
**Genre:** Physics-Based Vertical Simulator / Chaotic Party Game  
**Platform:** Roblox (Optimized for Mobile/Tablet, compatible with PC & Console)  
**Target Audience:** Demographics aged 7–15

---

**📌 1\. EXECUTIVE SUMMARY & CORE LOOP**

*Don't Drop The Coin\!* is an engineered high-margin monetization engine disguised as a chaotic, physics-driven party simulator \[🏆\]. The game completely rejects complex combat mechanics in favor of a zero-skill, highly addictive visual progression loop built on three primal player motives: **Greed, Vanity, and Revenge.**

**The 4-Step Core Loop:**

1. **Gather:** Players traverse a single, massive vertical tower collecting floating coins/gems.

2. **Stack:** Collected items dynamically stack in a physical, precariously wobbling pile on top of the player's head.

3. **Dodge & Grief:** Players must dodge environmental traps, AI monsters, and other players who are actively trying to bump them to steal their progress.

4. **Bank:** Players must physically navigate back down to the ground-floor "Safe Zone Bank" to cash in their unstable stack for permanent leaderboard currency.

---

**🗺️ 2\. WORLD ARCHITECTURE & ZONE DESIGN**

To maximize performance on lower-end mobile devices and fit within a strict **$200 Builder budget**, the entire game takes place within **one single, continuous, vertical tower map.** Players do not teleport to separate servers; everyone plays in the same arena, allowing lower-tier players to watch high-value coin explosions rain down from the sky tiers.

\[ ZONE 3: THE VOID LUNATIC (Sky Tier) \] ──────► 3x Cash Multiplier

       │  • Hazards: Disappearing platforms, "Glitch Drone" AI Hunter Monster.

       ▼

\[ ZONE 2: THE CHAOS FACTORY (Mid Tier) \] ────► 2x Cash Multiplier

       │  • Hazards: Narrow assembly lines, moving Piston Crushers, swinging Pendulums.

       ▼

\[ ZONE 1: THE SUNNY START (Low Tier) \] ──────► 1x Cash Multiplier

       │  • Hazards: Simple jumps, wide platforms, player-vs-player bumps only.

       ▼

\[ GROUND LEVEL: THE CENTRAL LOBBY \] ─────────► 0x Cash (100% Safe Zone)

          • Features: Secure Bank Vault, Gacha Skin Wheels, Roblox Group Loyalty Gate.

---

**🎮 3\. DETAILED MECHANICS & PHYSICS SPECS**

**A. The Spring-Loaded Stacking System**

* **Attachment Engine:** When a player character collides with a floating coin mesh, the server instantiates an item model and snaps it to a dynamic chain attached to the player's character accessory socket.

* **Angular Velocity Control:** The stack uses custom physics constraints (spring and hinge constraints). As the number of items increases, the weight vector shifts upwards. The stack dynamically tilts, sways, and lags behind player movement inputs. A stack of 50 items wobbles drastically, making precise jumping incredibly difficult.

**B. The Combat Mechanic ("The Bump")**

* **Default Ability:** Every player has a permanent, non-lethal "Dash Bump" bound to an on-screen UI button (Mobile) or 'E' key (PC) with a hard 5-second cooldown.

* **Collision Logic:** When a player dashes into an opponent, the game executes a knockback calculation. The distance the victim is launched scales upward based on how tall and top-heavy their coin stack is.

**C. The Ragdoll & Loot Explosion**

* **The Trigger:** Initiated instantly when a player character is struck by another player's Bump, a Zone 2 mechanical hazard, or the Zone 3 AI Monster.

* **Character Action:** The player's standard Roblox avatar humanoid is instantly disabled, forcing them into a completely unanchored **physics ragdoll state** for 2.5 seconds, launching them backwards or downwards off platforms.

* **The Exploding Physics:** The head-stack instantly detaches. Every single item in the stack is converted back into an individual, glowing, unanchored physical coin model that violently scatters and bounces across the local platforms. For 10 seconds, these dropped items can be vacuumed up by any nearby player.

---

**🔊 4\. JUICINESS & DOPAMINE ENGINE (AUDIO & VFX)**

To maximize retention and game addiction metrics, every basic action must trigger extreme sensory feedback.

**A. Sound FX Matrix**

* **Collection Pop:** Gathering a coin plays a crisp, clean, high-pitched *“Ding-Ching\!”* audio track. Consecutive collections within a 3-second window pitch-shift the audio slightly higher per coin, mimicking a rhythmic combo streak.

* **The Mega-Crash:** When a stack explodes, the game plays an intensely loud, chaotic, multi-layered metal impact sound (*“MEGA-CRASH-CLINK\!”*) fused with a cartoonish *“Oof\!”* vocal grunt for the ragdoll launch.

* **The Bank Registry:** Stepping onto the secure banking pad fires a heavy, mechanical antique cash-register bell sound effect (*“KA-CHING\! 🎉”*) accompanied by an upbeat, short stadium crowd cheer audio track.

**B. Visual Effects (VFX) & UI Tweens**

* **The Flash Sparkle:** Every coin addition fires a bright, micro-radial neon particle explosion around the player's head.

* **Screen Shake & Tracers:** Getting hit by a bump triggers a directional camera camera-shake script for the victim. Scattered coins emit vibrant, neon trails as they bounce through space.

* **Elastic UI Scaling:** Any time a player's wallet changes value or a Robux shop prompt opens, the text and UI windows execute an elastic tween scale animation (scaling instantly from 100% to 135% and bouncing smoothly back to 100% size).

---

**💸 5\. AGGRESSIVE MONETIZATION MATRIX (ROBUX TRAPS)**

The monetization strategy intentionally targets extreme emotional spikes: **Panic, Impatience, and Rage.**

* **"Super Glue" Passive Pass (399 Robux):** Permanent gamepass. Permanently modifies the loot explosion script so that 50% of the player's stack remains safely locked to their head upon being wiped out. (Targeting Fear/Loss Aversion).

* **"Nuclear Revenge" Strike (29 Robux):** Dynamic Developer Product. Pop-up appears on the ragdoll defeat screen showing the avatar image of the player who hit them. Clicking it instantly fires an unavoidable, map-wide lightning bolt VFX that ragdolls and explodes that specific player's stack. (Targeting Rage).

* **"Instant Bank" Emergency Teleport (39 Robux):** Dynamic Developer Product. Prompts automatically via UI when a player reaches a stack height greater than 50 items inside high-risk zones. Instantly fades the screen to black and safely moves the player and their entire stack directly into the ground-floor Bank Zone. (Targeting Anxiety).

* **"Mega Dash Range" Pass (249 Robux):** Permanent gamepass. Increases the hit-box radius and velocity of the player's default Bump ability by 100%. (Targeting Griefing/Dominance).

* **Stat-Boosting Gacha Wheels (49 Robux per roll):** Randomized Developer Product. Players spin a wheel to change their default coin models into unique cosmetic items (e.g., *Neon Cats, Rainbow Toilets, Flaming Skulls*). The ultra-rare tier (0.5% drop rate) features embedded asset tags that grant a permanent \+25% player movement speed or \+30% knockback resistance. (Targeting Gambling/Flexing).

---

**👥 6\. RETENTION & ROBLOX GROUP GROWTH CONVERSION**

**A. The Group Loyalty Gate**

To build a massive, permanent community for future game launches, a literal asset wall is placed in the center of the Safe Zone Lobby. A massive, glowing vault door is labeled **"ROBLOX GROUP MEMBERS ONLY."**  
An automated backend script checks the player's profile data against your Roblox Group ID. If verified, the door swings open to grant access to a continuous **\+20% permanent cash value multiplier pad** and a glowing "Fan" chat tag. A prominent 1-click UI button natively prompts the user to join your group without leaving the game client.

**B. The AFK Reward Matrix**

To artificially inflate the game’s concurrent player count—forcing the organic Roblox algorithm to display the game on the front page—players are rewarded purely for keeping the game application open. An on-screen UI timer tracks continuous active session minutes and awards un-duplicatable prizes at specific intervals:

* **5 Minutes:** 250 Base Coins

* **15 Minutes:** 2x Speed Potion (5-minute active duration)

* **30 Minutes:** 1x Free Gacha Skin Wheel Token

* **60 Minutes:** Permanent Exclusive "Clockwork Engine" Stack Skin (Unlocks special visual particle aura).

---

**⏳ 7\. PRODUCTION TIMELINE & MILESTONE BUDGET ROADMAP**

TOTAL BUDGET AVAILABLE: $1,500

ALLOCATION: $750 (Development Phase) | $750 (Launch Marketing Phase)

**🗓️ Week 1: Recruitment, Architecture & Core Tech Setup**

* **Budget Target:** $150 (25% developer deposits)

* **Director Deliverables:** Create the Roblox Group, upload a placeholder game slot, and post job briefs on the Roblox DevForum and Hidden Developers Discord. Interview candidates and demand verified past portfolios demonstrating spring/physics constraints or simulator loops.

* **Technical Milestone:** Formally sign on your **Lead Scripter** and **3D Modeler**. Set up a shared source-control repository.

**🗓️ Week 2: The Greybox Mechanics Prototype**

* **Budget Target:** $150 (Milestone payment upon proof of core mechanics)

* **Director Deliverables:** Log into the private developer studio testing slot and verify performance.

* **Technical Milestone:** The scripter must deliver a functional, bare-bones greybox map. Characters must be able to walk over test parts, generate a stack that wobbles accurately based on directional velocity vectors, deploy a functional "Bump" ability, trigger a flawless character ragdoll, and explode the stack parts cleanly across the floor into a functional "Bank Zone" script.

**🗓️ Week 3: Asset Integration, Audio & Monetization Hooks**

* **Budget Target:** $250 ($100 to 3D Modeler for finished assets, $150 to GFX/UI Freelancer)

* **Director Deliverables:** Hire the GFX/UI artist. Review the 15–20 Gacha stack models created by the modeler.

* **Technical Milestone:** The builder delivers the themed textures for Zone 1, 2, and 3\. The scripter imports all UI layouts, integrates the elastic text tweens, wires up the sound effects matrix, connects the live Roblox Group API verification gate, and binds all Robux gamepasses and Developer Product IDs to the live storefront canvas.

**🗓️ Week 4: Rigid QA Testing & The Weekend Ad Blitz Launch**

* **Budget Target:** $200 (Final developer balance payout) \+ $750 (Pure Marketing Launch Spend)

* **Director Deliverables:** Host intense, closed stress-testing matches with 10–15 players to look for memory leaks, platform lag on mobile devices, or stack clipping bugs. Confirm all backend data-stores save coins perfectly when players log out.

* **Technical Milestone (THE GO-LIVE):** On **Friday at exactly 4:00 PM EST**, change the game's privacy status to Public. Instantly deploy your entire **$750 marketing budget** directly into the Roblox Sponsored Ads and Sponsor Game systems targeting mobile/tablet devices. Monitor server analytics across the 48-hour weekend window as the algorithmic traffic velocity loops kick in.

---

