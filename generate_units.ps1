$base = "https://image.pollinations.ai/prompt"
$root = "D:\Projects\CWG\assets\sprites\cards"
$seed = 1000
$timeout = 180

function Gen($prompt, $outPath) {
    $encoded = [System.Uri]::EscapeDataString($prompt)
    $url = "$base/$encoded?width=512&height=768&nologo=true&seed=$script:seed"
    Write-Host "[$script:seed] -> $(Split-Path $outPath -Leaf)"
    try {
            curl.exe -s -o $outPath $url --max-time $timeout 2>$null
        $size = (Get-Item $outPath -ErrorAction SilentlyContinue).Length
        if ($size -lt 10000) {
            Write-Host "  RETRY (too small: $size bytes)"
            $script:seed++
            $url = "$base/$([System.Uri]::EscapeDataString($prompt))?width=512&height=768&nologo=true&seed=$script:seed"
        curl.exe -s -o $outPath $url --max-time $timeout 2>$null
        }
        $size = (Get-Item $outPath -ErrorAction SilentlyContinue).Length
        Write-Host "  OK: $([math]::Round($size/1KB))KB"
    } catch {
        Write-Host "  FAILED: $_"
    }
    $script:seed++
}

$style = "19th century steel engraving style, Harper's Weekly illustration, detailed cross-hatching, fine linework, historical print, vintage woodcut engraving"
$blueTint = "sepia tones with subtle blue color tinting, blue dominant, UNION BLUE theme"
$redTint = "sepia tones with subtle red color tinting, red dominant, CONFEDERATE RED theme"

# === UNION INFANTRY (26) ===
$unionInfantry = @(
    @("u_inf_02wi", "2nd Wisconsin Infantry Iron Brigade charging through cornfield"),
    @("u_inf_06wi", "6th Wisconsin Infantry capturing Confederate train at Gettysburg railroad cut"),
    @("u_inf_07wi", "7th Wisconsin Infantry Iron Brigade in line of battle"),
    @("u_inf_19in", "19th Indiana Infantry Iron Brigade fighting in woods"),
    @("u_inf_24mi", "24th Michigan Infantry Iron Brigade taking heavy casualties at Gettysburg"),
    @("u_inf_69ny", "69th New York Fighting 69th Irish Brigade charging with green flags"),
    @("u_inf_63ny", "63rd New York Irish Brigade soldiers in battle"),
    @("u_inf_88ny", "88th New York Irish Brigade Connacht Rangers advancing"),
    @("u_inf_28ma", "28th Massachusetts Irish Brigade with Enfield rifles"),
    @("u_inf_116pa", "116th Pennsylvania Irish Brigade in formation"),
    @("u_inf_01mn", "1st Minnesota Infantry sacrificial charge at Gettysburg desperate attack"),
    @("u_inf_14ny", "14th Brooklyn New York Red Legged Devils in distinctive red trousers"),
    @("u_inf_44ny", "44th New York Ellsworths Avengers defending hill position"),
    @("u_inf_83pa", "83rd Pennsylvania Infantry defending position at Gettysburg"),
    @("u_inf_16mi", "16th Michigan Infantry defending rocky hill"),
    @("u_inf_54ma", "54th Massachusetts Colored Troops storming Fort Wagner coastal fortress"),
    @("u_inf_55ma", "55th Massachusetts Colored Troops on march"),
    @("u_inf_01us", "1st US Regular Army Infantry professional soldiers in formation"),
    @("u_inf_04us", "4th US Regular Army Infantry disciplined line"),
    @("u_inf_17us", "17th US Regular Army Infantry in battle"),
    @("u_inf_01kc", "1st Kansas Colored Infantry first Black combat unit fighting"),
    @("u_inf_04uc", "4th US Colored Infantry earning medals in assault"),
    @("u_inf_22ny", "22nd New York Eastern Iron Brigade marching"),
    @("u_inf_24ny", "24th New York Eastern Iron Brigade in camp"),
    @("u_inf_30ny", "30th New York Eastern Iron Brigade on patrol")
)

foreach ($card in $unionInfantry) {
    $prompt = "$style, $($card[1]), Union blue uniforms, $blueTint, dramatic composition, card game illustration"
    Gen $prompt "$root\units_union\$($card[0]).png"
}

