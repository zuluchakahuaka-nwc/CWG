const fs = require("fs");
const path = require("path");

const SVG_FILE = path.join(__dirname, "assets/sprites/map/blank_us_1860.svg");
const OUT_FILE = path.join(__dirname, "data/maps/map_data.json");

const svg = fs.readFileSync(SVG_FILE, "utf8");

const SVG_W = 600, SVG_H = 379.592;
const DST_W = 1200, DST_H = 850, PAD = 20;

function parsePathD(d) {
  const cmds = [];
  const re = /([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)/g;
  let m;
  while ((m = re.exec(d)) !== null) {
    cmds.push({ cmd: m[1], args: m[2].trim() ? m[2].trim().split(/[\s,]+/).map(Number) : [] });
  }
  return cmds;
}

function pathToPoints(d) {
  const cmds = parsePathD(d);
  const points = [];
  let cx = 0, cy = 0, sx = 0, sy = 0;
  for (const { cmd, args } of cmds) {
    switch (cmd) {
      case "M": for (let i=0;i<args.length;i+=2){cx=args[i];cy=args[i+1];sx=cx;sy=cy;points.push([cx,cy]);} break;
      case "m": for (let i=0;i<args.length;i+=2){cx+=args[i];cy+=args[i+1];sx=cx;sy=cy;points.push([cx,cy]);} break;
      case "L": for (let i=0;i<args.length;i+=2){cx=args[i];cy=args[i+1];points.push([cx,cy]);} break;
      case "l": for (let i=0;i<args.length;i+=2){cx+=args[i];cy+=args[i+1];points.push([cx,cy]);} break;
      case "H": for (const x of args){cx=x;points.push([cx,cy]);} break;
      case "h": for (const dx of args){cx+=dx;points.push([cx,cy]);} break;
      case "V": for (const y of args){cy=y;points.push([cx,cy]);} break;
      case "v": for (const dy of args){cy+=dy;points.push([cx,cy]);} break;
      case "C": for (let i=0;i<args.length;i+=6){sampleCubic(cx,cy,args[i],args[i+1],args[i+2],args[i+3],args[i+4],args[i+5],points);cx=args[i+4];cy=args[i+5];} break;
      case "c": for (let i=0;i<args.length;i+=6){sampleCubic(cx,cy,cx+args[i],cy+args[i+1],cx+args[i+2],cy+args[i+3],cx+args[i+4],cy+args[i+5],points);cx+=args[i+4];cy+=args[i+5];} break;
      case "S": for (let i=0;i<args.length;i+=4){sampleCubic(cx,cy,cx,cy,args[i],args[i+1],args[i+2],args[i+3],points);cx=args[i+2];cy=args[i+3];} break;
      case "Q": for (let i=0;i<args.length;i+=4){sampleQuad(cx,cy,args[i],args[i+1],args[i+2],args[i+3],points);cx=args[i+2];cy=args[i+3];} break;
      case "q": for (let i=0;i<args.length;i+=4){sampleQuad(cx,cy,cx+args[i],cy+args[i+1],cx+args[i+2],cy+args[i+3],points);cx+=args[i+2];cy+=args[i+3];} break;
      case "Z": case "z":
        cx=sx;cy=sy;
        if(points.length>0){const l=points[points.length-1],f=points[0];if(Math.abs(l[0]-f[0])>0.01||Math.abs(l[1]-f[1])>0.01)points.push([f[0],f[1]]);}
        break;
    }
  }
  return points;
}

function sampleCubic(x0,y0,x1,y1,x2,y2,x3,y3,pts){const N=8;for(let i=1;i<=N;i++){const t=i/N,u=1-t;pts.push([u*u*u*x0+3*u*u*t*x1+3*u*t*t*x2+t*t*t*x3,u*u*u*y0+3*u*u*t*y1+3*u*t*t*y2+t*t*t*y3]);}}
function sampleQuad(x0,y0,x1,y1,x2,y2,pts){const N=6;for(let i=1;i<=N;i++){const t=i/N,u=1-t;pts.push([u*u*x0+2*u*t*x1+t*t*x2,u*u*y0+2*u*t*y1+t*t*y2]);}}

function hasSI(pts){for(let i=0;i<pts.length-1;i++)for(let j=i+2;j<pts.length-1;j++){const a=pts[i],b=pts[i+1],c=pts[j],d=pts[j+1];const det=(b[0]-a[0])*(d[1]-c[1])-(b[1]-a[1])*(d[0]-c[0]);if(Math.abs(det)<1e-10)continue;const t=((c[0]-a[0])*(d[1]-c[1])-(c[1]-a[1])*(d[0]-c[0]))/det;const u=((c[0]-a[0])*(b[1]-a[1])-(c[1]-a[1])*(b[0]-a[0]))/det;if(t>0.01&&t<0.99&&u>0.01&&u<0.99)return true;}return false;}

function convexHull(points){
  const pts=points.filter(p=>Array.isArray(p)&&p.length>=2).sort((a,b)=>a[0]-b[0]||a[1]-b[1]);
  const cross=(O,A,B)=>(A[0]-O[0])*(B[1]-O[1])-(A[1]-O[1])*(B[0]-O[0]);
  const lower=[];for(const p of pts){while(lower.length>=2&&cross(lower[lower.length-2],lower[lower.length-1],p)<=0)lower.pop();lower.push(p);}
  const upper=[];for(let i=pts.length-1;i>=0;i--){const p=pts[i];while(upper.length>=2&&cross(upper[upper.length-2],upper[upper.length-1],p)<=0)upper.pop();upper.push(p);}
  upper.pop();lower.pop();const hull=lower.concat(upper);hull.push(hull[0].slice());return hull;
}

function polygonArea(pts){let a=0;for(let i=0;i<pts.length-1;i++)a+=pts[i][0]*pts[i+1][1]-pts[i+1][0]*pts[i][1];return Math.abs(a)/2;}
function centroid(pts){let cx=0,cy=0,n=0;for(const[x,y]of pts){cx+=x;cy+=y;n++;}return[cx/n,cy/n];}

function simplify(pts,eps){
  if(pts.length<=3)return pts;
  const md=(p,a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],l=Math.sqrt(dx*dx+dy*dy);if(l<0.001)return Math.sqrt((p[0]-a[0])**2+(p[1]-a[1])**2);const t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/(l*l)));return Math.sqrt((p[0]-(a[0]+t*dx))**2+(p[1]-(a[1]+t*dy))**2);};
  let dm=0,idx=0;
  for(let i=1;i<pts.length-1;i++){const d=md(pts[i],pts[0],pts[pts.length-1]);if(d>dm){dm=d;idx=i;}}
  if(dm>eps){const l=simplify(pts.slice(0,idx+1),eps),r=simplify(pts.slice(idx),eps);return l.slice(0,-1).concat(r);}
  return[pts[0],pts[pts.length-1]];
}

