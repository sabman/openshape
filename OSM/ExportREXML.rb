
require 'OSM/StreamParserREXML.rb'

module OSM

    module Export

        VERSION = '0.1.2'
   
        # Parser class for OSM exports.
        #
        # Use as follows:
        #
        #    parser = OSM::Export::Parser.new(OSMFILENAME, MAPPER)
        #    parser.parse
        #
        # The parser will then (for each Node, Way, and Relation) call the right methods on the mapper class
        # (a subclass of OSM::Export::Base) which will do the mapping of the data to the destination format.
        #
        class Parser < OSM::StreamParserREXML

            # Create new parser instance. The filename must be the name of an OSM XML file. The
            # mapper argument is an instance of one of the subclasses of OSM::Export::Base.
            def initialize(filename, mapper)
                @mapper = mapper
                @db = OSM::Database.new
                super(:filename => filename, :db => @db, :callbacks => OSM::Export::Callbacks.new(mapper, @db))
            end

        end

        class Callbacks < OSM::CallbacksREXML

            def initialize(mapper, db)
                super()
                @mapper = mapper
                @db = db
            end

            # This method is called by the parser whenever an OSM::Node has been parsed.
            def node(node)  # :nodoc:
                @mapper.run_node(@db, node)
                true
            end
            
            # This method is called by the parser whenever an OSM::Way has been parsed.
            def way(way) # :nodoc:
                @db << way
                @mapper.run_way(@db, way)
                false
            end

            # This method is called by the parser whenever an OSM::Relation has been parsed.
            def relation(relation) # :nodoc:
                @db << relation
                @mapper.run_relation(@db, relation)
                false
            end

        end

        # This is the virtual base class for all export mappers. See
        # OSM::Export::KML, OSM::Export::Shp, OSM::Export::CSV.
        class Base

            def initialize(file_or_dir_name) # :nodoc:
                @file_or_dir_name = file_or_dir_name
                @nodes = nil
                @ways = nil
                @relations = nil
            end

            def run_node(db, node) # :nodoc:
                return if @nodes.nil?   # return if there are no rules for nodes
                $osmexport_context = node
                node.instance_eval(&@nodes)
            end

            def run_way(db, way) # :nodoc:
                return if @ways.nil?    # return if there are no rules for ways
                $osmexport_context = way
                way.instance_eval(&@ways)
            end

            def run_relation(db, relation) # :nodoc:
                return if @relations.nil?    # return if there are no rules for relations
                $osmexport_context = relation
                relation.instance_eval(&@relations)
            end

            def commit
                OSM::Export::Target.targets.each { |target| target._commit }
            end

            private

            def setup(type)
                $osmexport_context = nil
                yield
            end

            def nodes(&block)
                @nodes = block
            end

            def ways(&block)
                @ways = block
            end

            def relations(&block)
                @relations = block
            end

        end

        # Virtual base class for OSM export targets.
        class Target

            @@targets = Hash.new

            attr_reader :id

            def self.[](targetsym)
                @@targets[targetsym.to_sym]
            end

            def self.<<(target)
                @@targets[target.id.to_sym] = target
            end

            def self.targets
                @@targets.values
            end

            def init(&block)
                instance_eval(&block) if block_given?
                _open
            end

        end

    end

end

class Symbol

    def <<(attributes)
        if OSM::Export::Target[self].nil?
            raise NameError.new("no target called :#{self}")
        end
        OSM::Export::Target[self]._add($osmexport_context, attributes)
    end

end

