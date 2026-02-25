// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(rnaturalearth)\n");	echo("require(sf)\n");	echo("require(dplyr)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var region = getValue("drp_region");
    var scale = getValue("drp_scale");
    var no_antarc = getValue("ex_antarc");
    var crs = getValue("drp_crs");

    echo("## 1. Download Base Data\n");
    // We use ne_countries to get the whole world first
    echo("raw_world <- rnaturalearth::ne_countries(scale = " + scale + ", returnclass = \"sf\")\n\n");

    echo("## 2. Filter Region\n");

    if (region == "world") {
        echo("map_filtered <- raw_world\n");
    }
    else if (region == "afro_eurasia") {
        echo("map_filtered <- subset(raw_world, continent %in% c(\"Africa\", \"Europe\", \"Asia\"))\n");
    }
    else if (region == "americas") {
        echo("map_filtered <- subset(raw_world, continent %in% c(\"North America\", \"South America\"))\n");
    }
    else if (region == "sub_saharan") {
        echo("map_filtered <- subset(raw_world, subregion != \"Northern Africa\" & continent == \"Africa\")\n");
    }
    else if (region == "North America" || region == "South America" || region == "Africa" || region == "Asia" || region == "Europe" || region == "Oceania") {
        // Continent level
        echo("map_filtered <- subset(raw_world, continent == \"" + region + "\")\n");
    }
    else {
        // Subregion level (Central America, Western Europe, etc.) matches standard Natural Earth names
        echo("map_filtered <- subset(raw_world, subregion == \"" + region + "\")\n");
    }

    if (no_antarc == "1") {
        echo("map_filtered <- subset(map_filtered, iso_a3 != \"ATA\")\n");
    }

    echo("\n## 3. Projection\n");
    if (crs != "none") {
        echo("map_final <- sf::st_transform(map_filtered, crs = \"" + crs + "\")\n");
    } else {
        echo("map_final <- map_filtered\n");
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Download Global/Regional Maps results")).print();

    echo("rk.header(\"Global/Regional Map Generated\")\n");
    echo("rk.print(paste(\"Region:\", \"" + getValue("drp_region") + "\"))\n");
    echo("rk.print(paste(\"Projection:\", \"" + getValue("drp_crs") + "\"))\n");
    echo("rk.print(paste(\"Features:\", nrow(map_final)))\n");

    if (getValue("save_obj.active")) {
        echo(getValue("save_obj") + " <- map_final\n");
    }
  
	//// save result object
	// read in saveobject variables
	var saveObj = getValue("save_obj");
	var saveObjActive = getValue("save_obj.active");
	var saveObjParent = getValue("save_obj.parent");
	// assign object to chosen environment
	if(saveObjActive) {
		echo(".GlobalEnv$" + saveObj + " <- world_map\n");
	}

}

