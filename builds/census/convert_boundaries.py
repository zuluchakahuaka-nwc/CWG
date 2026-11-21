# Convert US Census state boundaries (public domain) into the game's
# map_data_v2.json: real state polygons for whole states, historical
# half-plane clips for split territories, small discs for city regions.
import shapefile, json, math, os

SHP = os.path.join(os.path.dirname(__file__), "cb_2023_us_state_20m.shp")
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "data", "maps", "map_data_v2.json")

# game territory id -> (census STUSPS, clip) ; clip: (axis, keep, value)
# axis 'lat'/'lon', keep 'north'/'south'/'east'/'west' of value
STATE_MAP = {
    "arkansas": ("AR", None),
    "connecticut": ("CT", None),
    "delaware": ("DE", None),
    "florida": ("FL", None),
    "illinois": ("IL", None),
    "indiana": ("IN", None),
    "iowa": ("IA", None),
    "kansas": ("KS", None),
    "kentucky": ("KY", None),
    "maryland": ("MD", None),
    "michigan": ("MI", None),
    "minnesota": ("MN", None),
    "missouri": ("MO", None),
    "nebraska": ("NE", None),
    "new_jersey": ("NJ", None),
    "new_york": ("NY", None),
    "north_carolina": ("NC", None),
    "ohio": ("OH", None),
    "pennsylvania": ("PA", None),
    "south_carolina": ("SC", None),
    "texas": ("TX", None),
    "wisconsin": ("WI", None),
    "indian_territory": ("OK", ("lon", "east", -99.3)),  # 1861 Indian Territory, no panhandle
    "alabama_north": ("AL", ("lat", "north", 32.35)),
    "georgia_south": ("GA", ("lat", "south", 32.6)),
    "louisiana_north": ("LA", ("lat", "north", 30.9)),
    "louisiana_south": ("LA", ("lat", "south", 30.9)),
    "mississippi_north": ("MS", ("lat", "north", 32.35)),
    "tennessee_east": ("TN", ("lon", "east", -86.6)),
    "tennessee_west": ("TN", ("lon", "west", -86.6)),
    "virginia_north": ("VA", ("lon", "east", -80.4)),  # 1861 VA incl. future WV
    "virginia_west": ("VA", ("lon", "west", -80.4)),
    "washington_dc": ("DC", None),
}

# city territory id -> (lon, lat)
CITIES = {
    "atlanta": (-84.39, 33.75),
    "charleston": (-79.93, 32.78),
    "chattanooga": (-85.31, 35.05),
    "corinth": (-88.50, 34.93),
    "harpers_ferry": (-77.74, 39.32),
    "memphis": (-90.05, 35.15),
    "mobile": (-88.04, 30.69),
    "nashville": (-86.78, 36.16),
    "natchez": (-91.40, 31.56),
    "new_orleans": (-90.07, 29.95),
    "richmond": (-77.44, 37.54),
    "savannah": (-81.10, 32.08),
    "shenandoah": (-78.75, 38.75),
    "vicksburg": (-90.88, 32.35),
    "wilmington": (-77.94, 34.23),
}

WIDTH, HEIGHT, MARGIN = 1200.0, 850.0, 22.0
MID_LAT = 37.0
K = math.cos(math.radians(MID_LAT))  # equirectangular aspect fix

def keep_point(lon, lat, clip):
    if clip is None:
        return True
    axis, side, v = clip
    if axis == "lon":
        return lon >= v if side == "east" else lon <= v
    return lat >= v if side == "north" else lat <= v

def clip_ring(ring, clip):
    """Sutherland-Hodgman clip of a lon/lat ring by one half-plane."""
    if clip is None:
        return ring
    def inside(p):
        return keep_point(p[0], p[1], clip)
    out = []
    n = len(ring)
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        ia, ib = inside(a), inside(b)
        if ia:
            out.append(a)
        if ia != ib:
            t = 0.0
            axis, _, v = clip
            if axis == "lon":
                t = (v - a[0]) / (b[0] - a[0]) if b[0] != a[0] else 0.0
            else:
                t = (v - a[1]) / (b[1] - a[1]) if b[1] != a[1] else 0.0
            t = max(0.0, min(1.0, t))
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out

def largest_ring(shapes, stusps):
    best, best_n = None, -1
    for sr in shapes.iterShapeRecords():
        if sr.record["STUSPS"] == stusps:
            pts = sr.shape.points
            # a shape may be MultiPolygon: split by parts
            parts = list(sr.shape.parts) + [len(pts)]
            for i in range(len(parts) - 1):
                ring = [(p[0], p[1]) for p in pts[parts[i]:parts[i + 1]]]
                if len(ring) > best_n:
                    best, best_n = ring, len(ring)
    return best

def simplify(ring, target):
    if len(ring) <= target:
        return ring
    step = len(ring) / float(target)
    return [ring[int(i * step)] for i in range(target)]

def disc(lon, lat, r_deg, n=14):
    return [(lon + r_deg * math.cos(2 * math.pi * i / n) / K, lat + r_deg * math.sin(2 * math.pi * i / n)) for i in range(n)]

def main():
    r = shapefile.Reader(SHP)
    shapes = r
    polys = {}
    for tid, (st, clip) in STATE_MAP.items():
        ring = largest_ring(shapes, st)
        if ring is None:
            print("MISSING state", st)
            continue
        ring = clip_ring(ring, clip)
        ring = simplify(ring, 90)
        if len(ring) >= 3:
            polys[tid] = ring
    for tid, (lon, lat) in CITIES.items():
        polys[tid] = disc(lon, lat, 0.35)

    # project: collect bounds
    all_pts = [p for ring in polys.values() for p in ring]
    xs = [p[0] * K for p in all_pts]
    ys = [p[1] for p in all_pts]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    sx = (WIDTH - 2 * MARGIN) / (maxx - minx)
    sy = (HEIGHT - 2 * MARGIN) / (maxy - miny)
    s = min(sx, sy)
    ox = (WIDTH - (maxx - minx) * s) / 2.0
    oy = (HEIGHT - (maxy - miny) * s) / 2.0
    def proj(p):
        return (round(ox + (p[0] * K - minx) * s, 1), round(oy + (maxy - p[1]) * s, 1))

    old = json.load(open(os.path.join(os.path.dirname(__file__), "..", "..", "data", "maps", "map_data.json"), encoding="utf-8"))
    territories = {tid: [list(proj(p)) for p in ring] for tid, ring in polys.items()}
    out = {
        "meta": old.get("meta", {"width": 1200, "height": 850}),
        "territories": territories,
        "rivers": old.get("rivers", {}),
        "mountains": old.get("mountains", {}),
        "forests": old.get("forests", []),
    }
    json.dump(out, open(OUT, "w", encoding="utf-8"), separators=(",", ":"))
    print("territories:", len(territories), "->", OUT)

if __name__ == "__main__":
    main()