# === CONFEDERATE INFANTRY (30) ===
$confInfantry = @(
    @("c_inf_02va", "2nd Virginia Infantry Stonewall Brigade in fierce combat"),
    @("c_inf_04va", "4th Virginia Infantry Stonewall Brigade Rockbridge Grays"),
    @("c_inf_05va", "5th Virginia Infantry Stonewall Brigade holding line"),
    @("c_inf_27va", "27th Virginia Infantry Stonewall Brigade standing like a stone wall"),
    @("c_inf_33va", "33rd Virginia Infantry Stonewall Brigade Shenandoah Sharpshooters"),
    @("c_inf_01tx", "1st Texas Infantry Hoods Brigade in brutal cornfield combat"),
    @("c_inf_04tx", "4th Texas Infantry Hoods Brigade advancing"),
    @("c_inf_05tx", "5th Texas Infantry Hoods Texas Brigade fighting"),
    @("c_inf_03ar", "3rd Arkansas Infantry only Trans-Mississippi regiment with Lee"),
    @("c_inf_18ga", "18th Georgia Infantry in battle line"),
    @("c_inf_01va", "1st Virginia Infantry Old First regiment in combat"),
    @("c_inf_07va", "7th Virginia Infantry Kempers Brigade in Picketts Charge"),
    @("c_inf_08va", "8th Virginia Infantry Bloody Eighth in fierce fighting"),
    @("c_inf_13va", "13th Virginia Infantry in valley campaign"),
    @("c_inf_03va", "3rd Virginia Infantry in defensive position"),
    @("c_inf_09va", "9th Virginia Infantry Confederate line of battle"),
    @("c_inf_11va", "11th Virginia Infantry at Gettysburg"),
    @("c_inf_17va", "17th Virginia Infantry in earthworks"),
    @("c_inf_18va", "18th Virginia Infantry defending position"),
    @("c_inf_24va", "24th Virginia Infantry Earlys Brigade"),
    @("c_hampton_inf", "Hamptons Legion Infantry elite South Carolina troops"),
    @("c_brig_garnett", "Garnetts Brigade Virginia Picketts Charge commander on horseback killed"),
    @("c_brig_armistead", "Armisteads Brigade High Water Mark Confederacy planting flag on Union lines"),
    @("c_brig_kemper", "Kempers Brigade Virginia Picketts Charge right flank"),
    @("c_brig_davis", "Davis Brigade Mississippi North Carolina Picketts Charge"),
    @("c_brig_lane", "Lanes Brigade North Carolina Picketts Charge"),
    @("c_brig_scales", "Scales Brigade North Carolina decimated before Charge"),
    @("c_brig_wilcox", "Wilcox Brigade Alabama supporting Picketts Charge"),
    @("c_brig_lang", "Lang Perry Brigade Florida in assault"),
    @("c_brig_brockenbrough", "Brockenbrough Brigade Virginia left flank breaking under fire")
)

foreach ($card in $confInfantry) {
    $prompt = "$style, $($card[1]), Confederate gray uniforms, $redTint, dramatic composition, card game illustration"
    Gen $prompt "$root\units_confederate\$($card[0]).png"
}

# === UNION CAVALRY (14) ===
$unionCav = @(
    @("u_cav_01us", "1st US Cavalry Regular Army mounted troops in review"),
    @("u_cav_02us", "2nd US Cavalry mounted soldiers on patrol"),
    @("u_cav_05us", "5th US Cavalry at Yellow Tavern cavalry battle"),
    @("u_cav_06us", "6th US Cavalry new regular cavalry regiment"),
    @("u_cav_02mi", "2nd Michigan Cavalry Sheridans first command"),
    @("u_cav_05mi", "5th Michigan Cavalry Custers Wolverines charging"),
    @("u_cav_06mi", "6th Michigan Cavalry Custers Brigade galloping"),
    @("u_cav_07mi", "7th Michigan Cavalry mounted charge"),
    @("u_cav_06pa", "6th Pennsylvania Cavalry Lancers on horseback"),
    @("u_cav_01ny_mr", "1st New York Mounted Rifles scouting"),
    @("u_cav_01wv", "1st West Virginia Cavalry Union loyalist horsemen"),
    @("u_cav_01vt", "1st Vermont Cavalry fighting partisans"),
    @("u_cav_05ny", "5th New York Cavalry pursuing guerrillas"),
    @("u_cav_13ny", "13th New York Cavalry on patrol duty")
)

foreach ($card in $unionCav) {
    $prompt = "$style, $($card[1]), Union cavalry blue uniforms horses, $blueTint, dramatic action, card game illustration"
    Gen $prompt "$root\units_union\$($card[0]).png"
}

