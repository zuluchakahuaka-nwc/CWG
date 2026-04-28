const fs = require("fs");
const path = require("path");
const https = require("https");

const topojson = require("topojson-client");

const CANVAS_W = 1200;
const CANVAS_H = 850;
const MIN_LON = -107;
const MAX_LON = -67;
const MIN_LAT = 24;
const MAX_LAT = 48;
const MARGIN = 10;

const SX = (CANVAS_W - 2 * MARGIN) / (MAX_LON - MIN_LON);
const SY = (CANVAS_H - 2 * MARGIN) / (MAX_LAT - MIN_LAT);

function lonLatToXY(lon, lat) {
  const x = MARGIN + (lon - MIN_LON) * SX;
  const y = MARGIN + (MAX_LAT - lat) * SY;
  return [Math.round(x * 100) / 100, Math.round(y * 100) / 100];
}

function simplifyRing(ring, tolerance) {
  if (ring.length <= 4) return ring;
  const eps = tolerance || 1.5;
  let maxDist = 0;
  let maxIdx = 0;
  const n = ring.length;
  for (let i = 1; i < n - 1; i++) {
    const dx = ring[n - 1][0] - ring[0][0];
    const dy = ring[n - 1][1] - ring[0][1];
    const len = Math.sqrt(dx * dx + dy * dy);
    let d;
    if (len < 0.001) {
      d = Math.sqrt((ring[i][0] - ring[0][0]) ** 2 + (ring[i][1] - ring[0][1]) ** 2);
    } else {
      const t = ((ring[i][0] - ring[0][0]) * dx + (ring[i][1] - ring[0][1]) * dy) / (len * len);
      const cx = ring[0][0] + t * dx;
      const cy = ring[0][1] + t * dy;
      d = Math.sqrt((ring[i][0] - cx) ** 2 + (ring[i][1] - cy) ** 2);
    }
    if (d > maxDist) { maxDist = d; maxIdx = i; }
  }
  if (maxDist > eps) {
    const left = simplifyRing(ring.slice(0, maxIdx + 1), eps);
    const right = simplifyRing(ring.slice(maxIdx), eps);
    return left.slice(0, -1).concat(right);
  }
  return [ring[0], ring[n - 1]];
}

function simplifyPolygon(coords, eps) {
  return coords.map(ring => simplifyRing(ring, eps || 1.5));
}

function geoJsonCoordsToXY(coords, eps) {
  const result = [];
  for (const ring of coords) {
    const projected = ring.map(([lon, lat]) => lonLatToXY(lon, lat));
    const simplified = simplifyRing(projected, eps || 2.0);
    if (simplified.length >= 3) result.push(simplified);
  }
  return result;
}

function centroidOfRings(rings) {
  let cx = 0, cy = 0, n = 0;
  for (const ring of rings) {
    for (const [x, y] of ring) {
      cx += x; cy += y; n++;
    }
  }
  return n > 0 ? [cx / n, cy / n] : [0, 0];
}

function makeCirclePolygon(cx, cy, r, segments) {
  segments = segments || 12;
  const pts = [];
  for (let i = 0; i < segments; i++) {
    const angle = (i / segments) * Math.PI * 2;
    pts.push([Math.round((cx + Math.cos(angle) * r) * 100) / 100,
              Math.round((cy + Math.sin(angle) * r) * 100) / 100]);
  }
  pts.push(pts[0].slice());
  return pts;
}

function splitPolygonVert(rings, splitX) {
  const ring = rings[0];
  const left = [], right = [];
  for (let i = 0; i < ring.length - 1; i++) {
    const [x1, y1] = ring[i];
    const [x2, y2] = ring[i + 1];
    const isLeft1 = x1 <= splitX;
    const isLeft2 = x2 <= splitX;
    if (isLeft1) left.push([x1, y1]);
    else right.push([x1, y1]);
    if (isLeft1 !== isLeft2) {
      const t = (splitX - x1) / (x2 - x1);
      const iy = y1 + t * (y2 - y1);
      left.push([splitX, iy]);
      right.push([splitX, iy]);
    }
  }
  if (left.length >= 3) left.push(left[0].slice());
  if (right.length >= 3) right.push(right[0].slice());
  return { left, right };
}