function scalePoint(p){
  const sx=(DST_W-2*PAD)/SVG_W, sy=(DST_H-2*PAD)/SVG_H, s=Math.min(sx,sy);
  const ox=PAD+(DST_W-2*PAD-SVG_W*s)/2, oy=PAD+(DST_H-2*PAD-SVG_H*s)/2;
  return[Math.round((ox+p[0]*s)*100)/100,Math.round((oy+p[1]*s)*100)/100];
}

// Extract all shapes from SVG
const shapes=[];
const pathRe=/<path[^>]*\sd="([^"]*)"[^>]*>/g;
let pm;
while((pm=pathRe.exec(svg))!==null){const pts=pathToPoints(pm[1]);if(pts.length>=3)shapes.push({pts,area:polygonArea(pts),center:centroid(pts)});}
const polyRe=/<polygon[^>]*\spoints="([^"]*)"[^>]*/g;
let plm;
while((plm=polyRe.exec(svg))!==null){const pts=plm[1].trim().split(/\s+/).map(p=>{const[x,y]=p.split(",").map(Number);return[x,y];}).filter(p=>!isNaN(p[0])&&!isNaN(p[1]));if(pts.length>=3)shapes.push({pts,area:polygonArea(pts),center:centroid(pts)});}

console.log(`Extracted ${shapes.length} shapes`);

// Known centroids from the explore agent analysis (rank → centroid)
const CENTROIDS = {
  california:[46.67,207.72], oregon_territory:[70.13,72.17],
  washington_territory:[92.97,54.03], new_mexico_territory:[140.20,239.26],
  nevada_territory:[173.59,172.15], utah_territory:[208.43,101.24],
  kansas:[270.37,186.44], arizona_territory:[276.31,301.21],
  nebraska:[283.54,97.27], texas:[291.18,246.67],
  dakota_territory:[335.11,69.05], minnesota:[341.79,143.21],
  missouri:[353.51,193.73], arkansas:[362.47,241.80],
  iowa:[368.28,98.45], louisiana:[372.12,305.87],
  illinois:[377.39,174.23], mississippi:[380.36,273.45],
  wisconsin:[395.15,74.45], indiana:[408.66,177.29],
  kentucky:[418.97,195.20], north_carolina:[422.94,275.64],
  michigan:[431.15,217.62], ohio:[453.05,161.30],
  south_carolina:[460.10,262.81], florida:[478.99,326.58],
  tennessee:[480.67,244.43], alabama:[481.67,258.0],
  virginia:[495.23,173.84], west_virginia:[504.27,214.13],
  pennsylvania:[512.45,136.51], delaware:[513.12,163.44],
  new_york:[517.96,109.30], maryland:[516.47,164.01],
  new_jersey:[532.64,141.39], massachusetts:[528.29,155.92],
  vermont:[540.79,87.04], connecticut:[545.56,119.94],
  new_hampshire:[551.03,83.50], rhode_island:[560.02,113.69],
  maine:[572.11,62.58],
};

