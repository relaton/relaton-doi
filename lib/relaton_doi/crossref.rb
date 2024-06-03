require "faraday"

module RelatonDoi
  module Crossref
    extend self

    HEADER = {
      "User-Agent" => "Relaton/RelatonDoi (https://www.relaton.org/guides/doi/; mailto:open.source@ribose.com)"
    }.freeze

    #
    # Get a document by DOI from the CrossRef API.
    #
    # @param [String] doi The DOI.
    #
    # @return [RelatonBib::BibliographicItem, RelatonIetf::IetfBibliographicItem,
    #   RelatonBipm::BipmBibliographicItem, RelatonIeee::IeeeBibliographicItem,
    #   RelatonNist::NistBibliographicItem] The bibitem.
    #
    def get(doi)
      Util.warn "(#{doi}) Fetching from search.crossref.org ..."
      id = doi.sub(%r{^doi:}, "")
      message = get_by_id id
      if message
        Util.warn "(#{doi}) Found: `#{message['DOI']}`"
        Parser.parse message
      else
        Util.warn("(#{doi}) Not found.")
        nil
      end
    end

    #
    # Get a document by DOI from the CrossRef API.
    #
    # @param [String] id The DOI.
    #
    # @return [Hash] The document.
    #
    def get_by_id(id)
      # resp = Serrano.works ids: id
      n = 0
      url = "https://api.crossref.org/works/#{CGI.escape(id)}"
      loop do
        resp = Faraday.get url, nil, HEADER
        case resp.status
        when 200
          work = JSON.parse resp.body
          return work["message"] if work["status"] == "ok"
        when 404 then return nil
        end

        if n > 1
          raise RelatonBib::RequestError, "Crossref error: #{resp.body}"
        end
        n += 1
        sleep resp.headers["x-rate-limit-interval"].to_i * n
      end
    end
  end
end
