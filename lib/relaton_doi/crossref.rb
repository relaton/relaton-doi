module RelatonDoi
  class Crossref
    REALATION_TYPES = {
      "is-preprint-of" => "reprintOf",
      "is-review-of" => "reviewOf",
      "has-review" => "hasReview",
      "is-identical-to" => "identicalTo", # ?
      "is-supplement-to" => "complements",
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
    def self.get(doi)
      new.get doi
    end

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
      resp = Serrano.works ids: id
      @message = resp[0]["message"]
      warn "[relaton-doi] [\"#{doi}\"] found #{@message['DOI']}"
      create_bibitem @message["DOI"], bibitem_hash
    end

    #
    # Create a bibitem from the bibitem hash.
    #
    # @param [String] doi The DOI.
    # @param [Hash] bibitem The bibitem hash.
    #
    # @return [RelatonBib::BibliographicItem, RelatonIetf::IetfBibliographicItem,
    #   RelatonBipm::BipmBibliographicItem, RelatonIeee::IeeeBibliographicItem,
    #   RelatonNist::NistBibliographicItem] The bibitem.
    #
    # @raise [RelatonDoi::Error] if the document type is not supported.
    #
    def create_bibitem(doi, bibitem) # rubocop:disable Metrics/CyclomaticComplexity
      # case @message["institution"]&.first&.fetch("acronym")&.first
      case doi
      when /\/nist/ then RelatonNist::NistBibliographicItem.new(**bibitem)
      when /\/rfc\d+/ then RelatonIetf::IetfBibliographicItem.new(**bibitem)
      when /\/0026-1394\// then RelatonBipm::BipmBibliographicItem.new(**bibitem)
      # when "ISO" then RelatonIso::IsoBibliographicItem.new(**bibitem)
      # when "W3C" then RelatonW3c::W3cBibliographicItem.new(**bibitem)
      when /\/ieee/ then RelatonIeee::IeeeBibliographicItem.new(**bibitem)
      else RelatonBib::BibliographicItem.new(**bibitem)
      end
    end

    #
    # Create a bibitem hash from the message hash.
    #
    # @return [Hash] The bibitem hash.
    #
    def bibitem_hash # rubocop:disable Metrics/MethodLength
      {
        type: "standard",
        fetched: Date.today.to_s,
        title: create_title,
        docid: create_docid,
        date: create_date,
        link: create_link,
        abstract: create_abstract,
        contributor: create_contributors,
        doctype: @message["type"],
        place: create_place,
        relation: create_relation,
      }
    end

    #
    # Create a title and a subtitle from the message hash.
    #
    # @return [Array<RelatonBib::TypedTitleString>] The title and subtitle.
    #
    def create_title
      @message["title"].map do |t|
        RelatonBib::TypedTitleString.new(
          type: "main", content: t, language: "en", script: "Latn",
        )
      end + @message["subtitle"].map do |t|
        RelatonBib::TypedTitleString.new(
          type: "subtitle", content: t, language: "en", script: "Latn",
        )
      end
    end

    #
    # Create a docid from the message hash.
    #
    # @return [Array<RelatonBib::DocumentIdentifier>] The docid.
    #
    def create_docid
      %w[DOI ISBN].each_with_object([]) do |type, obj|
        id = @message[type].is_a?(Array) ? @message[type].first : @message[type]
        next unless id

        primary = type == "DOI"
        obj << RelatonBib::DocumentIdentifier.new(type: type, id: id, primary: primary)
      end
    end

    #
    # Create dates from the message hash.
    #
    # @return [Array<RelatonBib::BibliographicDate>] The dates.
    #
    def create_date
      %w[created issued published approved].each_with_object([]) do |type, obj|
        next unless @message[type]

        on = @message[type]["date-parts"][0].map { |d| d.to_s.rjust(2, "0") }.join "-"
        obj << RelatonBib::BibliographicDate.new(type: type, on: on)
      end
    end

    #
    # Create a link from the message hash.
    #
    # @return [Array<RelatonBib::TypedUri>] The link.
    #
    def create_link
      return [] unless @message["URL"]

      [RelatonBib::TypedUri.new(type: "DOI", content: @message["URL"])]
    end

    #
    # Create an abstract from the message hash.
    #
    # @return [Array<RelatonBib::FormattedString>] The abstract.
    #
    def create_abstract
      return [] unless @message["abstract"]

      content = @message["abstract"]
      abstract = RelatonBib::FormattedString.new(
        content: content, language: "en", script: "Latn", format: "text/html",
      )
      [abstract]
    end

    #
    # Create contributors from the message hash.
    #
    # @return [Array<RelatonBib::ContributionInfo>] The contributors.
    #
    def create_contributors
      contribs = %w[author editor translator].each_with_object([]) do |type, obj|
        @message[type]&.each do |contrib|
          obj << contributor(person(contrib), type)
        end
      end
      contribs << contributor(org_publisher, "publisher")
    end

    #
    # Cerate an organization publisher from the message hash.
    #
    # @return [RelatonBib::Organization] The organization.
    #
    def org_publisher
      pbr = @message["institution"]&.detect do |i|
        @message["publisher"].include?(i["name"]) ||
          i["name"].include?(@message["publisher"])
      end
      a = pbr["acronym"]&.first if pbr
      RelatonBib::Organization.new name: @message["publisher"], abbreviation: a
    end

    #
    # Create contributor from an entity and a role type.
    #
    # @param [RelatonBib::Person, RelatonBib::Organization] entity The entity.
    # @param [String] type The role type.
    #
    # @return [RelatonBib::ContributionInfo] The contributor.
    #
    def contributor(entity, type)
      RelatonBib::ContributionInfo.new(entity: entity, role: [type: type])
    end

    #
    # Create a person from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [RelatonBib::Person] The person.
    #
    def person(person)
      RelatonBib::Person.new(
        name: person_name(person), affiliation: affiliation(person),
        identifier: person_id(person)
      )
    end

    #
    # Create person affiliations from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [Array<RelatonBib::Affiliation>] The affiliations.
    #
    def affiliation(person)
      (person["affiliation"] || []).map do |a|
        org = RelatonBib::Organization.new(name: a["name"])
        RelatonBib::Affiliation.new organization: org
      end
    end

    #
    # Create a person full name from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [RelatonBib::FullName] The full name.
    #
    def person_name(person)
      sn = RelatonBib::LocalizedString.new(person["family"], "en", "Latn")
      RelatonBib::FullName.new(
        surname: sn, forename: forename(person), addition: nameaddition(person),
        completename: completename(person), prefix: nameprefix(person)
      )
    end

    #
    # Create a person name prefix from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [Array<RelatonBib::LocalizedString>] The name prefix.
    #
    def nameprefix(person)
      return [] unless person["prefix"]

      [RelatonBib::LocalizedString.new(person["prefix"], "en", "Latn")]
    end

    #
    # Create a complete name from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [RelatonBib::LocalizedString] The complete name.
    #
    def completename(person)
      return unless person["name"]

      RelatonBib::LocalizedString.new(person["name"], "en", "Latn")
    end

    #
    # Create a forename from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [Array<RelatonBib::LocalizedString>] The forename.
    #
    def forename(person)
      return [] unless person["given"]

      [RelatonBib::Forename.new(content: person["given"], language: "en", script: "Latn")]
    end

    #
    # Create an addition from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [Array<RelatonBib::LocalizedString>] The addition.
    #
    def nameaddition(person)
      return [] unless person["suffix"]

      [RelatonBib::LocalizedString.new(person["suffix"], "en", "Latn")]
    end

    #
    # Create a person identifier from a person hash.
    #
    # @param [Hash] person The person hash.
    #
    # @return [Array<RelatonBib::PersonIdentifier>] The person identifier.
    #
    def person_id(person)
      return [] unless person["ORCID"]

      [RelatonBib::PersonIdentifier.new("orcid", person["ORCID"])]
    end

    #
    # Create a place from the message hash.
    #
    # @return [Array<RelatonBib::Place>] The place.
    #
    def create_place
      return [] unless @message["publisher-location"]

      city, rg = @message["publisher-location"].split(", ")
      region = RelatonBib::Place::RegionType.new(name: rg)
      [RelatonBib::Place.new(city: city, region: [region])]
    end

    #
    # Crerate relations from the message hash.
    #
    # @return [Array<RelatonBib::DocumentRelation>] The relations.
    #
    def create_relation
      @message["relation"].map do |k, v|
        fref = RelatonBib::FormattedRef.new(content: v["id"])
        bib = create_bibitem v["id"], formattedref: fref
        type = REALATION_TYPES[k] || k
        RelatonBib::DocumentRelation.new(type: type, bibitem: bib)
      end
    end
  end
end
