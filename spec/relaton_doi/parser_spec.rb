describe RelatonDoi::Parser do
  subject { RelatonDoi::Parser.new({}) }

  context "transform relation type" do
    it "without description" do
      type = subject.relation_type "is-preprint-of"
      expect(type).to eq ["draftOf", nil]
    end

    it "with description" do
      type = subject.relation_type "is-funded-by"
      expect(type[0]).to eq "related"
      expect(type[1]).to be_instance_of(RelatonBib::FormattedString)
      expect(type[1].content).to eq "is-funded-by"
    end
  end

  it "parse link" do
    subject.instance_variable_set :@src, {
      "URL" => "http://dx.doi.org/10.1037/0000120-016",
      "link" => [{ "URL" => "http://psycnet.apa.org/books/16096/016.pdf" }],
    }
    link = subject.parse_link
    expect(link).to be_instance_of(Array)
    expect(link[0]).to be_instance_of(RelatonBib::TypedUri)
    expect(link[0].type).to eq "DOI"
    expect(link[0].content.to_s).to eq "http://dx.doi.org/10.1037/0000120-016"
    expect(link[1].type).to eq "pdf"
    expect(link[1].content.to_s).to eq "http://psycnet.apa.org/books/16096/016.pdf"
  end

  it "parse abstract" do
    subject.instance_variable_set :@src, { "abstract" => "Abstract text" }
    abstract = subject.parse_abstract
    expect(abstract).to be_instance_of(Array)
    expect(abstract.first).to be_instance_of(RelatonBib::FormattedString)
    expect(abstract.first.content).to eq "Abstract text"
  end

  it "create affiliation" do
    affiliation = subject.create_affiliation "affiliation" => [{ "name" => "Org name" }]
    expect(affiliation).to be_instance_of(Array)
    expect(affiliation[0]).to be_instance_of(RelatonBib::Affiliation)
    expect(affiliation[0].organization).to be_instance_of(RelatonBib::Organization)
    expect(affiliation[0].organization.name[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(affiliation[0].organization.name[0].content).to eq "Org name"
  end

  it "parse name prefix" do
    prefix = subject.nameprefix "prefix" => "Prefix"
    expect(prefix).to be_instance_of(Array)
    expect(prefix[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(prefix[0].content).to eq "Prefix"
  end

  it "parse complete name" do
    completename = subject.completename "name" => "Complete name"
    expect(completename).to be_instance_of(RelatonBib::LocalizedString)
    expect(completename.content).to eq "Complete name"
  end

  it "parse name addition" do
    nameaddition = subject.nameaddition "suffix" => "Addition"
    expect(nameaddition).to be_instance_of(Array)
    expect(nameaddition[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(nameaddition[0].content).to eq "Addition"
  end

  it "parse person identifier" do
    id = subject.person_id "ORCID" => "0000-0000-0000-0000"
    expect(id).to be_instance_of(Array)
    expect(id[0]).to be_instance_of(RelatonBib::PersonIdentifier)
    expect(id[0].value).to eq "0000-0000-0000-0000"
  end

  it "parse relation" do
    expect(RelatonDoi::Crossref).to receive(:get_by_id).with("10.1186/s12891-020-03567-w")
      .and_return("title" => ["Preprint of"])
    expect(RelatonDoi::Crossref).to receive(:get_by_id).with("10.1016/j.cell.2006.03.039")
      .and_return("title" => ["Review of"])
    expect(RelatonDoi::Crossref).to receive(:get_by_id).with("10.1515/9789048514373-004")
      .and_return("title" => ["Identical to"])
    subject.instance_variable_set :@src, {
      "relation" => {
        "is-preprint-of" => {
          "id-type" => "doi",
          "id" => "10.1186/s12891-020-03567-w",
          "asserted-by" => "subject",
        },
        "is-review-of" => {
          "id-type": "doi",
          "id" => "10.1016/j.cell.2006.03.039",
          "asserted-by" => "subject",
        },
        "is-identical-to" => {
          "id-type" => "doi",
          "id" => "10.1515/9789048514373-004",
          "asserted-by" => "subject",
        },
      },
    }
    relation = subject.parse_relation
    expect(relation).to be_instance_of(Array)
    expect(relation[0]).to be_instance_of(RelatonBib::DocumentRelation)
    expect(relation[0].type).to eq "draftOf"
    expect(relation[0].bibitem).to be_instance_of(RelatonBib::BibliographicItem)
    expect(relation[0].bibitem.title).to be_instance_of(RelatonBib::TypedTitleStringCollection)
    expect(relation[0].bibitem.title[0].title.content).to eq "Preprint of"
    expect(relation[1].bibitem.title[0].title.content).to eq "Review of"
    expect(relation[2].bibitem.title[0].title.content).to eq "Identical to"
  end

  context "parse place" do
    it "with 2 different places" do
      subject.instance_variable_set :@src, { "publisher-location" => "Place 1, Place 2" }
      place = subject.parse_place
      expect(place).to be_instance_of(Array)
      expect(place[0]).to be_instance_of(RelatonBib::Place)
      expect(place[0].city).to eq "Place 1"
      expect(place[1]).to be_instance_of(RelatonBib::Place)
      expect(place[1].city).to eq "Place 2"
    end
  end
end
