module GeoRuby
  # Raised when an error in the GeoRSS string is detected
  class GeorssFormatError < StandardError
  end

  # Contains tags possibly found on GeoRss Simple geometries
  class GeorssTags < Struct.new(:featuretypetag, :relationshiptag,
                                :elev, :floor, :radius)
  end

  # Parses GeoRSS strings
  # You can also use directly the static method Geometry.from_georss
  class GeorssParser
    include GeoRuby::SimpleFeatures
    attr_reader :georss_tags, :geometry

    GEORSS_REGEX = /=['"]([^"']*)['"]/

    # Parses the georss geometry  passed as argument and notifies
    # the factory of events the parser assumes
    def parse(georss, with_tags = false)
      @geometry = nil
      @georss_tags = GeorssTags.new
      parse_geometry(georss, with_tags)
    end

    private

    def parse_geometry(georss, with_tags)
      georss.strip!
      # check for W3CGeo first
      if georss =~ /<[^:>]*:lat\s*>([^<]*)</
        # if valid, it is W3CGeo
        lat = Regexp.last_match[1].to_f
        if georss =~ /<[^:>]*:long\s*>([^<]*)</
          lon = Regexp.last_match[1].to_f
          @geometry = Point.from_x_y(lon, lat)
        else
          fail GeorssFormatError, 'Bad W3CGeo GeoRSS format'
        end
      elsif georss =~ /^<\s*[^:>]*:where\s*>/
        # GML format found
        gml = $'.strip
        if gml =~ /^<\s*[^:>]*:Point\s*>/
          # gml point
          if gml =~ /<\s*[^:>]*:pos\s*>([^<]*)/
            point = Regexp.last_match[1].split(' ')
            # lat comes first
            @geometry = Point.from_x_y(point[1].to_f, point[0].to_f)
          else
            fail GeorssFormatError, 'Bad GML GeoRSS: Malformed Point'
          end
        elsif gml =~ /^<\s*[^:>]*:LineString\s*>/
          if gml =~ /<\s*[^:>]*:posList\s*>([^<]*)/
            xy = Regexp.last_match[1].split(' ')
            @geometry = LineString.new
            0.upto(xy.size / 2 - 1) do |index|
              @geometry << Point.from_x_y(xy[index * 2 + 1].to_f,
                                          xy[index * 2].to_f)
            end
          else
            fail GeorssFormatError, 'Bad GML GeoRSS: Malformed LineString'
          end
        elsif gml =~ /^<\s*[^:>]*:Polygon\s*>/
          if gml =~ /<\s*[^:>]*:posList\s*>([^<]*)/
            xy = Regexp.last_match[1].split(' ')
            @geometry = Polygon.new
            linear_ring = LinearRing.new
            @geometry << linear_ring
            xy = Regexp.last_match[1].split(' ')
            0.upto(xy.size / 2 - 1) do |index|
              linear_ring << Point.from_x_y(xy[index * 2 + 1].to_f,
                                            xy[index * 2].to_f)
            end
          else
            fail GeorssFormatError, 'Bad GML GeoRSS: Malformed Polygon'
          end
        elsif gml =~ /^<\s*[^:>]*:Envelope\s*>/
          if gml =~ /<\s*[^:>]*:lowerCorner\s*>([^<]*)</
            lc = Regexp.last_match[1].split(' ').collect(&:to_f).reverse
            if gml =~ /<\s*[^:>]*:upperCorner\s*>([^<]*)</
              uc = Regexp.last_match[1].split(' ').collect(&:to_f).reverse
              @geometry = Envelope.from_coordinates([lc, uc])
            else
              fail GeorssFormatError, 'Bad GML GeoRSS: Malformed Envelope'
            end
          else
            fail GeorssFormatError, 'Bad GML GeoRSS: Malformed Envelope'
          end
        else
          fail GeorssFormatError, 'Bad GML GeoRSS: Unknown geometry type'
        end
      else
        # must be simple format
        if georss =~ /^<\s*[^>:]*:point([^>]*)>(.*)</m
          tags = Regexp.last_match[1]
          point = Regexp.last_match[2].gsub(',', ' ').split(' ')
          @geometry = Point.from_x_y(point[1].to_f, point[0].to_f)
        elsif georss =~ /^<\s*[^>:]*:line([^>]*)>(.*)</m
          tags = Regexp.last_match[1]
          @geometry = LineString.new
          xy = Regexp.last_match[2].gsub(',', ' ').split(' ')
          0.upto(xy.size / 2 - 1) do |index|
            @geometry << Point.from_x_y(xy[index * 2 + 1].to_f,
                                        xy[index * 2].to_f)
          end
        elsif georss =~ /^<\s*[^>:]*:polygon([^>]*)>(.*)</m
          tags = Regexp.last_match[1]
          @geometry = Polygon.new
          linear_ring = LinearRing.new
          @geometry << linear_ring
          xy = Regexp.last_match[2].gsub(',', ' ').split(' ')
          0.upto(xy.size / 2 - 1) do |index|
            linear_ring << Point.from_x_y(xy[index * 2 + 1].to_f,
                                          xy[index * 2].to_f)
          end
        elsif georss =~ /^<\s*[^>:]*:box([^>]*)>(.*)</m
          tags = Regexp.last_match[1]
          corners = []
          xy = Regexp.last_match[2].gsub(',', ' ').split(' ')
          0.upto(xy.size / 2 - 1) do |index|
            corners << Point.from_x_y(xy[index * 2 + 1].to_f,
                                      xy[index * 2].to_f)
          end
          @geometry = Envelope.from_points(corners)
        else
          fail GeorssFormatError, 'Bad Simple GeoRSS format: ' \
                                  'Unknown geometry type'
        end

        # geometry found: parse tags
        return unless with_tags
        if tags =~ /featuretypetag#{GEORSS_REGEX}/
          @georss_tags.featuretypetag = Regexp.last_match[1]
        end

        if tags =~ /relationshiptag#{GEORSS_REGEX}/
          @georss_tags.relationshiptag = Regexp.last_match[1]
        end

        if tags =~ /elev#{GEORSS_REGEX}/
          @georss_tags.elev = Regexp.last_match[1].to_f
        end

        if tags =~ /floor#{GEORSS_REGEX}/
          @georss_tags.floor = Regexp.last_match[1].to_i
        end

        if tags =~ /radius#{GEORSS_REGEX}/
          @georss_tags.radius = Regexp.last_match[1].to_f
        end

      end
    end
  end
end
