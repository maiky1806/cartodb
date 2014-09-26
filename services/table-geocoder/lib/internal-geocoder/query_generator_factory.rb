# encoding: utf-8

require_relative 'input_type_resolver'

require_relative 'cities_text_points'
require_relative 'cities_column_points'
require_relative 'admin1_text_points'

module CartoDB
  module InternalGeocoder

    class QueryGeneratorFactory

      class QueryGeneratorNotImplemented < StandardError; end

      class << self
        private :new

        def get(internal_geocoder, input_type=nil)
          input_type ||= InputTypeResolver.new(internal_geocoder).type

          case input_type
            when [:namedplace, :text, :point]
              CitiesTextPoints.new internal_geocoder
            when [:namedplace, :column, :point]
              CitiesColumnPoints.new internal_geocoder
            when [:admin1, :text, :polygon]
              Admin1TextPoints.new internal_geocoder
            else
              raise QueryGeneratorNotImplemented. new "QueryGenerator not implemented for input type #{input_type}"
          end
        end
      end


    end # QueryGeneratorFactory

  end # InternalGeocoder
end #CartoDB