const { updateGamePass } = require('./roblox_api');

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log("Usage: node tools/monetization/update_gamepass.js <gamePassId> --price=<price> --name=<name> --desc=<description> --sale=<true|false>");
        console.log("Example: node tools/monetization/update_gamepass.js 87654321 --price=199");
        process.exit(1);
    }

    const gamePassId = args[0];
    const updates = {};

    for (let i = 1; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith('--price=')) updates.price = parseInt(arg.split('=')[1], 10);
        if (arg.startsWith('--name=')) updates.name = arg.split('=')[1];
        if (arg.startsWith('--desc=')) updates.description = arg.split('=')[1];
        if (arg.startsWith('--sale=')) updates.isForSale = arg.split('=')[1] === 'true';
    }

    console.log(`Updating GamePass ${gamePassId}...`, updates);
    await updateGamePass(gamePassId, updates);
}

main();
