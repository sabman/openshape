require 'OSM/Export.rb'
require 'csv'

module OSM

    module Export

        # This class handles exporting to CSV files.
        class CSV < Base

            def file(id, &block)
                file = CSVFile.new(id, @file_or_dir_name)
                file.init(&block)
            end

        end

        class CSVFile < Target

            def initialize(id, dir)
                @id = id
                @dir = dir
                @name = @id.to_s
                @fs = ','
                @rs = nil
                @fields = []
                @fields_alloc = Hash.new
                OSM::Export::Target << self
            end

            def name(name)
                @name = name
            end

            def fields(*fields)
                @fields = fields
                @fields.each_with_index do |field, index|
                    @fields_alloc[field] = index
                end
            end

            def fs(fs)
                @fs = fs
            end

            def rs(rs)
                @rs = rs
            end

            def _filename
                File.join(@dir, @name + '.csv')
            end

            def _open
                @fd = ::CSV.open(_filename, 'w', @fs, @rs)
            end

            def _commit
                @fd.close
                @fd = nil
            end

            def _add(object, args)
                fields = []
                args.each do |key, value|
                    fields[@fields_alloc[key]] = value
                end
                @fd << fields
            end

        end

    end

end

