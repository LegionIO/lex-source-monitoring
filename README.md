# lex-source-monitoring

Reality monitoring for LegionIO cognitive agents. Tracks the attributed source of information — distinguishing externally perceived facts from internally generated content (imagination, inference, dream).

## What It Does

`lex-source-monitoring` implements Johnson & Raye's Reality Monitoring framework. Every piece of information the agent holds is tagged with its attributed source. External sources (`:external_perception`, `:instruction`) produce `:real` content. Internal sources (`:internal_generation`, `:imagination`, `:dream`) produce `:generated` content. Source attribution errors — where internally generated content is believed to be external — can be detected and corrected.

- **Sources**: `:external_perception`, `:internal_generation`, `:memory_retrieval`, `:imagination`, `:inference`, `:instruction`, `:dream`, `:unknown`
- **Reality status**: `:real`, `:generated`, or `:uncertain` per source type
- **Verification**: boosts confidence by 0.15 on corroboration
- **Correction**: records attribution changes with full history; `confused?` flags records that have confusion-prone source pairs and low confidence
- **Accuracy**: ratio of records never corrected
- **Decay**: confidence decreases each tick; faded records are pruned

## Usage

```ruby
require 'legion/extensions/source_monitoring'

client = Legion::Extensions::SourceMonitoring::Client.new

# Record a fact with its source
result = client.record_source(
  content: 'the meeting is at 3pm',
  source: :external_perception,
  domain: :calendar
)
record_id = result[:record_id]
# => { reality_status: :real }

# Record something imagined
client.record_source(content: 'the user seemed frustrated', source: :imagination)
# => { reality_status: :generated }

# Verify a source (corroboration boosts confidence)
client.verify_source(record_id: record_id)

# Correct a misattribution
client.correct_source(record_id: record_id, new_source: :memory_retrieval)
# => { old_source: :external_perception, new_source: :memory_retrieval, correction_count: 1 }

# Reality check
client.reality_check(record_id: record_id)
# => { reality_status: :uncertain, external: false, internal: false }

# Find confused attributions
client.confused_sources
# => { confused: [...], count: 0 }

# Attribution accuracy
client.attribution_accuracy
# => { accuracy: 0.0, total_records: 2 }
# (Both records had corrections in this example)

# Per-tick decay (also runs every 300s via Decay actor)
client.update_source_monitoring
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
