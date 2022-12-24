module RelatonDoi
  class Crossref
    TYPES = {
      "book-chapter" => "inbook",
      "book-part" => "inbook",
      "book-section" => "inbook",
      "book-series" => "book",
      "book-set" => "book",
      "book-track" => "inbook",
      "component" => "misc",
      "database" => "dataset",
      "dissertation" => "thesis",
      "edited-book" => "book",
      "grant" => "misc",
      "journal-article" => "article",
      "journal-issue" => "article",
      "journal-volume" => "journal",
      "monograph" => "book",
      "other" => "misc",
      "peer-review" => "article",
      "posted-content" => "social_media",
      "proceedings-article" => "inproceedings",
      "proceedings-series" => "proceedings",
      "reference-book" => "book",
      "reference-entry" => "inbook",
      "report-component" => "techreport",
      "report-series" => "techreport",
      "report" => "techreport",
    }.freeze

    REALATION_TYPES = {
      "is-cited-by" => "isCitedIn",
      "is-funded-by" => :-,
      "has-award" => :-,
      "belongs-to" => "related",
      "is-child-of" => "includedIn",
      "is-expression-of" => "expressionOf",
      "has-expression" => "hasExpression",
      "is-manifestation-of" => "manifestationOf",
      "is-manuscript-of" => "draftOf",
      "has-manuscript" => "hasDraft",
      "is-preprint-of" => "draftOf",
      "has-preprint" => "hasDraft",
      "is-replaced-by" => "obsoletedBy",
      "replaces" => "obsoletes",
      "is-translation-of" => "translatedFrom",
      "has-translation" => "hasTranslation",
      "is-variant-form-of" => :-,
      "is-original-form-of" => :-,
      "is-version-of" => "editionOf",
      "has-version" => "hasEdition",
      "is-based-on" => "updates",
      "is-basis-for" => "updatedBy",
      "is-comment-on" => "commentaryOf",
      "has-comment" => "hasCommentary",
      "is-continued-by" => "hasSuccessor",
      "continues" => "successorOf",
      "is-derived-from" => "derives",
      "has-derivation" => "derivedFrom",
      "is-documented-by" => "describedBy",
      "documents" => "describes",
      "finances" => :-,
      "is-financed-by" => :-,
      "is-part-of" => "partOf",
      "has-part" => "hasPart",
      "is-review-of" => "reviewOf",
      "has-review" => "hasReview",
      "references" => "cites",
      "is-referenced-by" => "isCitedIn",
      "is-replay-to" => :-,
      "has-replay" => :-,
      "requires" => "hasComplement",
      "is-required-by" => "complementOf",
      "is-supplement-to" => "complementOf",
      "is-supplemented-by" => "hasComplement",
      "is-identical-to" => "identicalTo", # ?
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
        type: parse_type,
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
        extent: create_extent,
        series: create_series,
      }
    end

    #
    # Parse the document type.
    #
    # @return [String] The document type.
    #
    def parse_type
      TYPES[@message["type"]] || @message["type"]
    end

    #
    # Create a title and a subtitle from the message hash.
    #
    # @return [Array<RelatonBib::TypedTitleString>] The title and subtitle.
    #
    def create_title
      titles.map { |t| RelatonBib::TypedTitleString.new(**t) }
    end

    #
    # Fetch titles from the projects.
    #
    # @return [Array<Hash>] The titles.
    #
    def project_titles
      RelatonBib.array(@message["project"]).reduce([]) do |memo, proj|
        memo + RelatonBib.array(proj["project-title"]).map do |t|
          { type: "main", content: t["title"], language: "en", script: "Latn" }
        end
      end
    end

    #
    # Fetch titles from the message hash.
    #
    # @return [Array<Hash>] The titles.
    #
    def titles
      if @message["title"].is_a?(Array) && @message["title"].any?
        main_sub_titles
      elsif @message["project"].is_a?(Array) && @message["project"].any?
        project_titles
      elsif @message["container-title"].is_a?(Array) && @message["container-title"].size > 1
        @message["container-title"][0..-2].map do |t|
          { type: "main", content: t, language: "en", script: "Latn" }
        end
      else []
      end
    end

    #
    # Fetch main and subtitle from the message hash.
    #
    # @return [Array<Hash>] The titles.
    #
    def main_sub_titles
      @message["title"].map do |t|
        { type: "main", content: t, language: "en", script: "Latn" }
      end + RelatonBib.array(@message["subtitle"]).map do |t|
        { type: "subtitle", content: t, language: "en", script: "Latn" }
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
      links = []
      if @message["URL"]
        links << RelatonBib::TypedUri.new(type: "DOI", content: @message["URL"])
      end
      return links unless @message["link"]&.any?

      link = @message["link"].first
      if link["URL"].match?(/\.pdf$/)
        links << RelatonBib::TypedUri.new(type: "pdf", content: link["URL"])
      end
      links
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
    def create_contributors # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      contribs = %w[author editor translator].each_with_object([]) do |type, obj|
        @message[type]&.each do |contrib|
          obj << contributor(person(contrib), type)
        end
      end
      contribs_from_parent(contribs) << contributor(org_publisher, "publisher")
    end

    #
    # Fetch authors and editors from parent if they are not present in the book part.
    #
    # @param [Array<RelatonBib::ContributionInfo>] contribs present contributors
    #
    # @return [Array<RelatonBib::ContributionInfo>] contributors with authors and editors from parent
    #
    def contribs_from_parent(contribs) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return contribs unless %w[inbook inproceedings dataset].include?(parse_type) && @message["container-title"]

      has_authors = contribs.any? { |c| c.role&.any? { |r| r.type == "author" } }
      has_editors = contribs.any? { |c| c.role&.any? { |r| r.type == "editor" } }
      return contribs if has_authors && has_editors

      item = fetch_parent
      authors = create_authors_editors(has_authors, "author", item)
      editors = create_authors_editors(has_editors, "editor", item)
      contribs + authors + editors
    end

    #
    # Fetch parent item from Crossref.
    #
    # @return [Hash, nil] parent item
    #
    def fetch_parent # rubocop:disable Metrics/AbcSize
      query = [@message["container-title"][0], fetch_year].compact.join "+"
      filter = "type:#{%w[book book-set edited-book monograph reference-book].join ',type:'}"
      resp = Faraday.get "https://api.crossref.org/works?query=#{query}&filter=#{filter}"
      json = JSON.parse resp.body
      json["message"]["items"].detect { |i| i["title"].include? @message["container-title"][0] }
    end

    #
    # Create authors and editors from parent item.
    #
    # @param [Boolean] has true if authors or editors are present in the book part
    # @param [String] type "author" or "editor"
    # @param [Hash, nil] item parent item
    #
    # @return [Array<RelatonBib::ContributionInfo>] authors or editors
    #
    def create_authors_editors(has, type, item)
      return [] if has || !item

      RelatonBib.array(item[type]).map { |a| contributor(person(a), type) }
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
      pub_location = @message["publisher-location"] || fetch_location
      return [] unless pub_location

      city, rg = pub_location.split(", ")
      region = RelatonBib::Place::RegionType.new(name: rg)
      [RelatonBib::Place.new(city: city, region: [region])]
    end

    #
    # Fetch location from conteiner.
    #
    # @return [String, nil] The location.
    #
    def fetch_location # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      title = titles&.first&.dig(:content)
      qparts = [title, fetch_year, @message["publisher"]]
      query = CGI.escape qparts.compact.join("+").gsub(" ", "+")
      filter = "type:#{%w[book-chapter book-part book-section book-track].join(',type:')}"
      resp = Faraday.get "https://api.crossref.org/works?query=#{query}&filter=#{filter}"
      json = JSON.parse resp.body
      json["message"]["items"].detect do |i|
        i["publisher-location"] && i["container-title"].include?(title)
      end&.dig("publisher-location")
    end

    #
    # Crerate relations from the message hash.
    #
    # @return [Array<RelatonBib::DocumentRelation>] The relations.
    #
    def create_relation # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      rels = included_in_relation
      @message["relation"].each_with_object(rels) do |(k, v), a|
        type, desc = relation_type k
        RelatonBib.array(v).each do |r|
          fref = RelatonBib::FormattedRef.new(content: r["id"])
          docid = RelatonBib::DocumentIdentifier.new(id: r["id"], type: "DOI")
          bib = create_bibitem r["id"], formattedref: fref, docid: [docid]
          a << RelatonBib::DocumentRelation.new(type: type, description: desc, bibitem: bib)
        end
      end
    end

    #
    # Transform crossref relation type to relaton relation type.
    #
    # @param [String] crtype The crossref relation type.
    #
    # @return [Array<String>] The relaton relation type and description.
    #
    def relation_type(crtype)
      type = REALATION_TYPES[crtype] || crtype
      if type == :-
        type = "related"
        desc = RelatonBib::FormattedString.new(content: crtype)
      end
      [type, desc]
    end

    def included_in_relation
      return [] unless @message["container-title"] # && parse_type != "article"

      @message["container-title"].map do |ct|
        contrib = included_in_editors(ct)
        bib = RelatonBib::BibliographicItem.new(title: [content: ct], contributor: contrib)
        RelatonBib::DocumentRelation.new(type: "includedIn", bibitem: bib)
      end
    end

    #
    # Fetch included in editors.
    #
    # @param [String] title container-title
    #
    # @return [Array<RelatonBib::ContributionInfo>] The editors contribution info.
    #
    def included_in_editors(title)
      item = fetch_included_in title
      return [] unless item

      item["editor"].map { |e| contributor(person(e), "editor") }
    end

    #
    # Fetch included in relation.
    #
    # @param [String] title container-title
    #
    # @return [Hash] The included in relation item.
    #
    def fetch_included_in(title)
      query = CGI.escape [title, @message["publisher"], @message["publisher-location"], fetch_year].join(", ")
      resp = Faraday.get %{http://api.crossref.org/works?query.bibliographic="#{query}"&rows=5&filter=type:book}
      json = JSON.parse resp.body
      json["message"]["items"].detect { |i| i["title"].include?(title) && i["editor"] }
    end

    def fetch_year
      d = @message["published"] || @message["approved"] || @message["created"]
      d["date-parts"][0][0]
    end

    #
    # Create an extent from the message hash.
    #
    # @return [Array<RelatonBib::Locality>] The extent.
    #
    def create_extent # rubocop:disable Metrics/AbcSize
      extent = []
      extent << RelatonBib::Locality.new("volume", @message["volume"]) if @message["volume"]
      extent << RelatonBib::Locality.new("issue", @message["issue"]) if @message["issue"]
      if @message["page"]
        from, to = @message["page"].split("-")
        extent << RelatonBib::Locality.new("page", from, to)
      end
      extent.any? ? [RelatonBib::LocalityStack.new(extent)] : []
    end

    #
    # Create a series from the message hash.
    #
    # @return [Arrey<RelatonBib::Series>] The series.
    #
    def create_series
      return [] unless @message["container-title"]

      con_ttl = if main_sub_titles.any? || project_titles.any?
                  @message["container-title"]
                else
                  @message["container-title"][-1..-1] || []
                end
      con_ttl.map do |ct|
        title = RelatonBib::TypedTitleString.new content: ct
        RelatonBib::Series.new title: title
      end
    end
  end
end