function splitPolygonHoriz(rings, splitY) {
  const ring = rings[0];
  const top = [], bottom = [];
  for (let i = 0; i < ring.length - 1; i++) {
    const [x1, y1] = ring[i];
    const [x2, y2] = ring[i + 1];
    const isTop1 = y1 <= splitY;
    const isTop2 = y2 <= splitY;
    if (isTop1) top.push([x1, y1]);
    else bottom.push([x1, y1]);
    if (isTop1 !== isTop2) {
      const t = (splitY - y1) / (y2 - y1);
      const ix = x1 + t * (x2 - x1);
      top.push([ix, splitY]);
      bottom.push([ix, splitY]);
    }
  }
  if (top.length >= 3) top.push(top[0].slice());
  if (bottom.length >= 3) bottom.push(bottom[0].slice());
  return { top, bottom };
}

const FIPS_TO_TERRITORY = {
  "42": { id: "pennsylvania", eps: 2.5 },
  "24": { id: "maryland", eps: 2.0 },
  "54": { id: "virginia_west", eps: 2.5 },
  "51": { id: "virginia_full", eps: 2.5 },
  "21": { id: "kentucky", eps: 2.5 },
  "28": { id: "mississippi_full", eps: 2.5 },
  "47": { id: "tennessee_full", eps: 2.5 },
  "01": { id: "alabama_full", eps: 2.5 },
  "13": { id: "georgia_full", eps: 2.5 },
  "45": { id: "south_carolina", eps: 2.5 },
  "37": { id: "north_carolina", eps: 2.5 },
  "12": { id: "florida", eps: 3.0 },
  "22": { id: "louisiana_full", eps: 2.5 },
  "48": { id: "texas", eps: 3.5 },
  "05": { id: "arkansas", eps: 2.5 },
  "40": { id: "indian_territory", eps: 3.0 },
  "29": { id: "missouri", eps: 2.5 },
  "36": { id: "new_york", eps: 2.5 },
  "34": { id: "new_jersey", eps: 2.5 },
  "10": { id: "delaware", eps: 2.0 },
  "11": { id: "district_columbia", eps: 1.0 },
  "09": { id: "connecticut", eps: 2.0 },
  "23": { id: "minnesota", eps: 3.0 },
  "55": { id: "wisconsin", eps: 3.0 },
  "17": { id: "illinois", eps: 2.5 },
  "18": { id: "indiana", eps: 2.5 },
  "26": { id: "michigan", eps: 2.5 },
  "39": { id: "ohio", eps: 2.5 },
  "19": { id: "iowa", eps: 3.0 },
  "27": { id: "minnesota_south", eps: 3.0 },
  "31": { id: "nebraska", eps: 3.0 },
  "20": { id: "kansas", eps: 3.0 },
};

const CITY_POLYGONS = {
  washington_dc: { lat: 38.9072, lon: -77.0369, r: 12 },
  richmond: { lat: 37.5407, lon: -77.4360, r: 12 },
  harpers_ferry: { lat: 39.3259, lon: -77.7361, r: 10 },
  nashville: { lat: 36.1627, lon: -86.7816, r: 12 },
  memphis: { lat: 35.1495, lon: -90.0490, r: 11 },
  chattanooga: { lat: 35.0456, lon: -85.3097, r: 11 },
  corinth: { lat: 34.9343, lon: -88.5214, r: 10 },
  vicksburg: { lat: 32.3526, lon: -90.8779, r: 11 },
  natchez: { lat: 31.5604, lon: -91.4032, r: 10 },
  atlanta: { lat: 33.7490, lon: -84.3880, r: 13 },
  savannah: { lat: 32.0809, lon: -81.0912, r: 11 },
  charleston: { lat: 32.7846, lon: -79.9396, r: 11 },
  wilmington: { lat: 34.2257, lon: -77.9447, r: 11 },
  new_orleans: { lat: 29.9511, lon: -90.0715, r: 13 },
  mobile: { lat: 30.6954, lon: -88.0399, r: 11 },
};

