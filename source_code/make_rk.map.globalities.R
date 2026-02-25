local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.08-1")

  plugin_name <- "rk.map.globalities"
  plugin_ver <- "0.0.1"

  package_about <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Downloads and creates Planispheres or Regional maps (Continents/Subregions) using 'rnaturalearth'. Includes built-in projection tools for aesthetic world maps.",
      version = plugin_ver,
      date = format(Sys.Date(), "%Y-%m-%d"),
      url = "https://github.com/AlfCano/rk.map.globalities",
      license = "GPL (>= 3)"
    )
  )

  # =========================================================================================
  # 2. UI Components
  # =========================================================================================

  # Region Selection
  region_opts <- list(
      "Whole World" = list(val = "world", chk = TRUE),
      "Afro-Eurasia (The Old World)" = list(val = "afro_eurasia"),
      "Americas (The New World)" = list(val = "americas"),

      "--- AMERICAS (Subregions) ---" = list(val = "sep1", enabled = FALSE),
      "North America (Continent)" = list(val = "North America"),
      "South America (Continent)" = list(val = "South America"),
      "Central America" = list(val = "Central America"),
      "Caribbean" = list(val = "Caribbean"),

      "--- EUROPE ---" = list(val = "sep4", enabled = FALSE),
      "Europe (Whole Continent)" = list(val = "Europe"),
      "Western Europe" = list(val = "Western Europe"),
      "Eastern Europe" = list(val = "Eastern Europe"),
      "Northern Europe" = list(val = "Northern Europe"),
      "Southern Europe" = list(val = "Southern Europe"),

      "--- AFRICA ---" = list(val = "sep2", enabled = FALSE),
      "Africa (Whole Continent)" = list(val = "Africa"),
      "North Africa" = list(val = "Northern Africa"),
      "Sub-Saharan Africa" = list(val = "sub_saharan"),

      "--- ASIA ---" = list(val = "sep3", enabled = FALSE),
      "Asia (Whole Continent)" = list(val = "Asia"),
      "Central Asia" = list(val = "Central Asia"),
      "East Asia" = list(val = "Eastern Asia"),
      "South Asia" = list(val = "Southern Asia"),
      "South-East Asia" = list(val = "South-Eastern Asia"),
      "West Asia (Middle East)" = list(val = "Western Asia"),

      "--- OCEANIA ---" = list(val = "sep5", enabled = FALSE),
      "Oceania" = list(val = "Oceania")
  )

  drp_region <- rk.XML.dropdown(label = "Select Region", id.name = "drp_region", options = region_opts)

  # Data Detail
  drp_scale <- rk.XML.dropdown(label = "Map Resolution", id.name = "drp_scale", options = list(
      "Low (1:110m) - Fast" = list(val = "110", chk = TRUE),
      "Medium (1:50m) - Standard" = list(val = "50"),
      "High (1:10m) - Detailed" = list(val = "10")
  ))

  # Filtering Options
  chk_antarc <- rk.XML.cbox(label = "Exclude Antarctica (Recommended for thematic maps)", id.name = "ex_antarc", value = "1", chk = TRUE)

  # Projection Options
  frame_proj <- rk.XML.frame(label = "Projection (Planisphere Style)",
      rk.XML.dropdown(label = "Transform CRS", id.name = "drp_crs", options = list(
          "None (WGS84 Lat/Lon)" = list(val = "none"),
          "Robinson (Standard World Map)" = list(val = "ESRI:54030", chk = TRUE),
          "Winkel Tripel (NatGeo Standard)" = list(val = "ESRI:54042"),
          "Mollweide (Equal Area)" = list(val = "ESRI:54009"),
          "Mercator (Web Standard)" = list(val = "3857")
      ))
  )

  # Output
  save_map <- rk.XML.saveobj(label = "Save Map Object As (sf)", initial = "world_map", id.name = "save_obj", chk = TRUE)

  # Dialog Layout
  main_dialog <- rk.XML.dialog(
      label = "Download Global/Regional Maps",
      child = rk.XML.row(
          rk.XML.col(
              rk.XML.frame(label = "1. Region & Quality",
                  drp_region,
                  drp_scale,
                  chk_antarc
              ),
              frame_proj,
              rk.XML.stretch(),
              save_map
          )
      )
  )

  # =========================================================================================
  # 3. JavaScript Logic
  # =========================================================================================

  js_calc <- '
    var region = getValue("drp_region");
    var scale = getValue("drp_scale");
    var no_antarc = getValue("ex_antarc");
    var crs = getValue("drp_crs");

    echo("## 1. Download Base Data\\n");
    // We use ne_countries to get the whole world first
    echo("raw_world <- rnaturalearth::ne_countries(scale = " + scale + ", returnclass = \\"sf\\")\\n\\n");

    echo("## 2. Filter Region\\n");

    if (region == "world") {
        echo("map_filtered <- raw_world\\n");
    }
    else if (region == "afro_eurasia") {
        echo("map_filtered <- subset(raw_world, continent %in% c(\\"Africa\\", \\"Europe\\", \\"Asia\\"))\\n");
    }
    else if (region == "americas") {
        echo("map_filtered <- subset(raw_world, continent %in% c(\\"North America\\", \\"South America\\"))\\n");
    }
    else if (region == "sub_saharan") {
        echo("map_filtered <- subset(raw_world, subregion != \\"Northern Africa\\" & continent == \\"Africa\\")\\n");
    }
    else if (region == "North America" || region == "South America" || region == "Africa" || region == "Asia" || region == "Europe" || region == "Oceania") {
        // Continent level
        echo("map_filtered <- subset(raw_world, continent == \\"" + region + "\\")\\n");
    }
    else {
        // Subregion level (Central America, Western Europe, etc.) matches standard Natural Earth names
        echo("map_filtered <- subset(raw_world, subregion == \\"" + region + "\\")\\n");
    }

    if (no_antarc == "1") {
        echo("map_filtered <- subset(map_filtered, iso_a3 != \\"ATA\\")\\n");
    }

    echo("\\n## 3. Projection\\n");
    if (crs != "none") {
        echo("map_final <- sf::st_transform(map_filtered, crs = \\"" + crs + "\\")\\n");
    } else {
        echo("map_final <- map_filtered\\n");
    }
  '

  js_print <- '
    echo("rk.header(\\"Global/Regional Map Generated\\")\\n");
    echo("rk.print(paste(\\"Region:\\", \\"" + getValue("drp_region") + "\\"))\\n");
    echo("rk.print(paste(\\"Projection:\\", \\"" + getValue("drp_crs") + "\\"))\\n");
    echo("rk.print(paste(\\"Features:\\", nrow(map_final)))\\n");

    if (getValue("save_obj.active")) {
        echo(getValue("save_obj") + " <- map_final\\n");
    }
  '

  # =========================================================================================
  # 4. Assembly
  # =========================================================================================

  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = main_dialog),
    js = list(
        require = c("rnaturalearth", "sf", "dplyr"),
        calculate = js_calc,
        printout = js_print
    ),
    pluginmap = list(
        name = "Download Global/Regional Maps",
        hierarchy = list("plots", "Maps")
        # po_id removed (auto-generated)
    ),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )

  cat("\nPlugin 'rk.map.globalities' (v0.0.1) generated successfully.\n")
})
