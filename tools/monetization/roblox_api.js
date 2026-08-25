require('dotenv').config();

const API_KEY = process.env.ROBLOX_OPEN_CLOUD_KEY;
const UNIVERSE_ID = process.env.ROBLOX_UNIVERSE_ID;

function checkEnvVars() {
    if (!API_KEY) {
        console.error("ERROR: ROBLOX_OPEN_CLOUD_KEY is missing in your .env file.");
        process.exit(1);
    }
    if (!UNIVERSE_ID) {
        console.error("ERROR: ROBLOX_UNIVERSE_ID is missing in your .env file.");
        process.exit(1);
    }
}

/**
 * ==========================================
 * DEVELOPER PRODUCTS API
 * ==========================================
 */

async function createDeveloperProduct(name, description, priceInRobux) {
    checkEnvVars();
    const url = `https://apis.roblox.com/developer-products/v2/universes/${UNIVERSE_ID}/developer-products`;

    const formData = new FormData();
    formData.append('Name', name);
    formData.append('Description', description || '');
    formData.append('Price', priceInRobux.toString());
    formData.append('IsForSale', 'true');

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'x-api-key': API_KEY,
        },
        body: formData,
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to create product '${name}': ${response.status} - ${errorText}`);
        return null;
    }

    const data = await response.json();
    const productId = data.id || data.productId;
    console.log(`Successfully created Product '${name}'! Product ID: ${productId}`);
    return data;
}

async function listDeveloperProducts() {
    checkEnvVars();
    const url = `https://apis.roblox.com/developer-products/v2/universes/${UNIVERSE_ID}/developer-products`;

    const response = await fetch(url, {
        method: 'GET',
        headers: {
            'x-api-key': API_KEY,
        },
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to list developer products: ${response.status} - ${errorText}`);
        return null;
    }

    const data = await response.json();
    return data.developerProducts || data.data || data;
}

async function updateDeveloperProduct(productId, updates) {
    checkEnvVars();
    const url = `https://apis.roblox.com/developer-products/v2/universes/${UNIVERSE_ID}/developer-products/${productId}`;

    const formData = new FormData();
    if (updates.name) formData.append('Name', updates.name);
    if (updates.description !== undefined) formData.append('Description', updates.description);
    if (updates.price !== undefined) formData.append('Price', updates.price.toString());
    if (updates.isForSale !== undefined) formData.append('IsForSale', updates.isForSale.toString());

    const response = await fetch(url, {
        method: 'POST', // Roblox Open Cloud dev products update endpoint accepts POST or PATCH
        headers: {
            'x-api-key': API_KEY,
        },
        body: formData,
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to update product ${productId}: ${response.status} - ${errorText}`);
        return null;
    }

    const text = await response.text();
    let data = null;
    if (text && text.trim().length > 0) {
        try { data = JSON.parse(text); } catch (e) { data = text; }
    }
    console.log(`Successfully updated Product ${productId}!`);
    return data || true;
}

/**
 * ==========================================
 * GAME PASSES API
 * ==========================================
 */

async function createGamePass(name, description, priceInRobux) {
    checkEnvVars();
    const url = `https://apis.roblox.com/game-passes/v1/universes/${UNIVERSE_ID}/game-passes`;

    const formData = new FormData();
    formData.append('Name', name);
    formData.append('Description', description || '');
    formData.append('Price', priceInRobux.toString());
    formData.append('IsForSale', 'true');

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'x-api-key': API_KEY,
        },
        body: formData,
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to create game pass '${name}': ${response.status} - ${errorText}`);
        return null;
    }

    const data = await response.json();
    const gamePassId = data.id || data.gamePassId;
    console.log(`Successfully created GamePass '${name}'! GamePass ID: ${gamePassId}`);
    return data;
}

async function listGamePasses() {
    checkEnvVars();
    const url = `https://apis.roblox.com/game-passes/v1/universes/${UNIVERSE_ID}/game-passes`;

    const response = await fetch(url, {
        method: 'GET',
        headers: {
            'x-api-key': API_KEY,
        },
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to list game passes: ${response.status} - ${errorText}`);
        return null;
    }

    const data = await response.json();
    return data.gamePasses || data.data || data;
}

async function updateGamePass(gamePassId, updates) {
    checkEnvVars();
    const url = `https://apis.roblox.com/game-passes/v1/universes/${UNIVERSE_ID}/game-passes/${gamePassId}`;

    const formData = new FormData();
    if (updates.name) formData.append('Name', updates.name);
    if (updates.description !== undefined) formData.append('Description', updates.description);
    if (updates.price !== undefined) formData.append('Price', updates.price.toString());
    if (updates.isForSale !== undefined) formData.append('IsForSale', updates.isForSale.toString());

    const response = await fetch(url, {
        method: 'PATCH',
        headers: {
            'x-api-key': API_KEY,
        },
        body: formData,
    });

    if (!response.ok) {
        const errorText = await response.text();
        console.error(`Failed to update game pass ${gamePassId}: ${response.status} - ${errorText}`);
        return null;
    }

    const text = await response.text();
    let data = null;
    if (text && text.trim().length > 0) {
        try { data = JSON.parse(text); } catch (e) { data = text; }
    }
    console.log(`Successfully updated GamePass ${gamePassId}!`);
    return data || true;
}

module.exports = {
    createDeveloperProduct,
    listDeveloperProducts,
    updateDeveloperProduct,
    createGamePass,
    listGamePasses,
    updateGamePass
};
