describe RelatonDoi::Crossref do
  it "gets a document by DOI" do
    expect(RelatonDoi::Crossref).to receive(:get_by_id).with("10.6028/nist.ir.8245").and_return(:message)
    expect(RelatonDoi::Parser).to receive(:parse).with(:message).and_return(:bibitem)
    expect(described_class.get("doi:10.6028/nist.ir.8245")).to eq :bibitem
  end

  it "gets a document by ID from Crossref" do
    resp = [{ "message" => :message }]
    expect(Serrano).to receive(:works).with(ids: "10.6028/nist.ir.8245").and_return(resp)
    expect(described_class.get_by_id("10.6028/nist.ir.8245")).to eq :message
  end
end
