require 'OSM/Export.rb'
$: << '../../../ruby-gpx/trunk/lib'
require 'gpx'

module OSM

    module Export

        # This class handles exporting to GPX files.
        class GPX < Base

            def initialize(*args)
                super
                @gpx = ::GPX::GPXFile.new(:waypoints => [])
                waypoints = GPXWaypoints.new(@gpx)
                trackpoints = GPXTrackpoints.new(@gpx)
                routes = GPXRoutes.new(@gpx)
            end

            def commit
                @gpx.write(@file_or_dir_name)
            end

        end

        class GPXTarget < Target

        end

        class GPXWaypoints < GPXTarget

            def initialize(gpx)
                @id = :waypoints
                @gpx = gpx
                OSM::Export::Target << self
            end

            def _add(object, attributes)
                wp = ::GPX::Waypoint.new
                wp.lon = object.lon
                wp.lat = object.lat
                wp.name = attributes[:name]
                wp.sym = attributes[:sym]
                wp.desc = attributes[:desc]
                @gpx.waypoints << wp
            end

        end

        class GPXTrackpoints < GPXTarget

            def initialize(gpx)
                @id = :trackpoints
                @gpx = gpx
                OSM::Export::Target << self
            end

            def _add(object, attributes)
            end

        end

        class GPXRoutes < GPXTarget

            def initialize(gpx)
                @id = :routes
                @gpx = gpx
                OSM::Export::Target << self
            end

            def _add(object, attributes)
            end

        end

    end

end

