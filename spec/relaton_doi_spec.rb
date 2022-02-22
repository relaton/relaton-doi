# frozen_string_literal: true

RSpec.describe RelatonDoi do
  it "has a version number" do
    expect(RelatonDoi::VERSION).not_to be nil
  end

  context "fetch document" do
    it "NIST" do
      VCR.use_cassette "crossref_nist" do
        file = "spec/fixtures/crossref_nist.xml"
        resp = RelatonDoi::Crossref.get "10.6028/nist.ir.8245"
        xml = resp.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(resp).to be_instance_of(RelatonNist::NistBibliographicItem)
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
      end
    end

    it "RFC" do
      VCR.use_cassette "crossref_rfc" do
        file = "spec/fixtures/crossref_rfc.xml"
        resp = RelatonDoi::Crossref.get "10.17487/RFC0001"
        xml = resp.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(resp).to be_instance_of(RelatonIetf::IetfBibliographicItem)
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
      end
    end

    it "BIPM" do
      VCR.use_cassette "crossref_bipm" do
        file = "spec/fixtures/crossref_bipm.xml"
        resp = RelatonDoi::Crossref.get "10.1088/0026-1394/29/6/001"
        xml = resp.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(resp).to be_instance_of(RelatonBipm::BipmBibliographicItem)
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
      end
    end

    it "IEEE" do
      VCR.use_cassette "crossref_ieee" do
        file = "spec/fixtures/crossref_ieee.xml"
        resp = RelatonDoi::Crossref.get "10.1109/ieeestd.2014.6835311"
        xml = resp.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(resp).to be_instance_of(RelatonIeee::IeeeBibliographicItem)
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}(?=<\/fetched>)/, Date.today.to_s)
      end
    end
  end
end
