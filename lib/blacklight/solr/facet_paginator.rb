# -*- encoding : utf-8 -*-
module Blacklight::Solr
  

  # Pagination for facet values -- works by setting the limit to max
  # displayable. You have to ask Solr for limit+1, to get enough
  # results to see if 'more' are available'. That is, the all_facet_values
  # arg in constructor should be the result of asking solr for limit+1
  # values. 
  # This is a workaround for the fact that Solr itself can't compute
  # the total values for a given facet field,
  # so we cannot know how many "pages" there are.
  #
  class FacetPaginator    
    extend Deprecation

    self.deprecation_horizon = 'blacklight version 6.0.0'
    
    # What request keys will we use for the parameters need. Need to
    # make sure they do NOT conflict with catalog/index request params,
    # and need to make them accessible in a list so we can easily
    # strip em out before redirecting to catalog/index.
    # class variable (via class-level ivar)
    @request_keys = {:sort => :'facet.sort', :page => :'facet.page'}
    class << self; attr_accessor :request_keys end # create a class method
    def request_keys ; self.class.request_keys ; end # shortcut
    
    attr_reader :total_count, :items, :offset, :limit, :sort
    
    # all_facet_values is a list of facet value objects returned by solr,
    # asking solr for n+1 facet values.
    # options:
    # :limit =>  number to display per page, or (default) nil. Nil means
    #            display all with no previous or next. 
    # :offset => current item offset, default 0
    # :sort => 'count' or 'index', solr tokens for facet value sorting, default 'count'. 
    def initialize(all_facet_values, arguments)
      # to_s.to_i will conveniently default to 0 if nil
      @offset = arguments[:offset].to_s.to_i 
      @limit =  arguments[:limit].to_s.to_i
      # count is solr's default
      @sort = arguments[:sort] || "count" 
      @total_count = all_facet_values.size
      @items = items_for_limit(all_facet_values)
    end

    def prev_page
      current_page - 1 unless first_page?
    end

    def current_page
      if limit == 0 #check for divide by zero
        1
      else
        @offset / limit + 1
      end
    end

    def next_page
      current_page + 1 unless last_page?
    end
   
    #@deprecated
    def has_next?
      !last_page?
    end
    deprecation_deprecate :has_next?

    #@deprecated
    def has_previous?
      !first_page?
    end
    deprecation_deprecate :has_next?

    def last_page?
      current_page >= total_pages
    end

    def first_page?
      current_page == 1
    end

    def total_pages
      if limit == 0 #check for divide by zero
        1
      else
        (total_count.to_f / limit).ceil
      end
    end      

    # Pass in a desired solr facet solr key ('count' or 'index', see
    # http://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
    # under facet.sort ), and your current request params.
    # Get back params suitable to passing to an ActionHelper method for
    # creating a url, to resort by that method.
    def params_for_resort_url(sort_method, params)
      # When resorting, we've got to reset the offset to start at beginning,
      # no way to make it make sense otherwise.
      params.merge(request_keys[:sort] => sort_method, request_keys[:page] => nil)
    end

    private
      # setting limit to 0 implies no limit
      def items_for_limit(values)
        limit != 0 ? values.slice(offset, limit) : values
      end
  end
end
