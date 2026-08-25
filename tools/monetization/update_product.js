const { updateDeveloperProduct } = require('./roblox_api');

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log("Usage: node tools/monetization/update_product.js <productId> --price=<price> --name=<name> --desc=<description> --sale=<true|false>");
        console.log("Example: node tools/monetization/update_product.js 12345678 --price=99");
        process.exit(1);
    }

    const productId = args[0];
    const updates = {};

    for (let i = 1; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith('--price=')) updates.price = parseInt(arg.split('=')[1], 10);
        if (arg.startsWith('--name=')) updates.name = arg.split('=')[1];
        if (arg.startsWith('--desc=')) updates.description = arg.split('=')[1];
        if (arg.startsWith('--sale=')) updates.isForSale = arg.split('=')[1] === 'true';
    }

    console.log(`Updating Developer Product ${productId}...`, updates);
    await updateDeveloperProduct(productId, updates);
}

main();
