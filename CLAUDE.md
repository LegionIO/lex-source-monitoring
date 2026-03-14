# lex-source-monitoring

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-source-monitoring`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::SourceMonitoring`

## Purpose

Implements Johnson & Raye's Reality Monitoring framework for cognitive agents. Tracks the attributed source of each piece of information the agent holds — distinguishing externally perceived facts from internally generated ones (imagination, inference, dream). Supports source verification, correction, confusion detection, and attribution accuracy tracking. Helps the agent maintain epistemic hygiene by flagging internally generated content that has been misattributed to external sources.

## Gem Info

- **Gem name**: `lex-source-monitoring`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/source_monitoring/
  version.rb                           # VERSION = '0.1.0'
  helpers/
    constants.rb                       # source types, reality status map, confusion pairs, confidence labels
    source_record.rb                   # SourceRecord class — content with attributed source and confidence
    source_tracker.rb                  # SourceTracker class — indexed store of SourceRecords
  runners/
    source_monitoring.rb               # Runners::SourceMonitoring module — all public runner methods
  actors/
    decay.rb                           # Decay actor — Every 300 seconds, calls update_source_monitoring
  client.rb                            # Client class including Runners::SourceMonitoring
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_RECORDS` | 500 | Maximum source records stored |
| `CONFIDENCE_DECAY` | 0.01 | Per-tick confidence decrease |
| `DEFAULT_CONFIDENCE` | 0.6 | Starting confidence for new records |
| `SOURCES` | 8 symbols | `:external_perception`, `:internal_generation`, `:memory_retrieval`, `:imagination`, `:inference`, `:instruction`, `:dream`, `:unknown` |
| `REALITY_STATUS` | hash | Maps each source to `:real`, `:generated`, or `:uncertain` |
| `CONFUSION_PAIRS` | 5 pairs | Source pairs prone to confusion (e.g., imagination vs external_perception) |
| `CONFIDENCE_LABELS` | hash | Named tiers: high/moderate/low/uncertain |

### `REALITY_STATUS` Map

| Source | Reality Status |
|---|---|
| `:external_perception` | `:real` |
| `:instruction` | `:real` |
| `:memory_retrieval` | `:uncertain` |
| `:inference` | `:uncertain` |
| `:internal_generation` | `:generated` |
| `:imagination` | `:generated` |
| `:dream` | `:generated` |
| `:unknown` | `:uncertain` |

## Helpers

### `Helpers::SourceRecord`

Content item with attributed source and confidence.

- `initialize(id:, content:, source:, domain: :general, confidence: DEFAULT_CONFIDENCE)` — recorded_at=Time.now, correction_history=[]
- `reality_status` — looks up REALITY_STATUS for current source
- `external?` — `reality_status == :real`
- `internal?` — `reality_status == :generated`
- `verify` — increments confidence by 0.15; clamps to 1.0
- `correct(new_source)` — records old source in correction_history; sets source to new_source; decrements confidence by 0.1
- `correction_count` — correction_history.size
- `confused?` — `source` and any correction_history entry form a CONFUSION_PAIR, AND confidence < 0.5
- `decay` — decrements confidence by CONFIDENCE_DECAY
- `faded?` — confidence <= 0.05

### `Helpers::SourceTracker`

Indexed store of SourceRecord objects.

- `initialize` — records hash keyed by record id, domain index
- `record(content:, source:, domain: :general)` — creates SourceRecord; returns nil if at MAX_RECORDS
- `attribute(record_id)` — returns source and confidence for the given record
- `verify(record_id)` — calls `record.verify`
- `correct(record_id:, new_source:)` — calls `record.correct`
- `reality_check(record_id)` — returns reality_status, external?, internal?
- `confused_records` — all records with `confused? == true`
- `by_source(source)` — filter records by source type
- `attribution_accuracy` — ratio of records that have never been corrected to total records
- `decay_all` — decays all records; removes faded ones

## Runners

All runners are in `Runners::SourceMonitoring`. The `Client` includes this module and owns a `SourceTracker` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `record_source` | `content:, source:, domain: :general` | `{ success:, record_id:, source:, reality_status: }` |
| `attribute_source` | `record_id:` | `{ success:, record_id:, source:, confidence: }` |
| `verify_source` | `record_id:` | `{ success:, record_id:, confidence: }` |
| `correct_source` | `record_id:, new_source:` | `{ success:, record_id:, old_source:, new_source:, correction_count: }` |
| `reality_check` | `record_id:` | `{ success:, record_id:, source:, reality_status:, external:, internal: }` |
| `confused_sources` | (none) | `{ success:, confused:, count: }` |
| `sources_by_type` | `source:` | `{ success:, source:, records:, count: }` |
| `attribution_accuracy` | (none) | `{ success:, accuracy:, total_records: }` |
| `update_source_monitoring` | (none) | `{ success:, records: }` — calls `decay_all` |
| `source_monitoring_stats` | (none) | Total records, accuracy, confusion count, distribution by source type |

## Actors

`Actor::Decay` — `Every` actor, fires every 300 seconds. Calls `update_source_monitoring` to run the decay cycle.

## Integration Points

- **lex-memory**: memory traces should have their source recorded here when stored; retrieval from memory maps to `:memory_retrieval` source
- **lex-dream**: content generated during the dream cycle should be tagged `:dream` source; source monitoring can later check if any dream content was misattributed as `:external_perception`
- **lex-privatecore**: source monitoring supports epistemic privacy — the agent can identify which content originated externally (may be sensitive) vs internally generated
- **lex-coldstart**: content ingested from CLAUDE.md files maps to `:instruction` source; cold-start firmware traces map to `:external_perception` semantically

## Development Notes

- `CONFUSION_PAIRS` is a defined list of pairs; `confused?` checks if the current source and any previously corrected source form one of those pairs — this is a post-hoc confusion detection based on correction history
- Attribution accuracy = fraction of records with zero corrections; this is a simple proxy for how well the agent attributed sources on first recording
- `confidence < 0.5` is the threshold for `confused?` — a recently recorded item (high confidence) is not flagged confused even if it involves a confusion pair
- `CONFIDENCE_DECAY = 0.01` per tick with `DEFAULT_CONFIDENCE = 0.6` means records fade to the confusion zone (~50 ticks) if never verified
- `correct` records the old source in `correction_history`, preserving the audit trail of attribution changes
