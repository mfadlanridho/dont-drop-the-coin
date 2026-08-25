const { listGamePasses } = require('./roblox_api');

async function main() {
    console.log("Fetching Game Passes...");
    const passes = await listGamePasses();
    if (passes) {
        console.log("\n=== GAME PASSES ===");
        console.log(JSON.stringify(passes, null, 2));
    }
}

main();
