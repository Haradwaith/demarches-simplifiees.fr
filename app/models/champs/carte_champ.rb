class Champs::CarteChamp < Champ
  # We are not using scopes here as we want to access
  # the following collections on unsaved records.
  def cadastres
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:cadastre)
    end
  end

  def quartiers_prioritaires
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:quartier_prioritaire)
    end
  end

  def parcelles_agricoles
    geo_areas.filter do |area|
      area.source == GeoArea.sources.fetch(:parcelle_agricole)
    end
  end

  def selection_utilisateur
    geo_areas.find(&:selection_utilisateur?)
  end

  def cadastres?
    type_de_champ&.cadastres && type_de_champ.cadastres != '0'
  end

  def quartiers_prioritaires?
    type_de_champ&.quartiers_prioritaires && type_de_champ.quartiers_prioritaires != '0'
  end

  def parcelles_agricoles?
    type_de_champ&.parcelles_agricoles && type_de_champ.parcelles_agricoles != '0'
  end

  def position
    if dossier.present?
      dossier.geo_position
    else
      lon = "2.428462"
      lat = "46.538192"
      zoom = "13"

      { lon: lon, lat: lat, zoom: zoom }
    end
  end

  def geo_json
    @geo_json ||= begin
      geo_area = selection_utilisateur

      if geo_area
        geo_area.geometry
      else
        geo_json_from_value
      end
    end
  end

  def selection_utilisateur_size
    if geo_json.present?
      geo_json['coordinates'].size
    else
      0
    end
  end

  def to_render_data
    {
      position: position,
      selection: user_geo_area&.geometry,
      quartiersPrioritaires: quartiers_prioritaires? ? quartiers_prioritaires.as_json(except: :properties) : [],
      cadastres: cadastres? ? cadastres.as_json(except: :properties) : [],
      parcellesAgricoles: parcelles_agricoles? ? parcelles_agricoles.as_json(except: :properties) : []
    }
  end

  def user_geo_area
    geo_area = selection_utilisateur

    if geo_area.present?
      geo_area
    elsif geo_json_from_value.present?
      GeoArea.new(
        geometry: geo_json_from_value,
        source: GeoArea.sources.fetch(:selection_utilisateur)
      )
    end
  end

  def geo_json_from_value
    @geo_json_from_value ||= begin
      parsed_value = value.blank? ? nil : JSON.parse(value)
      # We used to store in the value column a json array with coordinates.
      if parsed_value.is_a?(Array)
        # Empty array is sent instead of blank to distinguish between empty and error
        if parsed_value.empty?
          nil
        else
          # If it is a coordinates array, format it as a GEO-JSON
          JSON.parse(GeojsonService.to_json_polygon_for_selection_utilisateur(parsed_value))
        end
      else
        # It is already a GEO-JSON
        parsed_value
      end
    end
  end

  def for_api
    nil
  end

  def for_export
    nil
  end
end
