const { createGamePass } = require('./roblox_api');

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log("Usage: node tools/monetization/create_gamepass.js <name> <priceInRobux> [description]");
        console.log("Example: node tools/monetization/create_gamepass.js \"VIP Pass\" 299 \"Grants VIP perks and exclusive coin skins\"");
        process.exit(1);
    }

    const name = args[0];
    const price = parseInt(args[1], 10);
    const description = args[2] || "";

    console.log(`Creating GamePass '${name}' for ${price} Robux...`);
    await createGamePass(name, description, price);
}

main();
