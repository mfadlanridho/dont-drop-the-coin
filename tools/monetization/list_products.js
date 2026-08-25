const { listDeveloperProducts } = require('./roblox_api');

async function main() {
    console.log("Fetching Developer Products...");
    const products = await listDeveloperProducts();
    if (products) {
        console.log("\n=== DEVELOPER PRODUCTS ===");
        console.log(JSON.stringify(products, null, 2));
    }
}

main();
