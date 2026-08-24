---
name: roblox-asset-batch-downloader
description: >-
  Procedure and script template for batch-downloading public Roblox asset images
  via official Roblox CDN endpoints and auto-rescaling them for UI memory optimization.
---

# Roblox Asset Batch Downloader & Rescaler Workflow

Use this workflow to extract, batch-download, and rescale UI textures or decals from Roblox experiences for memory optimization.

---

## 1. How It Works (Technical Overview)

Roblox public image assets (decals, textures, UI images) are publicly accessible via the official Roblox Thumbnails API:

`https://thumbnails.roblox.com/v1/assets?assetIds=<ID1,ID2,...>&returnPolicy=PlaceHolder&size=512x512&format=Png`

This API returns a JSON payload containing direct CDN URLs (`https://tr.rbxcdn.com/...`) for each asset ID, allowing clean PNG image downloads without needing authentication or session cookies.

---

## 2. Python Batch Download Script

Run the following Python script to download asset IDs in chunks of 10 and save clean `.png` files:

```python
import urllib.request, json, os

asset_ids = [
    "105052363052939", "105215331733605", "105952264254886", "107904151808812", "112882057182762",
    "114505581952233", "117101885043003", "117431244796990", "119830369436772", "122127514724193",
    "126697368852796", "127312772270498", "12905962634", "130351473745260", "13049845751",
    "138677986064030", "4917649592", "6927295847", "71646319230388", "72392065441833",
    "83270804553268", "8398274754", "86506276108132", "89209434548027", "90587055551098",
    "92322196162857", "95809487388622", "96245126771230", "97406217305320", "98199146096947"
]

out_dir = os.path.expanduser("~/Desktop/ShopPNGs")
os.makedirs(out_dir, exist_ok=True)

chunk_size = 10
downloaded = 0

for i in range(0, len(asset_ids), chunk_size):
    chunk = asset_ids[i:i+chunk_size]
    ids_str = ",".join(chunk)
    url = f"https://thumbnails.roblox.com/v1/assets?assetIds={ids_str}&returnPolicy=PlaceHolder&size=512x512&format=Png"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            for item in data.get("data", []):
                aid = str(item.get("targetId"))
                img_url = item.get("imageUrl")
                if img_url and item.get("state") == "Completed":
                    img_req = urllib.request.Request(img_url, headers={"User-Agent": "Mozilla/5.0"})
                    with urllib.request.urlopen(img_req) as img_resp:
                        img_bytes = img_resp.read()
                        with open(os.path.join(out_dir, f"shop_{aid}.png"), "wb") as f:
                            f.write(img_bytes)
                        downloaded += 1
                        print(f"Downloaded shop_{aid}.png ({len(img_bytes)} bytes)")
    except Exception as e:
        print(f"Error fetching chunk: {e}")

print(f"Successfully downloaded {downloaded}/{len(asset_ids)} images into {out_dir}")
```

---

## 3. Image Rescaling via macOS `sips` Tool

To automatically resize all downloaded images to `512x512` pixels:

```bash
sips -z 512 512 ~/Desktop/ShopPNGs/*.png
```

---

## 4. Re-upload & Automated ID Swap Workflow

1. User uploads the `~/Desktop/ShopPNGs` folder into Roblox Studio using **Asset Manager -> Bulk Import**.
2. Run an `execute_luau` script via MCP in Studio to automatically re-bind the new asset IDs to the UI elements.