function fetchJSON(url) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith("https") ? https : require("http");
    mod.get(url, { headers: { "User-Agent": "CWG-MapGen/1.0" } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        fetchJSON(res.headers.location).then(resolve).catch(reject);
        return;
      }
      let data = "";
      res.on("data", c => data += c);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error("JSON parse error")); }
      });
    }).on("error", reject);
  });
}

async function main() {
  console.log("Fetching US Atlas TopoJSON (states-10m)...");
  const topoData = await fetchJSON("https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json");

  console.log("Converting TopoJSON → GeoJSON...");
  const geojson = topojson.feature(topoData, topoData.objects.states);

  const statesByFIPS = {};
  for (const feature of geojson.features) {
    statesByFIPS[feature.id] = feature;
  }

  console.log("Processing state geometries...");
  const territoryPolygons = {};

  for (const [fips, cfg] of Object.entries(FIPS_TO_TERRITORY)) {
    const feature = statesByFIPS[fips];
    if (!feature) {
      console.log(`  SKIP FIPS ${fips} (${cfg.id}) — not found`);
      continue;
    }

    const geom = feature.geometry;
    let coords;
    if (geom.type === "Polygon") {
      coords = [geom.coordinates];
    } else if (geom.type === "MultiPolygon") {
      coords = geom.coordinates;
    } else {
      console.log(`  SKIP ${cfg.id} — unsupported geometry: ${geom.type}`);
      continue;
    }

    let allRings = [];
    for (const polyCoords of coords) {
      const rings = geoJsonCoordsToXY(polyCoords, cfg.eps || 2.5);
      allRings = allRings.concat(rings);
    }

    let largestRing = allRings[0] || [];
    let largestArea = 0;
    for (const ring of allRings) {
      let area = 0;
      for (let i = 0; i < ring.length - 1; i++) {
        area += ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1];
      }
      if (Math.abs(area) > largestArea) {
        largestArea = Math.abs(area);
        largestRing = ring;
      }
    }

    territoryPolygons[cfg.id] = largestRing;
    console.log(`  ${cfg.id}: ${largestRing.length} points`);
  }

  console.log("\nSplitting multi-territory states...");

  // Virginia → split into north + shenandoah (west half) and south/east
  if (territoryPolygons.virginia_full) {
    const c = centroidOfRings([territoryPolygons.virginia_full]);
    // Shenandoah = western portion
    const splitX = c[0] - 40;
    const parts = splitPolygonVert([territoryPolygons.virginia_full], splitX);
    if (parts.left.length >= 3) {
      territoryPolygons.shenandoah = simplifyRing(parts.left, 2.0);
      console.log(`  shenandoah: ${territoryPolygons.shenandoah.length} pts`);
    }
    if (parts.right.length >= 3) {
      // Split right side into north and south
      const splitY = c[1] - 10;
      const parts2 = splitPolygonHoriz([parts.right], splitY);
      if (parts2.top.length >= 3) {
        territoryPolygons.virginia_north = simplifyRing(parts2.top, 2.0);
        console.log(`  virginia_north: ${territoryPolygons.virginia_north.length} pts`);
      }
    }
    delete territoryPolygons.virginia_full;
  }

  // Tennessee → split east/west
  if (territoryPolygons.tennessee_full) {
    const c = centroidOfRings([territoryPolygons.tennessee_full]);
    const splitX = c[0] - 15;
    const parts = splitPolygonVert([territoryPolygons.tennessee_full], splitX);
    if (parts.left.length >= 3) {
      territoryPolygons.tennessee_west = simplifyRing(parts.left, 2.0);
      console.log(`  tennessee_west: ${territoryPolygons.tennessee_west.length} pts`);
    }
    if (parts.right.length >= 3) {
      territoryPolygons.tennessee_east = simplifyRing(parts.right, 2.0);
      console.log(`  tennessee_east: ${territoryPolygons.tennessee_east.length} pts`);
    }
    delete territoryPolygons.tennessee_full;
  }

  // Mississippi → split north (keep whole for simplicity, cities are separate)
  if (territoryPolygons.mississippi_full) {
    territoryPolygons.mississippi_north = territoryPolygons.mississippi_full;
    console.log(`  mississippi_north: ${territoryPolygons.mississippi_north.length} pts`);
    delete territoryPolygons.mississippi_full;
  }

  // Alabama → split north (keep whole, mobile is separate)
  if (territoryPolygons.alabama_full) {
    territoryPolygons.alabama_north = territoryPolygons.alabama_full;
    console.log(`  alabama_north: ${territoryPolygons.alabama_north.length} pts`);
    delete territoryPolygons.alabama_full;
  }

  // Georgia → split south (keep whole, atlanta & savannah are separate)
  if (territoryPolygons.georgia_full) {
    territoryPolygons.georgia_south = territoryPolygons.georgia_full;
    console.log(`  georgia_south: ${territoryPolygons.georgia_south.length} pts`);
    delete territoryPolygons.georgia_full;
  }

  // Louisiana → split north/south
  if (territoryPolygons.louisiana_full) {
    const c = centroidOfRings([territoryPolygons.louisiana_full]);
    const splitY = c[1] + 15;
    const parts = splitPolygonHoriz([territoryPolygons.louisiana_full], splitY);
    if (parts.top.length >= 3) {
      territoryPolygons.louisiana_north = simplifyRing(parts.top, 2.0);
      console.log(`  louisiana_north: ${territoryPolygons.louisiana_north.length} pts`);
    }
    if (parts.bottom.length >= 3) {
      territoryPolygons.louisiana_south = simplifyRing(parts.bottom, 2.0);
      console.log(`  louisiana_south: ${territoryPolygons.louisiana_south.length} pts`);
    }
    delete territoryPolygons.louisiana_full;
  }

  // Generate city polygons
  console.log("\nGenerating city polygons...");
  for (const [cityId, info] of Object.entries(CITY_POLYGONS)) {
    const [cx, cy] = lonLatToXY(info.lon, info.lat);
    territoryPolygons[cityId] = makeCirclePolygon(cx, cy, info.r, 14);
    console.log(`  ${cityId}: circle at (${cx.toFixed(1)}, ${cy.toFixed(1)})`);
  }

  // Ocean / coast polygons
  territoryPolygons.atlantic_coast = [
    lonLatToXY(-76, 38),
    lonLatToXY(-75.5, 36),
    lonLatToXY(-76, 34),
    lonLatToXY(-77, 33),
    lonLatToXY(-79, 32),
    lonLatToXY(-80, 30),
    lonLatToXY(-81, 28),
    lonLatToXY(-80, 25),
    [CANVAS_W, 25 * SY + MARGIN],
    [CANVAS_W, 38 * SY + MARGIN],
    lonLatToXY(-76, 38),
  ];
  territoryPolygons.atlantic_coast.push(territoryPolygons.atlantic_coast[0].slice());

  territoryPolygons.gulf_coast = [
    lonLatToXY(-80, 25),
    lonLatToXY(-82, 26),
    lonLatToXY(-83, 28),
    lonLatToXY(-84, 30),
    lonLatToXY(-87, 30),
    lonLatToXY(-89, 29),
    lonLatToXY(-90, 29),
    lonLatToXY(-93, 29),
    lonLatToXY(-95, 28),
    lonLatToXY(-97, 26),
    [MIN_LON * SX + MARGIN, 24 * SY + MARGIN],
    [CANVAS_W, 25 * SY + MARGIN],
    lonLatToXY(-80, 25),
  ];
  territoryPolygons.gulf_coast.push(territoryPolygons.gulf_coast[0].slice());

  // Mississippi river as polyline
  const mississippiRiver = [
    [-93.5, 47.5], [-93.2, 46.5], [-93.0, 45.5], [-92.5, 44.5],
    [-92.0, 43.5], [-91.2, 42.5], [-91.0, 41.5], [-90.5, 41.0],
    [-90.0, 40.0], [-89.5, 38.5], [-89.0, 37.5], [-89.5, 36.5],
    [-90.0, 35.5], [-90.2, 35.0], [-90.5, 34.0], [-91.0, 33.0],
    [-91.0, 32.0], [-90.8, 31.0], [-91.0, 30.0], [-91.0, 29.5],
    [-89.5, 29.0],
  ].map(([lon, lat]) => lonLatToXY(lon, lat));

  const ohioRiver = [
    [-80.5, 40.5], [-81.0, 39.8], [-82.0, 39.0], [-83.0, 38.5],
    [-84.0, 38.0], [-85.0, 37.8], [-86.0, 37.5], [-87.0, 37.2],
    [-88.0, 37.0], [-89.0, 37.0],
  ].map(([lon, lat]) => lonLatToXY(lon, lat));

  const potomacRiver = [
    [-78.5, 39.3], [-78.0, 39.2], [-77.5, 39.0], [-77.2, 38.8],
    [-77.0, 38.5],
  ].map(([lon, lat]) => lonLatToXY(lon, lat));

  const rivers = {
    mississippi: mississippiRiver,
    ohio: ohioRiver,
    potomac: potomacRiver,
  };

  // Appalachian mountains
  const mountains = {
    appalachian: [
      [-83.5, 36.5], [-83.0, 36.8], [-82.0, 37.0], [-81.5, 37.5],
      [-81.0, 38.0], [-80.5, 38.5], [-80.0, 39.0], [-79.5, 39.5],
      [-78.5, 39.8], [-78.0, 40.0], [-77.5, 40.5],
    ].map(([lon, lat]) => lonLatToXY(lon, lat)),
    blue_ridge: [
      [-83.5, 35.0], [-83.0, 35.5], [-82.5, 36.0], [-82.0, 36.5],
      [-81.5, 37.0],
    ].map(([lon, lat]) => lonLatToXY(lon, lat)),
    ozarks: [
      [-94.0, 37.5], [-93.5, 37.0], [-93.0, 36.5], [-92.5, 36.0],
      [-92.0, 35.5],
    ].map(([lon, lat]) => lonLatToXY(lon, lat)),
  };

  // Forests
  const forests = [
    { lon: -80.5, lat: 37.5, r: 1.5, n: 6 },
    { lon: -83.0, lat: 35.5, r: 1.8, n: 8 },
    { lon: -89.0, lat: 33.0, r: 1.5, n: 7 },
    { lon: -91.0, lat: 34.5, r: 1.2, n: 5 },
    { lon: -79.0, lat: 34.0, r: 1.5, n: 6 },
    { lon: -82.5, lat: 33.0, r: 1.3, n: 5 },
    { lon: -86.0, lat: 35.0, r: 1.5, n: 6 },
    { lon: -84.5, lat: 34.5, r: 1.2, n: 5 },
    { lon: -78.0, lat: 36.0, r: 1.0, n: 4 },
  ].map(f => {
    const [cx, cy] = lonLatToXY(f.lon, f.lat);
    return { cx, cy, r: f.r, n: f.n };
  });

  const output = {
    meta: {
      width: CANVAS_W,
      height: CANVAS_H,
      projection: "equirectangular",
      min_lon: MIN_LON,
      max_lon: MAX_LON,
      min_lat: MIN_LAT,
      max_lat: MAX_LAT,
    },
    territories: territoryPolygons,
    rivers,
    mountains,
    forests,
  };

  const outPath = path.join(__dirname, "data", "maps", "map_data.json");
  fs.writeFileSync(outPath, JSON.stringify(output, null, 2));
  console.log(`\nWrote ${outPath}`);
  console.log(`Territories: ${Object.keys(territoryPolygons).length}`);
  console.log(`Rivers: ${Object.keys(rivers).length}`);
  console.log(`Mountains: ${Object.keys(mountains).length}`);
  console.log(`Forests: ${forests.length}`);
}

main().catch(err => {
  console.error("FATAL:", err.message);
  process.exit(1);
});
