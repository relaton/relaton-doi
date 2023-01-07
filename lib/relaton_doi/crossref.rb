module RelatonDoi
  module Crossref
    extend self

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
      warn "[relaton-doi] [\"#{doi}\"] fetching..."
      id = doi.sub(%r{^doi:}, "")
      message = get_by_id id
      warn "[relaton-doi] [\"#{doi}\"] found #{message['DOI']}"
      Parser.parse message
    end

    #
    # Get a document by DOI from the CrossRef API.
    #
    # @param [String] id The DOI.
    #
    # @return [Hash] The document.
    #
    def get_by_id(id)
      resp = Serrano.works ids: id
      resp[0]["message"]
    end
  end
end
