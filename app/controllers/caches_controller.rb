class CachesController < ApplicationController

  def create
    # for each url in the params, find which cache strategies it is applicable to
    @caches = Cache.instances_for(CacheConfigMatcher.sort_urls_into_hashes(params),params)

    # Constructing response
    resp = {}
    CacheConfigMatcher.urls_as_array(params).map{|u| resp[u] = nil}

    # Add cache objects to queues
    @caches.each do |cache|
      queued = CacheClearer.push_to_queue(cache.basename, [cache])
      cache.urls.each do |c|
        resp[c]||=[]
        resp[c] << (queued ? "Added to #{cache.strategy} queue" : "#{cache.basename} queue did not respond while adding #{c}")
      end
    end

    # Respond with the outcome of each purge url in the params: queued/error/missing config
    resp.each do |k,v|
      resp[k] = v ? v.uniq : "Could not find cache config for '#{k}'"
    end
    render json: resp
  end

end
