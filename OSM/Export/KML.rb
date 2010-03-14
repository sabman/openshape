require 'OSM/Export.rb'
require 'builder'

module OSM

    module Export

        module NameThingWithSubfolders

            def name(text=nil)
                if text.nil?
                    @name || @id.to_s
                else
                    @name = text
                end
            end

            def description(text=nil)
                if text.nil?
                    @description
                else
                    @description = text
                end
            end

            def folder(id, &block)
                newfolder = KMLFolder.new(id)
                @subfolders << newfolder
                newfolder.instance_eval(&block) if block_given?
            end

        end

        # This class handles exporting to KML files.
        class KML < Base

            include NameThingWithSubfolders

            def initialize(*args)
                @subfolders = []
                super(*args)
            end

            def commit
                File.open(@file_or_dir_name, 'w') do |file|
                    doc = Builder::XmlMarkup.new(:indent => 2, :target => file)
                    doc.kml do |xml|
                        xml.Document do
                            xml.name(name) unless name.nil?
                            xml.description(description) unless description.nil?
                            _copyright(xml)
                            @subfolders.each do |folder|
                                folder._out(xml)
                            end
                        end
                    end
                end
            end

            def _copyright(xml)
                xml.comment!('
Copyright (c) OpenStreetMap Contributors
http://www.openstreetmap.org/

This work is licensed under the
Creative Commons Attribution-ShareAlike 2.0 License.
http://creativecommons.org/licenses/by-sa/2.0/
')
                xml.ScreenOverlay(:id => 'CopyrightNotice') do
                    xml.name('Copyright Notice')
                    xml.description do
                        xml.cdata!('The data in this KML file is Copyright <a href="http://www.openstreetmap.org/">OpenStreetMap</a> Contributors. It is available under the <a href="http://creativecommons.org/licenses/by-sa/2.0/">Creative Commons Attribution-ShareAlike (CC-BY-SA) Version 2.0 License</a>.')
                    end
                    xml.Snippet('Copyright (c) OpenStreetMap Contributors. CC-BY-SA 2.0 License.')
                    xml.Icon do
                        xml.href('OSMCopyright.png')
                    end
                    xml.overlayXY(:x => '0', :y => '1', :xunits => 'fraction', :yunits => 'fraction')
                    xml.screenXY(:x => '0', :y => '1', :xunits => 'fraction', :yunits => 'fraction')
                    xml.size(:x => '0', :y => '0', :xunits => 'fraction', :yunits => 'fraction')
                end

            end

        end

        class KMLFolder < Target

            include NameThingWithSubfolders

            def initialize(id)
                @id = id
                @name = nil
                @description = nil
                @snippet = nil
                @style = nil
                @subfolders = []
                @placemarks = []

                OSM::Export::Target << self
            end

            def style(id=nil, &block)
                id = "style-#{@id}" if id.nil?
                @style = KMLStyle.new(id)
                @style.instance_eval(&block)
            end

            def _out(xml)
                xml.Folder do |xml|
                    xml.name(name) unless name.nil?
                    xml.description(description) unless description.nil?
                    @style._out(xml) unless @style.nil?
                    @subfolders.each do |folder|
                        folder._out(xml)
                    end
                    @placemarks.each do |placemark|
                        placemark._out(xml, @style.id)
                    end
                end
            end

            def _add(object, attributes)
                @placemarks << KMLPlacemark.new(attributes[:id], object.geometry, attributes)
            end

        end

        class KMLStyle

            attr_reader :id

            def initialize(id=nil)
                @id = id
                @iconstyle = nil
                @linestyle = nil
            end

            def icon(options)
                @iconstyle = options
            end

            def line(options)
                @linestyle = options
            end

            def _out(xml)
                xml.Style(:id => @id) do
                    if ! @iconstyle.nil?
                        xml.IconStyle do
                            xml.scale(@iconstyle[:scale]) if @iconstyle[:scale]
                            xml.Icon do
                                xml.href(@iconstyle[:href])
                            end
                        end
                    end
                    if ! @linestyle.nil?
                        xml.LineStyle do
                            xml.color(@linestyle[:color])
                            xml.width(@linestyle[:width])
                        end
                    end
                end
            end

        end

        class KMLPlacemark

            def initialize(id, geometry, options)
                @id = id
                @geometry = geometry
                @options = options
            end

            def _out(xml, style_id)
                xml.Placemark(:id => @id) do
                    xml.name(@options[:name]) if @options[:name]
                    xml.description(@options[:description]) if @options[:description]
                    xml.Snippet(@options[:snippet]) if @options[:snippet]
                    xml.styleUrl("##{style_id}")
                    case @geometry
                        when GeoRuby::SimpleFeatures::Point
                            xml.Point do
                                xml.coordinates("#{@geometry.x},#{@geometry.y},#{@options[:height] || 0}")
                            end
                        when GeoRuby::SimpleFeatures::LineString
                            xml.LineString do
                                xml.altitudeMode('relativeToGround')
                                xml.coordinates(@geometry.points.collect{ |p| "#{p.x},#{p.y},#{@options[:height] || 0}" }.join(' '))
                            end
                        when GeoRuby::SimpleFeatures::Polygon
                            xml.Polygon do
                                xml.altitudeMode('relativeToGround')
                                xml.outerBoundaryIs do
                                    xml.LinearRing do
                                        xml.coordinates(@geometry.points.collect{ |p| "#{p.x},#{p.y},#{@options[:height] || 0}" }.join(' '))
                                    end
                                end
                            end
                        else
                            raise ArgumentError.new('XXX')
                    end
                end
            end

        end

    end

end