# === CONFEDERATE CAVALRY (14) ===
$confCav = @(
    @("c_cav_02va", "2nd Virginia Cavalry Munford capturing prisoners at Second Bull Run"),
    @("c_cav_04va", "4th Virginia Cavalry Black Horse Cavalry elite troopers"),
    @("c_cav_07va", "7th Virginia Cavalry Ashbys regiment Shenandoah Valley Laurel Brigade"),
    @("c_cav_09va", "9th Virginia Cavalry ANV cavalry on march"),
    @("c_cav_11va", "11th Virginia Cavalry Laurel Brigade mounted"),
    @("c_cav_35va", "35th Virginia Cavalry White Comanches first into Gettysburg"),
    @("c_cav_08tx", "8th Texas Cavalry Terrys Rangers daring mounted raid"),
    @("c_cav_01tx", "1st Texas Cavalry Trans-Mississippi patrol"),
    @("c_cav_03tn", "3rd Tennessee Cavalry Forrests first regiment"),
    @("c_cav_laurel", "Laurel Brigade Rasser aggressive cavalry charge"),
    @("c_cav_hampton", "2nd South Carolina Cavalry Hampton elite troops"),
    @("c_cav_mcneill", "McNeills Rangers partisan guerrillas in mountains")
)

foreach ($card in $confCav) {
    $prompt = "$style, $($card[1]), Confederate cavalry gray butternut horses, $redTint, dramatic action, card game illustration"
    Gen $prompt "$root\units_confederate\$($card[0]).png"
}

# === UNION ARTILLERY (9) ===
$unionArt = @(
    @("u_art_B04us", "Battery B 4th US Light Artillery with Iron Brigade cannons firing"),
    @("u_art_01us", "1st US Artillery Regular Army cannon battery in action"),
    @("u_art_02us", "2nd US Artillery Tidballs Horse Artillery galloping guns"),
    @("u_art_05us", "1st US Artillery Regular battery firing volley"),
    @("u_art_01ct", "1st Connecticut Light Artillery 32-pounder howitzers firing"),
    @("u_art_01mn", "1st Minnesota Light Battery 3-inch Ordnance rifles"),
    @("u_art_13in", "13th Indiana Battery 12-pounder Napoleon guns"),
    @("u_art_07ny_h", "7th New York Heavy Artillery siege guns in fortress"),
    @("u_art_02uc", "2nd US Colored Artillery Black gunners serving cannons")
)

foreach ($card in $unionArt) {
    $prompt = "$style, $($card[1]), Union artillery crew, $blueTint, smoke and fire, dramatic, card game illustration"
    Gen $prompt "$root\units_union\$($card[0]).png"
}

# === CONFEDERATE ARTILLERY (11) ===
$confArt = @(
    @("c_art_washington", "Washington Artillery New Orleans elite militia cannons firing Try Us"),
    @("c_art_richmond", "Richmond Howitzers elegant battery in action"),
    @("c_art_palmetto", "Palmetto Artillery South Carolina cannon firing"),
    @("c_art_01rockbridge", "1st Rockbridge Artillery Stonewall Brigade cannons"),
    @("c_art_stuart_horse", "Stuarts Horse Artillery Gallant Pelham single gun holding flank"),
    @("c_art_purcell", "Purcell Artillery Pegrams battery ANV firing"),
    @("c_art_fredericksburg", "Fredericksburg Artillery steady battery"),
    @("c_art_staunton", "Staunton Artillery Valley campaign guns"),
    @("c_art_crenshaw", "Crenshaws Battery ANV light artillery"),
    @("c_art_hampton", "Hamptons Legion Artillery British Blakely rifled guns through blockade"),
    @("c_art_petersburg", "Petersburg Artillery horse artillery mobile guns")
)

foreach ($card in $confArt) {
    $prompt = "$style, $($card[1]), Confederate artillery crew, $redTint, smoke and fire, dramatic, card game illustration"
    Gen $prompt "$root\units_confederate\$($card[0]).png"
}

