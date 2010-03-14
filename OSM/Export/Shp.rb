require 'OSM/Export.rb'

module OSM

    module Export

        # This class handles exporting to ESRI Shapefiles.
        #
        # See http://www.clicketyclick.dk/databases/xbase/format/data_types.html for Shapefile data types.
        class Shp < Base

            def point(id, &block)
                file = ShpFile.new(id, @file_or_dir_name, GeoRuby::Shp4r::ShpType::POINT)
                file.init(&block)
            end

            def polyline(id, &block)
                file = ShpFile.new(id, @file_or_dir_name, GeoRuby::Shp4r::ShpType::POLYLINE)
                file.init(&block)
            end

            def polygon(id, &block)
                file = ShpFile.new(id, @file_or_dir_name, GeoRuby::Shp4r::ShpType::POLYGON)
                file.init(&block)
            end

        end

        class ShpFile < Target

            def initialize(id, dir, shptype)
                @id = id
                @dir = dir
                @name = @id.to_s
                @shptype = shptype
                @fields = []
                OSM::Export::Target << self
            end

            def name(name)
                @name = name
            end

            def string(id, size)
                _add_field(id, 'C', size)
            end

            def number(id, size)
                _add_field(id, 'N', size)
            end

            def boolean(id)
                _add_field(id, 'L', 1)
            end

            def _add_field(id, type, size)
                @fields << GeoRuby::Shp4r::Dbf::Field.new(id.to_s, type, size)
            end

            def _filename
                File.join(@dir, @name)
            end

            def _open
                @fd = GeoRuby::Shp4r::ShpFile.create(_filename, @shptype, @fields)
                @transaction = @fd.transaction
            end

            def _commit
                @transaction.commit
                open(_filename + '.prj', 'w') do |fh|
                    fh.puts 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]'
                end
                open(_filename + '.cpg', 'w') do |fh|
                    fh.puts 'UTF-8'
                end
            end

            def _add(object, attributes)
                begin
                    geom = case @shptype
                        when GeoRuby::Shp4r::ShpType::POINT    then object.point
                        when GeoRuby::Shp4r::ShpType::POLYLINE then object.linestring
                        when GeoRuby::Shp4r::ShpType::POLYGON  then object.polygon
                    end
                    @transaction.add(object.shape(geom, attributes))
                rescue OSM::GeometryError, OSM::NotClosedError
                    # just ignore this object if we can't get a geometry for it
                end
            end

        end

    end

end

