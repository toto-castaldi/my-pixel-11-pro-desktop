# Spikes

A spike is a backlog item of type `Spike` (`SPIKE-NNN`) that answers explicit questions before committing to a design (`docs/PROCESS.md` §4.1).

- Report file: `SPIKE-NNN-short-slug.md`, copied from `_TEMPLATE.md`, written in the project language.
- The spike's acceptance criteria are the questions to answer; the report must answer each of them or state why it could not.
- Exploratory code is not merged unless the acceptance criteria say so. Disposable material goes in an ignored folder (e.g. `tmp/`).
- Decisions resulting from the spike are recorded in `docs/design/` or in an ADR, and follow-up work is added to the backlog.

| Spike | Title | Outcome |
| ----- | ----- | ------- |
| [SPIKE-001](SPIKE-001-input-android.md) | Input su Android: tasto SUPER, touch e trackpad | Partial |
| [SPIKE-002](SPIKE-002-avvio-aggiornamenti.md) | Tenuta al riavvio e agli aggiornamenti dell'app Terminal | Partial |
| [SPIKE-003](SPIKE-003-audio.md) | Audio nella VM: PulseAudio e tasti volume | Partial |