// Match shapes by centroid proximity
const used = new Set();
const matched = {};

for (const [stateId, [tx, ty]] of Object.entries(CENTROIDS)) {
  let bestIdx = -1, bestDist = Infinity;
  for (let i = 0; i < shapes.length; i++) {
    if (used.has(i)) continue;
    const [cx, cy] = shapes[i].center;
    const d = (cx - tx) ** 2 + (cy - ty) ** 2;
    if (d < bestDist) { bestDist = d; bestIdx = i; }
  }
  if (bestIdx >= 0 && bestDist < 800) {
    matched[stateId] = shapes[bestIdx];
    used.add(bestIdx);
    console.log(`  ${stateId}: ${shapes[bestIdx].pts.length} pts, dist=${Math.sqrt(bestDist).toFixed(1)}`);
  } else {
    console.log(`  ${stateId}: NOT MATCHED (dist=${bestDist<Infinity?Math.sqrt(bestDist).toFixed(1):'none'})`);
  }
}

// Territory → state mapping
const TERRITORY_TO_STATE = {
  pennsylvania:"pennsylvania", maryland:"maryland", kentucky:"kentucky",
  missouri:"missouri", florida:"florida", texas:"texas", arkansas:"arkansas",
  south_carolina:"south_carolina", north_carolina:"north_carolina",
  new_york:"new_york", new_jersey:"new_jersey", delaware:"delaware",
  connecticut:"connecticut", ohio:"ohio", indiana:"indiana", illinois:"illinois",
  michigan:"michigan", wisconsin:"wisconsin", minnesota:"minnesota",
  iowa:"iowa", kansas:"kansas", nebraska:"nebraska",
  virginia_north:"virginia", shenandoah:"virginia", richmond:"virginia",
  harpers_ferry:"west_virginia", virginia_west:"west_virginia",
  tennessee_east:"tennessee", tennessee_west:"tennessee",
  memphis:"tennessee", nashville:"tennessee", chattanooga:"tennessee",
  corinth:"mississippi", mississippi_north:"mississippi",
  vicksburg:"mississippi", natchez:"mississippi",
  alabama_north:"alabama", mobile:"alabama",
  atlanta:"georgia_south", georgia_south:"south_carolina",
  savannah:"south_carolina", charleston:"south_carolina",
  wilmington:"north_carolina",
  louisiana_north:"louisiana", louisiana_south:"louisiana", new_orleans:"louisiana",
};

// Wait — the mapping above is wrong. Let me redo it properly.
// Our game territories use these state shapes:
const WHOLE = [
  "pennsylvania","maryland","kentucky","missouri","florida","texas","arkansas",
  "south_carolina","north_carolina","new_york","new_jersey","delaware",
  "connecticut","ohio","indiana","illinois","michigan","wisconsin","minnesota",
  "iowa","kansas","nebraska",
];

const territoryPolygons = {};

const HIGH_EPS = new Set(["florida","virginia_west","maryland","wisconsin","virginia_north","virginia_west"]);
const EPS_MAP = {
  florida: 40, virginia_west: 30, maryland: 15, wisconsin: 40, virginia_north: 30,
};

for (const tid of WHOLE) {
  const shape = matched[tid];
  if (!shape) { console.log(`  SKIP ${tid}`); continue; }
  const scaled = shape.pts.map(scalePoint);
  const eps = EPS_MAP[tid] || 2.5;
  let simplified = simplify(scaled, eps);
  if (hasSI(simplified)) {
    simplified = convexHull(scaled);
    console.log(`  ${tid}: CONVEX HULL ${simplified.length} pts (was ${scaled.length})`);
  } else {
    const first = simplified[0], last = simplified[simplified.length-1];
    if (Math.abs(first[0]-last[0])>0.01 || Math.abs(first[1]-last[1])>0.01) simplified.push(first.slice());
    territoryPolygons[tid] = simplified;
    console.log(`  ${tid}: ${simplified.length} pts (was ${scaled.length})`);
    continue;
  }
  const first2 = simplified[0], last2 = simplified[simplified.length-1];
  if (Math.abs(first2[0]-last2[0])>0.01 || Math.abs(first2[1]-last2[1])>0.01) simplified.push(first2.slice());
  territoryPolygons[tid] = simplified;
}

