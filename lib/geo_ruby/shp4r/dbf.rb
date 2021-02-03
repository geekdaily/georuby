# Uses the dbf lib, Copyright 2006 Keith Morrison (http://infused.org)
# Modified to work as external gem now
require 'rubygems'
begin
  require 'dbf'
rescue LoadError
  puts "You've loaded GeoRuby SHP Support."
  puts "Please install the gem 'dbf' to use it. `gem install dbf`"
end

module GeoRuby
  # Ruby .shp files
  module Shp4r
    Dbf = DBF

    module Dbf
      class Record
        def [](v)
          attributes[v]
        end
      end

      # Allow field (column) creation with defaults for decimal, version, and encoding
      class Field < Column
        # TODO: Figure out how to unwind Field creation to be able to provide a DBF::Table

        # Shim class to address backward compatibility issues with DBF >= 2.0.13
        # 
        # Previous signature was (name, type, length, decimal, version, encoding)
        # v2.0.13 and later signature is (table, name, type, length, decimal)
        # with table expected to provide version and encoding
        class FauxTable
          attr_reader :version, :encoding

          def initialize(version, encoding)
            @version, @encoding = version, encoding
          end
        end

        def initialize(name, type, length, decimal = 0, version = 1, enc = nil)
          table = FauxTable.new(version, enc)
          super(table, name, type, length, decimal)
        end
      end

      # Main DBF File Reader
      class Reader < Table
        alias_method :fields, :columns

        def self.open(f)
          new(f)
        end

        def close
          nil
        end
      end
    end
  end
end
