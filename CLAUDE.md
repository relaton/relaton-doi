# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

relaton-doi is a Ruby gem that fetches bibliographic metadata via DOI identifiers from the Crossref API and converts them into Relaton bibliographic objects. It detects DOI patterns to produce flavor-specific items (NIST, IETF, BIPM, IEEE) or generic `Bib::ItemData`.

## Common Commands

```bash
bundle exec rake spec          # Run all tests (default rake task)
bundle exec rspec spec/relaton/doi/parser_spec.rb  # Run a single spec file
bundle exec rspec spec/relaton/doi/parser_spec.rb:224  # Run a single example by line
rubocop                        # Lint
rubocop -a                     # Lint with auto-correct
```

## Architecture

**Namespace:** `Relaton::Doi` (migrated from legacy `RelatonDoi`).

**Core flow:** `Crossref.get(doi)` → HTTP fetch from api.crossref.org → `Parser.parse(json_hash)` → flavor-specific `ItemData`

Key classes in `lib/relaton/doi/`:

- **`Crossref`** — module with `get(doi)` and `get_by_id(id)`. Uses Faraday with retry logic (3 retries). Handles rate limiting via `x-rate-limit-interval` header.
- **`Parser`** — largest file (~827 lines). Converts Crossref JSON hashes to Relaton objects. Factory method `parse(src)` delegates to `create_bibitem` which picks the right ItemData class based on DOI pattern (`/nist/` → `Nist::ItemData`, `/rfc\d+/` → `Ietf::ItemData`, etc.). Contains ~30 `parse_*` helper methods for individual bibliographic fields.
- **`Processor`** — `Relaton::Processor` subclass for the Relaton registry system. Entry point for `get`, `from_xml`, `hash_to_bib`.
- **`Util`** — logging utility, extends `Relaton::Bib::Util` with `PROGNAME = "relaton-doi"`.

## Test Setup

- **RSpec** with `expect` syntax only (monkey patching disabled)
- **VCR** cassettes in `spec/vcr_cassettes/` record Crossref HTTP responses (re-recorded every 7 days)
- **XML fixtures** in `spec/fixtures/` — expected output XML files. The `read_fixture` helper auto-substitutes today's date into `<fetched>` tags.
- **equivalent-xml** gem for XML comparison in integration tests
- Integration tests in `spec/relaton/doi_spec.rb` cover 40+ document types via VCR cassettes
- Unit tests in `spec/relaton/doi/parser_spec.rb` test Parser methods directly with hash inputs

## Key Constants in Parser

- `TYPES` — maps 23 Crossref document types to Relaton types (e.g., `"book-chapter"` → `"inbook"`)
- `REALATION_TYPES` — maps 37 Crossref relation types to Relaton relation types
- `COUNTRIES` — `%w[USA]`, used by `parse_place` to distinguish country vs region
- `TAG_RE`, `NS_PREFIX_RE`, `NS_PLACEHOLDER`, `SAVE_OPTS` — used by `normalize_markup` and
  `drop_namespaces` to remove the `jats:` and `xlink:` prefixes that Crossref puts on
  abstract and title markup. Relaton never declares those prefixes, so the output would
  otherwise fail every namespace-aware parser downstream, including relaton-render
  (metanorma-pdfa#99). The helper declares each prefix on a wrapper element, removes the
  namespaces with Nokogiri, and returns the content unchanged when it does not parse.