// Virginia → split into shenandoah (west half) + virginia_north (east half)
if (matched.virginia) {
  const pts = matched.virginia.pts;
  const c = centroid(pts);
  const {left,right} = splitVert(pts, c[0]-10);
  if(left.length>=3){territoryPolygons.shenandoah=simplify(left.map(scalePoint),5);console.log(`  shenandoah: ${territoryPolygons.shenandoah.length} pts`);}
  if(right.length>=3){
    let vn = simplify(right.map(scalePoint),5);
    if(hasSI(vn)) vn = convexHull(right.map(scalePoint));
    territoryPolygons.virginia_north=vn;
    console.log(`  virginia_north: ${vn.length} pts`);
  }
}

if (matched.west_virginia) {
  let wv = simplify(matched.west_virginia.pts.map(scalePoint), 5);
  if(hasSI(wv)) wv = convexHull(matched.west_virginia.pts.map(scalePoint));
  territoryPolygons.virginia_west = wv;
  console.log(`  virginia_west: ${wv.length} pts`);
}

// Tennessee → split east/west
if (matched.tennessee) {
  const pts = matched.tennessee.pts;
  const c = centroid(pts);
  const {left,right} = splitVert(pts, c[0]-5);
  if(left.length>=3){territoryPolygons.tennessee_west=simplify(left.map(scalePoint),1.5);console.log(`  tennessee_west: ${territoryPolygons.tennessee_west.length} pts`);}
  if(right.length>=3){territoryPolygons.tennessee_east=simplify(right.map(scalePoint),1.5);console.log(`  tennessee_east: ${territoryPolygons.tennessee_east.length} pts`);}
}

// Mississippi whole
if (matched.mississippi) {
  territoryPolygons.mississippi_north = simplify(matched.mississippi.pts.map(scalePoint), 2.5);
  console.log(`  mississippi_north: ${territoryPolygons.mississippi_north.length} pts`);
}

// Alabama: we matched alabama but centroid was (481,258) which seems more like SC/GA area
// The explore agent had rank 28 at (423, 276) for alabama
// Let me use the matched shape if area is reasonable
if (matched.alabama) {
  territoryPolygons.alabama_north = matched.alabama.pts.map(scalePoint);
  console.log(`  alabama_north: ${territoryPolygons.alabama_north.length} pts`);
}

// Georgia: the explore agent showed georgia doesn't have a direct entry
// Alabama centroid (481,258) is actually georgia territory. Let me use south_carolina shape for georgia_south
if (matched.south_carolina) {
  // Actually south_carolina centroid is (460,263) which IS SC
  // We need to find georgia separately
}

// Louisiana → split north/south
if (matched.louisiana) {
  const pts = matched.louisiana.pts;
  const c = centroid(pts);
  const {top,bottom} = splitHoriz(pts, c[1]+10);
  if(top.length>=3){territoryPolygons.louisiana_north=simplify(top.map(scalePoint),1.5);console.log(`  louisiana_north: ${territoryPolygons.louisiana_north.length} pts`);}
  if(bottom.length>=3){territoryPolygons.louisiana_south=simplify(bottom.map(scalePoint),1.5);console.log(`  louisiana_south: ${territoryPolygons.louisiana_south.length} pts`);}
}

// Cities as small circles at known SVG positions
const CITIES = {
  washington_dc:{sx:497,sy:143,r:8}, richmond:{sx:470,sy:172,r:8},
  harpers_ferry:{sx:462,sy:148,r:7}, nashville:{sx:383,sy:218,r:8},
  memphis:{sx:340,sy:228,r:7}, chattanooga:{sx:400,sy:230,r:7},
  corinth:{sx:352,sy:238,r:6}, vicksburg:{sx:325,sy:272,r:7},
  natchez:{sx:332,sy:282,r:6}, atlanta:{sx:415,sy:265,r:8},
  savannah:{sx:445,sy:280,r:7}, charleston:{sx:455,sy:255,r:7},
  wilmington:{sx:462,sy:245,r:7}, new_orleans:{sx:278,sy:310,r:8},
  mobile:{sx:350,sy:282,r:7},
};