# === UNION FLEET (13) ===
$unionShips = @(
    @("u_ship_galena", "USS Galena ironclad sloop warship at sea"),
    @("u_ship_newironsides", "USS New Ironsides casemate ironclad broadside warship devastating firepower"),
    @("u_ship_cairo", "USS Cairo City-class river ironclad Pook Turtle western river"),
    @("u_ship_carondelet", "USS Carondelet river ironclad fighting on Mississippi"),
    @("u_ship_benton", "USS Benton flagship Mississippi Squadron powerful river ironclad"),
    @("u_ship_kearsarge", "USS Kearsarge sinking CSS Alabama naval battle at sea"),
    @("u_ship_cumberland", "USS Cumberland sail frigate being rammed going down fighting"),
    @("u_ship_moundcity", "USS Mound City river ironclad on Mississippi"),
    @("u_ship_louisville", "USS Louisville river ironclad Vicksburg campaign"),
    @("u_ship_essex", "USS Essex river ironclad converted snag boat"),
    @("u_ship_minnesota", "USS Minnesota steam frigate blockading squadron"),
    @("u_ship_vanderbilt", "USS Vanderbilt armed merchant ram steamer")
)

foreach ($card in $unionShips) {
    $prompt = "$style, $($card[1]), maritime engraving, $blueTint, dramatic seas, card game illustration"
    Gen $prompt "$root\units_union\$($card[0]).png"
}

# === CONFEDERATE FLEET (16) ===
$confShips = @(
    @("c_ship_virginia", "CSS Virginia casemate ironclad ram ship Hampton Roads terrifying"),
    @("c_ship_atlanta", "CSS Atlanta blockade runner converted ironclad warship"),
    @("c_ship_albemarle", "CSS Albemarle ironclad ram built in cornfield on river"),
    @("c_ship_tennessee", "CSS Tennessee flagship ironclad Battle of Mobile Bay"),
    @("c_ship_arkansas", "CSS Arkansas ironclad breaking through Union fleet at Vicksburg"),
    @("c_ship_alabama", "CSS Alabama Confederate raider sailing ship at sea sinking merchant vessels"),
    @("c_ship_shenandoah", "CSS Shenandoah raider sailing in Arctic waters last shot of war"),
    @("c_ship_hunley", "HL Hunley Confederate submarine underwater attack spar torpedo"),
    @("c_ship_patrick_henry", "CSS Patrick Henry river gunboat Hampton Roads"),
    @("c_ship_jamestown", "CSS Jamestown river gunboat capturing prizes"),
    @("c_ship_raleigh", "CSS Raleigh gunboat tender small warship"),
    @("c_ship_teaser", "CSS Teaser armed tugboat naval support"),
    @("c_ship_relee", "CSS Robert E Lee Scottish-built blockade runner steamer at night"),
    @("c_ship_syren", "SS Syren blockade runner ship slipping past warships"),
    @("c_ship_fingal", "SS Fingal blockade runner delivering rifles from Britain"),
    @("c_ship_sumter", "CSS Sumter first Confederate raider ship at sea")
)

foreach ($card in $confShips) {
    $prompt = "$style, $($card[1]), maritime engraving, $redTint, dramatic seas, card game illustration"
    Gen $prompt "$root\units_confederate\$($card[0]).png"
}

# === SPECIAL UNITS ===
$unionSpec = @(
    @("u_spec_berdan1", "Berdans 1st US Sharpshooters green uniform marksman with Sharps rifle aiming prone"),
    @("u_spec_berdan2", "2nd US Sharpshooters elite marksmen in green uniforms"),
    @("u_spec_ny_ss", "1st New York Sharpshooter Battalion precision rifle fire"),
    @("u_spec_ma_ss", "Massachusetts Sharpshooters Andrew Guards aiming rifles"),
    @("u_spec_lightning", "Wilders Lightning Brigade mounted infantry Spencer repeaters rapid fire"),
    @("u_spec_loudoun", "Loudoun Rangers Means Rangers only Virginia Union unit scouting"),
    @("u_spec_blazer", "Blazers Scouts independent scout company tracking partisans"),
    @("u_spec_1la_ng", "1st Louisiana Native Guard Colored Union free Creoles New Orleans")
)

foreach ($card in $unionSpec) {
    $prompt = "$style, $($card[1]), $blueTint, dramatic, card game illustration"
    Gen $prompt "$root\units_union\$($card[0]).png"
}

$confSpec = @(
    @("c_spec_forrest_escort", "Forrests Escort Company elite cavalry bodyguards 40-90 riders"),
    @("c_spec_forrest_corps", "Forrests Cavalry Corps Wizard of the Saddle revolutionary doctrine"),
    @("c_spec_forrest_div", "Forrests Cavalry Division bluffing enemy into surrender"),
    @("c_spec_va_irish", "1st Virginia Infantry Battalion Irish Confederate Irishmen fighting"),
    @("c_spec_1mo_cav", "1st Missouri Cavalry Company A representatives with Lees army")
)

