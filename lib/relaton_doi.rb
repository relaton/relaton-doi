# frozen_string_literal: true

# require "serrano"
require "relaton_bipm"
# require "relaton_iso_bib"
# require "relaton_w3c"
require "relaton_ietf"
require "relaton_ieee"
require "relaton_nist"
require_relative "relaton_doi/version"
require_relative "relaton_doi/util"
require_relative "relaton_doi/parser"
require_relative "relaton_doi/crossref"

# Serrano.configuration do |config|
#   config.mailto = "open.source@ribose.com"
# end

module RelatonDoi
  extend self

  def grammar_hash
    Digest::MD5.hexdigest(
      RelatonNist::VERSION + RelatonIetf::VERSION + RelatonIeee::VERSION + RelatonBipm::VERSION + RelatonBib::VERSION,
    )
  end
end