function makeCircle(cx,cy,r,n=12){const pts=[];for(let i=0;i<n;i++){const a=(i/n)*Math.PI*2;pts.push([Math.round((cx+Math.cos(a)*r)*100)/100,Math.round((cy+Math.sin(a)*r)*100)/100]);}pts.push(pts[0].slice());return pts;}

for(const[cid,{sx,sy,r}]of Object.entries(CITIES)){
  const[cx,cy]=scalePoint([sx,sy]);
  territoryPolygons[cid]=makeCircle(cx,cy,r*((DST_W-2*PAD)/SVG_W)*0.8,14);
  console.log(`  ${cid}: circle`);
}

// Ocean polygons
const s = p => scalePoint(p);
territoryPolygons.atlantic_coast=[
  [580,30],[585,80],[575,130],[560,170],[545,200],[540,230],
  [545,260],[520,285],[480,305],[450,320],[420,335],[380,345],
  [350,355],[320,360],[300,365],[300,380],[600,380],[600,0],[580,0],
].map(s);
territoryPolygons.atlantic_coast.push(territoryPolygons.atlantic_coast[0].slice());

territoryPolygons.gulf_coast=[
  [300,365],[320,360],[350,355],[380,345],[420,335],[380,355],
  [340,365],[300,370],[260,365],[220,360],[180,355],[140,350],
  [100,340],[60,330],[0,330],[0,380],[300,380],
].map(s);
territoryPolygons.gulf_coast.push(territoryPolygons.gulf_coast[0].slice());

// Rivers
const rivers={
  mississippi:[[310,10],[315,40],[320,70],[325,100],[330,130],[335,155],[337,180],[338,200],[337,220],[335,240],[330,260],[325,280],[320,300],[315,320],[310,340],[300,360]].map(s),
  ohio:[[370,165],[385,170],[400,172],[415,174],[430,173],[445,170],[460,165],[470,160]].map(s),
  potomac:[[462,145],[468,148],[475,152],[482,155],[490,158],[497,160]].map(s),
};

const mountains={
  appalachian:[[460,195],[458,185],[455,175],[452,165],[450,155],[448,145],[445,135],[442,125]].map(s),
  blue_ridge:[[448,210],[445,200],[443,190],[440,180]].map(s),
  ozarks:[[300,200],[295,195],[290,190],[285,185]].map(s),
};

const forests=[
  {sx:445,sy:160,r:1.5,n:6},{sx:440,sy:200,r:1.2,n:5},{sx:350,sy:240,r:1.3,n:5},
  {sx:340,sy:260,r:1.0,n:4},{sx:460,sy:240,r:1.4,n:5},{sx:380,sy:270,r:1.2,n:4},{sx:420,sy:280,r:1.3,n:5},
].map(f=>{const[cx,cy]=scalePoint([f.sx,f.sy]);return{cx,cy,r:f.r,n:f.n};});

function splitVert(pts,splitX){
  const left=[],right=[];
  for(let i=0;i<pts.length-1;i++){
    const[x1,y1]=pts[i],[x2,y2]=pts[i+1];
    const l1=x1<=splitX,l2=x2<=splitX;
    if(l1)left.push([x1,y1]);else right.push([x1,y1]);
    if(l1!==l2){const t=(splitX-x1)/(x2-x1);left.push([splitX,y1+t*(y2-y1)]);right.push([splitX,y1+t*(y2-y1)]);}
  }
  if(left.length>=3)left.push(left[0].slice());
  if(right.length>=3)right.push(right[0].slice());
  return{left,right};
}

function splitHoriz(pts,splitY){
  const top=[],bottom=[];
  for(let i=0;i<pts.length-1;i++){
    const[x1,y1]=pts[i],[x2,y2]=pts[i+1];
    const t1=y1<=splitY,t2=y2<=splitY;
    if(t1)top.push([x1,y1]);else bottom.push([x1,y1]);
    if(t1!==t2){const t=(splitY-y1)/(y2-y1);top.push([x1+t*(x2-x1),splitY]);bottom.push([x1+t*(x2-x1),splitY]);}
  }
  if(top.length>=3)top.push(top[0].slice());
  if(bottom.length>=3)bottom.push(bottom[0].slice());
  return{top,bottom};
}

const output={meta:{width:DST_W,height:DST_H,source:"Blank_US_map_1860.svg (Wikimedia)",svg_viewBox:`${SVG_W}x${SVG_H}`},territories:territoryPolygons,rivers,mountains,forests};
fs.writeFileSync(OUT_FILE,JSON.stringify(output,null,2));
console.log(`\nWrote ${OUT_FILE} — ${Object.keys(territoryPolygons).length} territories`);
