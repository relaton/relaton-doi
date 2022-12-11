describe RelatonDoi::Crossref do
  it "create link" do
    subject.instance_variable_set :@message, {
      "URL" => "http://dx.doi.org/10.1037/0000120-016",
      "link" => [{ "URL" => "http://psycnet.apa.org/books/16096/016.pdf" }],
    }
    link = subject.create_link
    expect(link).to be_instance_of(Array)
    expect(link[0]).to be_instance_of(RelatonBib::TypedUri)
    expect(link[0].type).to eq "DOI"
    expect(link[0].content.to_s).to eq "http://dx.doi.org/10.1037/0000120-016"
    expect(link[1].type).to eq "pdf"
    expect(link[1].content.to_s).to eq "http://psycnet.apa.org/books/16096/016.pdf"
  end

  it "create abstract" do
    subject.instance_variable_set :@message, { "abstract" => "Abstract text" }
    abstract = subject.create_abstract
    expect(abstract).to be_instance_of(Array)
    expect(abstract.first).to be_instance_of(RelatonBib::FormattedString)
    expect(abstract.first.content).to eq "Abstract text"
  end

  it "create affiliation" do
    affiliation = subject.affiliation "affiliation" => [{ "name" => "Org name" }]
    expect(affiliation).to be_instance_of(Array)
    expect(affiliation[0]).to be_instance_of(RelatonBib::Affiliation)
    expect(affiliation[0].organization).to be_instance_of(RelatonBib::Organization)
    expect(affiliation[0].organization.name[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(affiliation[0].organization.name[0].content).to eq "Org name"
  end

  it "create name prefix" do
    prefix = subject.nameprefix "prefix" => "Prefix"
    expect(prefix).to be_instance_of(Array)
    expect(prefix[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(prefix[0].content).to eq "Prefix"
  end

  it "create complete name" do
    completename = subject.completename "name" => "Complete name"
    expect(completename).to be_instance_of(RelatonBib::LocalizedString)
    expect(completename.content).to eq "Complete name"
  end

  it "create name addition" do
    nameaddition = subject.nameaddition "suffix" => "Addition"
    expect(nameaddition).to be_instance_of(Array)
    expect(nameaddition[0]).to be_instance_of(RelatonBib::LocalizedString)
    expect(nameaddition[0].content).to eq "Addition"
  end

  it "create person identifier" do
    id = subject.person_id "ORCID" => "0000-0000-0000-0000"
    expect(id).to be_instance_of(Array)
    expect(id[0]).to be_instance_of(RelatonBib::PersonIdentifier)
    expect(id[0].value).to eq "0000-0000-0000-0000"
  end

  it "create relation" do
    subject.instance_variable_set :@message, {
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
    relation = subject.create_relation
    expect(relation).to be_instance_of(Array)
    expect(relation.first).to be_instance_of(RelatonBib::DocumentRelation)
    expect(relation.first.type).to eq "reprintOf"
    expect(relation.first.bibitem).to be_instance_of(RelatonBib::BibliographicItem)
    expect(relation.first.bibitem.formattedref).to be_instance_of(RelatonBib::FormattedRef)
    expect(relation.first.bibitem.formattedref.content).to eq "10.1186/s12891-020-03567-w"
  end
end