foreach ($card in $confSpec) {
    $prompt = "$style, $($card[1]), $redTint, dramatic, card game illustration"
    Gen $prompt "$root\units_confederate\$($card[0]).png"
}

# === COMMANDERS ===
$commanders = @(
    @("union", "cmd_lincoln", "portrait of President Abraham Lincoln tall gaunt stovepipe hat beard melancholy wise, black suit, White House"),
    @("union", "cmd_grant", "portrait of General Ulysses S Grant Union commander blue uniform lieutenant general stars short beard cigar determined calm"),
    @("union", "cmd_sherman", "portrait of General William Tecumseh Sherman Union major general blue uniform red-haired beard fierce eyes gaunt"),
    @("union", "cmd_mcclellan", "portrait of General George McClellan Union major general blue uniform elegant young Napoleon on horseback reviewing troops"),
    @("union", "cmd_meade", "portrait of General George Meade Union major general blue uniform balding beard victor of Gettysburg"),
    @("union", "cmd_burnside", "portrait of General Ambrose Burnside Union major general blue uniform distinctive sideburn whiskers"),
    @("union", "cmd_hooker", "portrait of General Joseph Hooker Union major general blue uniform confident handsome commanding"),
    @("union", "cmd_sheridan", "portrait of General Philip Sheridan Union major general blue uniform short fiery cavalry commander on horseback"),
    @("union", "cmd_custer", "portrait of General George Armstrong Custer boy general brigadier general blue uniform long golden curls flamboyant"),
    @("union", "cmd_hancock", "portrait of General Winfield Scott Hancock Union major general blue uniform magnificent superb tall commanding presence"),
    @("union", "cmd_reynolds", "portrait of General John Reynolds Union major general blue uniform distinguished killed first day Gettysburg"),
    @("union", "cmd_chamberlain", "portrait of Colonel Joshua Chamberlain blue uniform beard academic turned soldier 20th Maine hero"),
    @("confederate", "cmd_jefferson", "portrait of President Jefferson Davis Confederate president gray suit thin austere dignified stern"),
    @("confederate", "cmd_relee", "portrait of General Robert E Lee Confederate commander gray uniform three stars white beard noble dignified Traveller horse"),
    @("confederate", "cmd_stonewall", "portrait of General Stonewall Jackson Confederate lieutenant general gray uniform dark beard intense eyes VMI professor"),
    @("confederate", "cmd_longstreet", "portrait of General James Longstreet Confederate lieutenant general gray uniform thick beard solid dependable Old War Horse"),
    @("confederate", "cmd_stuart", "portrait of General JEB Stuart Confederate cavalry major general gray uniform plumed hat golden curls dashing smile"),
    @("confederate", "cmd_aphill", "portrait of General AP Hill Confederate lieutenant general gray uniform thin intense Little Powell"),
    @("confederate", "cmd_forrest", "portrait of General Nathan Bedford Forrest Confederate lieutenant general rough uniform no insignia fierce intimidating mounted"),
    @("confederate", "cmd_johnston", "portrait of General Joseph Johnston Confederate general gray uniform dignified cautious strategic retreat master"),
    @("confederate", "cmd_bragg", "portrait of General Braxton Bragg Confederate general gray uniform stern quarrelsome strict disciplinarian"),
    @("confederate", "cmd_hood", "portrait of General John Bell Hood Confederate major general gray uniform one leg missing aggressive fighter"),
    @("confederate", "cmd_pickett", "portrait of General George Pickett Confederate major general gray uniform long hair theatrical dashing"),
    @("confederate", "cmd_early", "portrait of General Jubal Early Confederate lieutenant general gray uniform gaunt bitter sarcastic")
)

foreach ($cmd in $commanders) {
    $side = $cmd[0]
    $tint = if ($side -eq "union") { $blueTint } else { $redTint }
    $prompt = "$style, $($cmd[2]), formal portrait, $tint, card game illustration"
    $dir = if ($side -eq "union") { "units_union" } else { "units_confederate" }
    Gen $prompt "$root\$dir\$($cmd[1]).png"
}

Write-Host "`n=== GENERATION COMPLETE ==="
Write-Host "Total cards generated: $seed - 1000"
