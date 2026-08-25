const { createDeveloperProduct } = require('./roblox_api');

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log("Usage: node tools/monetization/create_product.js <name> <priceInRobux> [description]");
        console.log("Example: node tools/monetization/create_product.js \"100 Coins\" 49 \"Instantly gives 100 Coins\"");
        process.exit(1);
    }

    const name = args[0];
    const price = parseInt(args[1], 10);
    const description = args[2] || "";

    console.log(`Creating Developer Product '${name}' for ${price} Robux...`);
    await createDeveloperProduct(name, description, price);
}

main();
