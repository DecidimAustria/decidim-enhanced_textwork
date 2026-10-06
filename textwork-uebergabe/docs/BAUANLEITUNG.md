# Textwork neu: Bauanleitung für die Entwicklung mit KI

Stand: 5. Oktober 2026

## 1. Ziel und Rahmen

Ziel ist ein neues, eigenständiges Decidim-Modul für partizipative Textarbeit. Die erste Ausbaustufe läuft auf einer Testinstanz, die als Präsentation dient. Das Modul ersetzt `decidim-enhanced_textwork` und baut nicht auf Proposals auf.

| Punkt | Festlegung |
| --- | --- |
| Zielversion | Decidim 0.32 (geprüft am Zweig `release/0.32-stable`, Version 0.32.1) |
| Arbeitsname | `decidim-textwork`, Namensraum `Decidim::Textwork`, Komponentenname `textwork` |
| Grundlage | Nur `decidim-core`, `decidim-comments`, `decidim-admin`. Keine Abhängigkeit von `decidim-proposals` oder `decidim-collaborative_texts` |
| Vorbild für Aufbau und Benennung | `decidim-collaborative_texts` (Document, Version, Suggestion, Rollout) |
| Vorlage für die Oberfläche | Das Mockup „Textarbeit – Redesign Mockup“ mit zwei Ansichten (Desktop mit Panel, mobil mit Bottom-Sheet) und den Notizzetteln daneben |
| Datenumzug | Keiner. Alte Verfahren bleiben im alten Plugin |
| Sprache | Oberfläche Deutsch und Englisch über Übersetzungsdateien. Bezeichner im Code englisch. Der Dokumenttext hat eine Originalsprache und wird bei Abruf maschinell übersetzt (Abschnitt 3.7) |

Der eine bewusste Unterschied zu Collaborative Texts: Absätze sind eigene, dauerhafte Datensätze. Collaborative Texts speichert den Text einer Version als ein Stück und nummeriert die Absätze beim Anzeigen (`ct-node-N` in `app/packs/src/decidim/collaborative_texts/document.js`). Daran können Kommentare, Zustimmung und stabile Adressen nicht zuverlässig hängen.

## 2. Arbeitsregeln für die KI

Diese Regeln gelten für jede Sitzung. Sie stehen vor allem anderen, weil sie Fehler verhindern, die sonst erst in der laufenden Instanz auffallen.

1. **Nachschlagen statt raten.** Bevor du eine Decidim-Schnittstelle verwendest (Concern, Cell, Helper, Command-Basisklasse, Stimulus-Controller), öffne die Datei im Decidim-Code der Version 0.32 und lies sie. Verwende nichts, was du dort nicht gefunden hast.
2. **Ein Vorbild pro Baustein.** Für jede neue Datei nimm die entsprechende Datei aus `decidim-collaborative_texts` als Muster (Aufbau, Benennung, Basisklasse). Wo dort nichts passt, nimm `decidim-debates` oder `decidim-blogs`, weil beide klein sind.
3. **Nichts aus `decidim-proposals` kopieren.** Keine Votes, Valuation, Notes, Collaborative Drafts, Amendments. Wenn eine Funktion nur dort existiert, halte an und frage.
4. **Das alte Plugin ist nur Vorlage für zwei Dinge:** den Textimport und (später) den Word-Export. Sonst nichts übernehmen.
5. **Kleine Schritte.** Arbeite Abschnitt 6 Schritt für Schritt ab. Nach jedem Schritt: Tests laufen lassen, die „Fertig, wenn“-Zeile prüfen, erst dann weiter.
6. **Tests und Übersetzungen im selben Schritt.** Jede neue Klasse bekommt einen Test, jeder sichtbare Text einen Schlüssel in `config/locales/de.yml` und `en.yml`. Keine festen Texte in Ansichten.
7. **Kein eigenes Design.** Farben, Schrift, Abstände und Zustände kommen aus den Tailwind-Klassen und Komponenten von Decidim 0.32. Die Farbwerte des Mockups sind Annäherungen und werden nicht übernommen. Aufbau, Reihenfolge, Texte und Verhalten des Mockups gelten.
8. **Barrierefreiheit ist Teil von „fertig“.** Echte `button`- und `a`-Elemente, sichtbarer Fokus, Bedienflächen mindestens 44 × 44 CSS-Pixel, Zustände nie nur über Farbe, Statusmeldungen mit `role="status"`.
9. **Bei Unklarheit anhalten.** Die Entscheidungen in Abschnitt 9 gelten und werden nicht umgedeutet. Bei einer Frage, die dort nicht beantwortet ist: die einfachste Lösung wählen und im Code mit `# DECISION:` markieren.

**Grundsatz für alles, was hier nicht festgelegt ist: die übliche Praxis von Decidim.** Das gilt besonders für die Ansichten im Admin-Bereich (Listen, Formulare, Filter, Sortierung, Papierkorb), für Fehlermeldungen, Leerzustände, Bestätigungsdialoge und den Versionsverlauf. Vorbild für den Admin-Bereich sind die Ansichten unter `decidim-collaborative_texts/app/views/decidim/collaborative_texts/admin/`, für alles Weitere `decidim-debates`. Eigene Lösungen nur dort, wo diese Anleitung sie ausdrücklich verlangt: Leseansicht mit Panel, Markierung im Text, Fassungen je Absatz und Übersetzung bei Abruf.

**Was in dieser Anleitung geprüft ist und was nicht.** Die genannten Dateien und Klassen in Decidim 0.32 wurden im Code nachgesehen. Nicht geprüft wurde, wie sie sich im Zusammenspiel verhalten. Stellen mit „prüfen“ sind Annahmen.

## 3. Datenmodell

Vier Tabellen. Ein Dokument besteht aus Blöcken (Überschrift oder Absatz), jeder Block hat Fassungen, und Änderungsvorschläge beziehen sich auf genau einen Absatz und eine Fassung.

### 3.1 Textformat und Sprache

- **Textformat:** Der Text eines Blocks ist eine Markdown-Teilmenge: `**fett**`, `*kursiv*`, `[Text](Adresse)` und Listen (Zeilen, die mit ` -  ` oder ` 1.  ` beginnen). Kein HTML, keine Überschriften, keine Bilder, keine Tabellen. Beim Anzeigen wird daraus bereinigtes HTML erzeugt.
- **Eine Liste ist ein Block.** Eine Aufzählung samt ihren Punkten ist ein einziger `paragraph`-Block und wird als Ganzes kommentiert und geändert.
- **Originalsprache:** Jedes Dokument hat genau eine Originalsprache (`Document#locale`). Text, Fassungen und Änderungsvorschläge werden in dieser Sprache gespeichert und verglichen.
- **Übersetzungen** sind maschinell erzeugte Lesefassungen und werden nur bei Abruf erstellt (Abschnitt 3.7).

### 3.2 `Decidim::Textwork::Document` (Tabelle `decidim_textwork_documents`)

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `decidim_component_id` | Referenz | Zugehörige Komponente |
| `locale` | string, Pflicht | Originalsprache des Dokuments |
| `title` | jsonb, Pflicht | Titel, Aufbau wie in 3.7 |
| `description` | jsonb | Einleitungssatz unter dem Titel, Aufbau wie in 3.7 |
| `published_at`, `deleted_at` | datetime | Veröffentlichung, Papierkorb |
| `likes_count`, `follows_count` | integer, Standard 0 | Zähler, soweit die Core-Concerns sie erwarten (prüfen) |

Concerns wie bei `Decidim::CollaborativeTexts::Document`: `Resourceable`, `HasComponent`, `Publicable`, `Traceable`, `Loggable`, `Searchable`, `SoftDeletable`. Zusätzlich `Decidim::Likeable` und `Decidim::Followable`: Hat ein Dokument keine Überschrift-Blöcke, sitzen „Stimme zu“ und „Folgen“ am Dokumenttitel. Hat es Überschriften, gibt es beides nur an den Kapiteln.

### 3.3 `Decidim::Textwork::Block` (Tabelle `decidim_textwork_blocks`)

Ein Block ist eine Kapitelüberschrift oder ein Absatz. Seine Datensatz-ID ist die dauerhafte Kennung.

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `document_id` | Referenz, Pflicht | Dokument |
| `kind` | enum `heading`, `paragraph` | Art des Blocks |
| `depth` | integer, Standard 1 | Gliederungsebene der Überschrift (1 bis 3). Bei Absätzen ohne Bedeutung |
| `position` | integer, Pflicht | Reihenfolge im Dokument, lückenlos |
| `body` | jsonb, Pflicht | Aktueller Text, Aufbau wie in 3.7 |
| `current_version_number` | integer, Standard 1 | Nummer der aktuellen Fassung |
| `comments_count`, `likes_count`, `follows_count` | integer, Standard 0 | Zähler, soweit die Core-Concerns sie erwarten (prüfen) |
| `pending_suggestions_count` | integer, Standard 0 | Zähler für das Bleistift-Symbol |
| removed\_at | datetime, optional | Gesetzt, wenn ein Admin den Block aus dem Dokument entfernt hat. Der Datensatz bleibt erhalten |

Concerns: `Decidim::Comments::Commentable`, `Decidim::Likeable`, `Decidim::Followable`, `Decidim::Traceable`. Kein `Decidim::Reportable`: Der offizielle Text kann nicht gemeldet werden.

| Block-Art | Kommentieren | Änderung vorschlagen | Stimme zu | Folgen |
| --- | --- | --- | --- | --- |
| `heading` | nein | nein | ja | ja |
| `paragraph` | ja | ja | nein | nein |

Die sichtbare Nummer („1“, „1.2“) wird nicht gespeichert, sondern aus `position`, `kind` und `depth` berechnet. Adressen und Verknüpfungen verwenden immer die ID, nie die Nummer.

### 3.4 `Decidim::Textwork::BlockVersion` (Tabelle `decidim_textwork_block_versions`)

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `block_id` | Referenz, Pflicht | Block |
| `number` | integer, Pflicht | Fassungsnummer, eindeutig je Block, beginnt bei 1 |
| `body` | text, Pflicht | Text dieser Fassung in der Originalsprache |
| `origin` | enum `import`, `suggestion`, `editorial` | Wie die Fassung entstand |
| `suggestion_id` | Referenz, optional | Vorschlag, aus dem die Fassung entstand |
| `adjusted` | boolean, Standard false | true, wenn die Moderation den Vorschlagstext vor der Annahme angepasst hat |
| `decidim_author_id` | Referenz, optional | Wer die Fassung erzeugt hat |

`BlockVersion` ist die maßgebliche Zählung der Fassungen („Fassung 2“, „zu Fassung 1“) und der Bezugspunkt für Änderungsvorschläge. Sie zählt nur Änderungen am Originaltext. Die Seite „Versionsverlauf“ wird mit den Kern-Bausteinen aus den Versionen von `Decidim::Traceable` gebaut (Abschnitt 4) und kann zusätzliche Einträge enthalten, etwa eine von Hand eingetragene Übersetzung. Ein Test stellt sicher, dass jede neue `BlockVersion` genau eine Traceable-Version des Blocks erzeugt; die umgekehrte Richtung gilt nicht.

### 3.4.1 `Decidim::Textwork::DocumentRevision` (Tabelle `decidim_textwork_document_revisions`)

Jede Änderung am Aufbau eines veröffentlichten Dokuments wird als Eintrag festgehalten. Zusammen mit den `BlockVersion`-Einträgen ergibt das den vollständigen Änderungsverlauf des Dokuments.

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `document_id` | Referenz, Pflicht | Dokument |
| `number` | integer, Pflicht | Laufende Nummer je Dokument, beginnt bei 1 (Import) |
| `kind` | enum `import`, `block_added`, `block_removed`, `block_moved` | Art der Änderung |
| `block_id` | Referenz, optional | Betroffener Block |
| `details` | jsonb | Bei `block_moved`: alte und neue Position und sichtbare Nummer. Bei `block_added` und `block_removed`: Position, sichtbare Nummer und Text zum Zeitpunkt der Änderung |
| `note` | text, optional | Anmerkung des Admins zur Änderung |
| `decidim_author_id` | Referenz | Wer die Änderung vorgenommen hat |

Textänderungen stehen nicht hier, sondern in `BlockVersion`. Die Seite „Änderungsverlauf des Dokuments“ zeigt beide Arten in zeitlicher Reihenfolge, in der Listendarstellung des Decidim-Kerns.

### 3.5 `Decidim::Textwork::Suggestion` (Tabelle `decidim_textwork_suggestions`)

Benennung und Status wie `Decidim::CollaborativeTexts::Suggestion`, ergänzt um `withdrawn`.

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `block_id` | Referenz, Pflicht | Betroffener Absatz |
| `block_version_id` | Referenz, Pflicht | Fassung, auf die sich der Vorschlag bezieht |
| `decidim_author_id`, `decidim_author_type` | polymorph | Verfasser:in (`Decidim::Authorable`) |
| `changeset` | jsonb, Pflicht | `{ "original": "...", "replace": "..." }`, jeweils der ganze Absatztext in der Originalsprache |
| `body` | jsonb | Der vorgeschlagene Text für übersetzte Ansichten, Aufbau wie in 3.7. Der Wert in der Originalsprache ist gleich `changeset["replace"]` |
| `justification` | jsonb, optional | Begründung der Verfasser:in, Aufbau wie in 3.7, höchstens 1000 Zeichen |
| `status` | enum `pending`, `accepted`, `rejected`, `withdrawn` | Entscheidungsstatus |
| `answer` | jsonb | Begründung der Moderation, Pflicht bei `rejected`, Aufbau wie in 3.7 |
| `answered_at` | datetime | Zeitpunkt der Entscheidung |
| `comments_count`, `likes_count` | integer, Standard 0 | Zähler (prüfen) |

Concerns: `Decidim::Authorable`, `Decidim::Comments::Commentable`, `Decidim::Likeable`, `Decidim::Reportable`, `Decidim::Traceable`.

### 3.6 Regeln

- **Ein Vorschlag betrifft genau einen Absatz.** Vorschläge über mehrere Absätze gibt es nicht.
- **Kein Titel.** Die Bezeichnung wird gebildet: „Änderungsvorschlag von \[Name\] zu Absatz \[Nummer\]“.
- **Ein Vorschlag ohne Änderung ist ungültig** (`original` und `replace` nach Normalisierung der Leerzeichen gleich).
- **Veraltet ist abgeleitet:** `outdated? = pending? && block_version.number < block.current_version_number`. Ein veralteter Vorschlag bleibt in der offenen Liste und ist weiter annehmbar. Er trägt den Vermerk „zu Fassung n“, und sein Vergleich bezieht sich auf `changeset["original"]`, nicht auf den aktuellen Text.
- **Annahme** (Command `Admin::AcceptSuggestion`, Vorbild `Decidim::CollaborativeTexts::Rollout`): Das Formular enthält den endgültigen Text, vorbefüllt mit `changeset["replace"]`. Ist der Vorschlag veraltet, zeigt das Formular eine Warnung und zusätzlich den aktuellen Text; die Moderation kann den endgültigen Text anpassen. In einer Transaktion: neue `BlockVersion` (`origin: suggestion`, `adjusted` wenn der Text vom Vorschlag abweicht), `block.body` in der Originalsprache und `current_version_number` setzen, gespeicherte Übersetzungen des Blocks löschen, Status `accepted`.
- **Ablehnung** (Command `Admin::RejectSuggestion`): Status `rejected`, `answer` Pflicht.
- **Redaktionelle Änderung** (Command `Admin::UpdateBlock`): Admins ändern einen Block direkt. Das erzeugt eine neue `BlockVersion` mit `origin: editorial` und ist im Versionsverlauf als „redaktionelle Änderung“ sichtbar.
- **Zurückziehen** (Command `WithdrawSuggestion`): Verfasser:innen können einen eigenen Vorschlag zurückziehen, solange er `pending` ist. Status `withdrawn`; er erscheint danach in keiner Liste mehr.
- **Bearbeiten** (Command `UpdateSuggestion`): Verfasser:innen können Text und Begründung eines eigenen Vorschlags ändern, solange er `pending` ist und `likes_count == 0 && comments_count == 0`.
- **Kapitelzugehörigkeit** eines Absatzes: die letzte Überschrift mit kleinerer `position`.
- **Zustimmung zum Kapitel bleibt** bei einer Textänderung bestehen. Wer zugestimmt hat, wird benachrichtigt (Abschnitt 3.8).
- **Längen:** Absatztext in einem Vorschlag höchstens 5000 Zeichen.

**Änderungen am Aufbau nach der Veröffentlichung.** Admins dürfen Blöcke einfügen, entfernen und umstellen. Jede dieser Änderungen erzeugt in derselben Transaktion einen `DocumentRevision`-Eintrag.

- **Einfügen** (Command `Admin::AddBlock`): neuer Block an der gewählten Position mit `BlockVersion` 1 (`origin: editorial`), die Positionen der folgenden Blöcke rücken auf.
- **Entfernen** (Command `Admin::RemoveBlock`): Der Block wird nicht gelöscht, sondern bekommt `removed_at`. Er erscheint nicht mehr im Text, im Inhaltsverzeichnis und in der Nummerierung. Seine Kommentare, Vorschläge und Fassungen bleiben gespeichert und sind über den Änderungsverlauf des Dokuments einsehbar. Offene Vorschläge zu diesem Block werden mit der Begründung „Der Absatz wurde entfernt.“ abgelehnt (von Claude gesetzte Regel, nicht ausdrücklich entschieden).
- **Umstellen** (Command `Admin::MoveBlock`): nur `position` ändert sich. Kommentare, Vorschläge, Zustimmungen und Fassungen bleiben am Block.
- **Nummern verschieben sich.** Die sichtbare Nummer eines Blocks kann sich durch diese Änderungen ändern. Deshalb gilt ohne Ausnahme: Adressen, Verknüpfungen und gespeicherte Bezüge verwenden die ID. Texte in Oberfläche und Benachrichtigungen nennen immer die aktuelle Nummer.
- **Adresse eines entfernten Blocks:** Sie öffnet das Dokument mit dem Hinweis „Dieser Absatz wurde entfernt.“ und einem Link zum Änderungsverlauf.
- **Entfernte Überschrift:** Die Absätze darunter gehören danach zum vorhergehenden Kapitel. Zustimmungen und Folgen der entfernten Überschrift bleiben gespeichert, wirken aber nicht mehr.
- **Absätze vor der ersten Überschrift** gehören zu keinem Kapitel. Für Benachrichtigungen gilt dort das Dokument als Bezug.

**Melden und verborgene Inhalte.**

- **Gemeldet werden können nur Änderungsvorschläge und Kommentare.** „Melden“ steht in der Detailansicht eines Vorschlags und, über den Kern, an jedem Kommentar. Am Absatz und an der Überschrift gibt es kein „Melden“.
- **Ein von der Moderation verborgener Vorschlag** erscheint in keiner Liste, wird nicht im Text markiert, zählt nicht in `pending_suggestions_count` und nicht in den Reitern. Seine Adresse öffnet den Absatz mit dem Hinweis „Dieser Änderungsvorschlag ist nicht verfügbar.“ Im Admin-Bereich bleibt er über die Moderation des Kerns erreichbar.
- **Verborgene Kommentare** behandelt der Kern; `comments_count` folgt dem Kern.

**Eigenen Vorschlag bearbeiten, wenn sich der Absatz inzwischen geändert hat.** Das Bearbeitungsformular zeigt den aktuellen Text des Absatzes als Grundlage. Beim Speichern wird `block_version_id` auf die aktuelle Fassung gesetzt und `changeset["original"]` auf den aktuellen Text. Der Vorschlag bezieht sich danach auf die neueste von der Moderation freigegebene Fassung und ist nicht mehr veraltet.

### 3.7 Übersetzbare Felder und Übersetzung bei Abruf

Übersetzbare Felder sind jsonb in der Form, die Decidim für maschinelle Übersetzungen verwendet: `{ "de": "Originaltext", "machine_translations": { "en": "..." } }`. Der Schlüssel der Originalsprache ist `Document#locale`.

Das ist die Struktur, die Decidim überall verwendet: Jede Sprache hat ihren eigenen Schlüssel und im Admin-Bereich ihr eigenes Eingabefeld. Bei maschineller Übersetzung bleiben diese Felder leer; die Übersetzung liegt unter `machine_translations`.

- **Vorrang:** Steht im Schlüssel einer Sprache ein Text (von Hand eingetragen), gilt er. Sonst gilt die maschinelle Übersetzung, sonst der Originaltext.
- **Anzeige über den Kern:** Zum Anzeigen den Helper `translated_attribute` verwenden (`decidim-core/lib/decidim/translatable_attributes.rb`). Er berücksichtigt die Einstellung der Organisation und den Umschalter „Original anzeigen“.
- **Admin-Formulare:** Für übersetzbare Felder die üblichen Decidim-Formularfelder mit einem Reiter je Sprache verwenden.
- **Nicht `Decidim::TranslatableResource` einbinden.** Dieser Concern übersetzt sofort beim Speichern in alle Sprachen (`after_create :machine_translation`, `after_update :machine_translation` in `decidim-core/lib/decidim/translatable_resource.rb`). Gewünscht ist Übersetzung nur bei Abruf.
- **Eigener Concern `Decidim::Textwork::LazyTranslatable`:** Liegt für die angefragte Sprache weder ein Text von Hand noch eine maschinelle Übersetzung vor und ist `Decidim.machine_translation_service_klass` gesetzt, wird einmalig `Decidim::MachineTranslationFieldsJob.perform_later(resource, field_name, originaltext, target_locale, source_locale)` angestoßen. Bis das Ergebnis da ist, erscheint der Originaltext mit dem Vermerk „Übersetzung wird erstellt“.
- **Speichern erzeugt keine Version (am Code geprüft):** `Decidim::MachineTranslationSaveJob` schreibt die Übersetzung mit `update_column` in das Feld. Das löst keine Callbacks aus, also weder eine Traceable-Version noch eine `BlockVersion`.
- **Pflicht für den Concern:** Er muss die Klassenmethode `translatable_fields_list` bereitstellen. `MachineTranslationSaveJob` ruft sie für gemeldete Ressourcen auf (`resource_completely_translated?`); ohne sie bricht der Job dort ab.
- **Auslöser:** der erste Abruf in einer Sprache, auch durch nicht angemeldete Personen. Blöcke beim Öffnen des Dokuments, Vorschläge und Begründungen erst, wenn das Panel sie anzeigt.
- **Doppelte Aufträge vermeiden:** je Feld und Sprache höchstens ein laufender Auftrag (zum Beispiel über einen Cache-Schlüssel mit kurzer Laufzeit).
- **Verfall:** Ändert sich der Originaltext eines Feldes, werden im selben Speichervorgang `machine_translations` und die von Hand eingetragenen Texte der anderen Sprachen geleert, weil sie zum alten Text gehören (von Claude gesetzte Regel, nicht ausdrücklich entschieden).
- **Fassungen zählen nur den Originaltext.** Eine `BlockVersion` entsteht ausschließlich durch Import, Annahme eines Vorschlags oder redaktionelle Änderung des Originaltexts. Eine von Hand eingetragene Übersetzung erzeugt keine neue Fassung.
- **Kommentare** übersetzt der Kern wie überall sofort (`Decidim::Comments::Comment` bindet `TranslatableResource` ein). Das bleibt unverändert.

### 3.8 Benachrichtigungen

| Ereignis | Empfänger:innen |
| --- | --- |
| Vorschlag angenommen | Verfasser:in; wer dem Kapitel folgt; wer dem Kapitel zugestimmt hat („Das Kapitel hat sich geändert“) |
| Vorschlag abgelehnt | Verfasser:in, mit Begründung |
| Redaktionelle Änderung | Wer dem Kapitel folgt; wer dem Kapitel zugestimmt hat |
| Neuer Änderungsvorschlag | Wer dem Kapitel folgt |
| Neuer Kommentar an einem Absatz | Wer dem Kapitel folgt; sonst Kern-Verhalten für Kommentare |
| Neuer Kommentar an einem Vorschlag | Verfasser:in des Vorschlags (Kern-Verhalten, prüfen) |
| Block eingefügt, entfernt oder umgestellt | Wer dem betroffenen Kapitel folgt; bei entferntem Block zusätzlich die Verfasser:innen der dadurch abgelehnten Vorschläge |

Bei Dokumenten ohne Überschriften gilt „Kapitel“ sinngemäß für das Dokument.

### 3.9 Berechtigungen und Einstellungen

- **Berechtigungen wie bei anderen Komponenten.** Die Aktionen `comment`, `like`, `suggest` werden im Komponenten-Manifest als `component.actions` angemeldet, damit Admins je Aktion eine Verifizierung verlangen können. Vorbild für das Zusammenspiel von Manifest und Permissions-Klasse: `decidim-proposals/lib/decidim/proposals/component.rb` (nur lesen, nichts kopieren) und `decidim-collaborative_texts/app/permissions/`.
- **Standard:** alle angemeldeten Personen dürfen kommentieren, zustimmen und vorschlagen. Annehmen, Ablehnen und redaktionelle Änderungen nur im Admin-Bereich durch Personen mit Admin-Rechten für den Beteiligungsraum.
- **Einstellungen je Phase** (`component.settings(:step)`): `comments_blocked`, `suggestions_blocked`, `likes_blocked`, jeweils boolean, Standard false. Global: `comments_max_length` wie in `decidim-debates/lib/decidim/debates/component.rb`.
- **Gesperrte Aktion:** Das Symbol bleibt sichtbar und zeigt vorhandene Beiträge, neue sind nicht möglich.

**Namen der Einstellungen für das Like (am Code geprüft):** Die Cell `decidim/like_buttons` fragt die Einstellungen der Komponente ab. Andere Module verwenden dafür `likes_enabled` (global, Standard true) und `likes_blocked` (je Phase), siehe `decidim-debates/lib/decidim/debates/component.rb`. Dieselben Namen verwenden, zusätzlich zu den oben genannten.

## 4. Zuordnung: Mockup-Funktion zu Decidim-Baustein

Jede Funktion des Mockups nutzt einen vorhandenen Baustein aus dem Decidim-Kern oder ist ausdrücklich Eigenbau. Die Fundstellen wurden in 0.32 nachgesehen; die Verwendung im Detail muss jeweils in der Datei gelesen werden.

| Mockup | Baustein | Fundstelle in Decidim 0.32 |
| --- | --- | --- |
| Komponente, die man einem Beteiligungsprozess hinzufügt | Komponenten-Manifest | `decidim-collaborative_texts/lib/decidim/collaborative_texts/component.rb`, `engine.rb`, `admin_engine.rb` |
| Kommentare am Absatz und am Vorschlag | `Decidim::Comments::Commentable`, Helper `comments_for` | `decidim-comments/lib/decidim/comments/commentable.rb`; Verwendung in `decidim-debates/app/views/decidim/debates/debates/show.html.erb` |
| „Stimme zu“ am Kapitel und am Vorschlag | `Decidim::Likeable`, Cell `decidim/like_block` | `decidim-core/lib/decidim/likeable.rb`, `decidim-core/app/cells/decidim/like_block_cell.rb`; Verwendung in `decidim-blogs/app/views/decidim/blogs/posts/_actions.html.erb` |
| „Stimme zu“ am Kommentar | Eigene Stimmen des Kommentar-Moduls (Modell CommentVote), eingeschaltet über die Methode comments\_have\_votes? an Block und Suggestion | `decidim-comments` (am Code geprüft: lib/decidim/comments/commentable.rb, app/cells/decidim/comments/comment/votes.erb. Der Kern zeigt Zustimmung und Ablehnung immer gemeinsam, einen Schalter nur für Zustimmung gibt es nicht) |
| „Folgen“ am Kapitel | `Decidim::Followable`, Cell `decidim/follow_button` | `decidim-core/lib/decidim/followable.rb`, `decidim-core/app/cells/decidim/follow_button_cell.rb` |
| „Melden“ an einem Änderungsvorschlag (an Kommentaren über den Kern) | `Decidim::Reportable`, Cell `decidim/report_button` | `decidim-core/lib/decidim/reportable.rb`, `decidim-core/app/cells/decidim/report_button_cell.rb` |
| Verfasser:in eines Vorschlags | `Decidim::Authorable` | `decidim-core/lib/decidim/authorable.rb` |
| Protokoll im Admin-Bereich | `Decidim::Traceable`, `Decidim::Loggable` | wie in `decidim-collaborative_texts/app/models/` |
| Benachrichtigung bei Annahme und Ablehnung | Ereignisklasse und `Decidim::EventsManager.publish` | `decidim-collaborative_texts/app/events/decidim/collaborative_texts/suggestion_accepted_event.rb`, `app/commands/decidim/collaborative_texts/rollout.rb` |
| Vorschlag anlegen | Command und Form | `decidim-collaborative_texts/app/commands/decidim/collaborative_texts/create_suggestion.rb`, `app/forms/decidim/collaborative_texts/suggestion_form.rb` |
| Rechte (wer darf vorschlagen, annehmen) | Permissions-Klassen | `decidim-collaborative_texts/app/permissions/decidim/collaborative_texts/permissions.rb` und `admin/permissions.rb` |
| Verhalten im Browser | Stimulus-Controller | Vorbilder in `decidim-core/app/packs/src/decidim/controllers/` (`dropdown`, `toggle`, `clipboard_copy`, `tooltip`) |
| Drei-Punkte-Menü, Tooltip, Link kopieren | Vorhandene Controller `dropdown`, `tooltip`, `clipboard_copy` | ebenda |
| Versionsverlauf eines Absatzes (Drei-Punkte-Menü) | Decidim::ResourceVersionsConcern, Cells decidim/versions\_list, decidim/version und decidim/diff. Grundlage sind die Versionen aus Decidim::Traceable am Block | decidim-core/app/controllers/concerns/decidim/resource\_versions\_concern.rb, decidim-core/app/cells/decidim/version\_cell.rb und diff\_cell.rb; vollständiges Beispiel: decidim-debates/app/controllers/decidim/debates/versions\_controller.rb mit den Ansichten unter app/views/decidim/debates/versions/. Prüfen: welche Diff-Renderer-Klasse die Diff-Cell für eine eigene Ressource erwartet, und dass nur Änderungen am Text eine Version erzeugen (Zähler und Position nicht) |

### Eigenbau, weil es im Kern nichts Passendes gibt

| Funktion | Hinweis |
| --- | --- |
| Leseansicht mit Symbolspalte, Panel und mobilem Sheet | Eine Seite, Panel-Inhalt wird nachgeladen (siehe Abschnitt 5) |
| Wortgenauer Vergleich mit Markierung im Text | Im Browser für die Live-Vorschau, auf dem Server für gespeicherte Vorschläge. Der Kern hat `decidim/diff` (`decidim-core/app/cells/decidim/diff_cell.rb`, `lib/decidim/diffy_extension.rb`); prüfen, ob sich damit ein Wortvergleich im Fließtext erzeugen lässt. Sonst den Algorithmus aus dem Mockup übernehmen (Abschnitt 5.4) |
| Fassungen je Absatz | Eigene Tabelle, siehe 3.3 |
| Annehmen und Ablehnen im Admin-Bereich | Eigene Admin-Ansicht und Commands |
| Textimport | Vorlage im alten Plugin: `lib/decidim/enhanced_textwork/html_to_markdown.rb` und die Importlogik der partizipativen Texte dort |

## 5. Oberfläche

Es gibt genau eine öffentliche Seite je Dokument. Alles Weitere (Kommentare, Vorschläge, Detail, Bearbeiten) geschieht in einem Panel auf derselben Seite, ohne Seitenwechsel. Das Mockup ist die verbindliche Vorlage für Aufbau, Texte und Verhalten.

### 5.1 Seitenaufbau

| Bereich | Desktop (ab ca. 1024 px) | Mobil |
| --- | --- | --- |
| Inhaltsverzeichnis | Linke Spalte. Bei offenem Panel eingeklappt, über Button „Inhaltsverzeichnis“ wieder einblendbar | Eingeklappt über dem Text (`details`) |
| Text | Mittlere Spalte, Absatz höchstens ca. 34em breit (55–75 Zeichen je Zeile), Schrift 18–20 px, Zeilenhöhe 1,5 | Volle Breite, 18 px |
| Symbole je Absatz | Rechts neben dem Absatz: Bleistift (mit Zahl offener Vorschläge) und Sprechblase (mit Zahl der Kommentare). Beide immer sichtbar, Zahl nur wenn größer 0 | Unter dem Absatz |
| Symbole je Kapitel | Rechts neben der Überschrift: Daumen mit Text „Stimme zu · n“ und Glocke (Folgen) | Daumen mit Text rechts neben der Überschrift |
| Panel | Rechte Spalte, ca. 420 px | Bottom-Sheet über ca. drei Viertel der Höhe, mit abgedunkeltem Hintergrund |

Über dem Text steht einmal der Satz: „So beteiligen Sie sich: Neben jedem Absatz können Sie über \[Sprechblase\] kommentieren und über \[Bleistift\] eine Änderung vorschlagen.“ Er ist Fließtext, keine Schaltfläche.

### 5.2 Auslöser und Zustände

| Aktion | Ergebnis |
| --- | --- |
| Klick auf Sprechblase | Panel öffnet mit Reiter „Kommentare“ für diesen Absatz |
| Klick auf Bleistift, Absatz hat offene Vorschläge | Panel öffnet mit Reiter „Änderungsvorschläge“; der erste Vorschlag wird im Text markiert |
| Klick auf Bleistift, Absatz hat keine offenen Vorschläge | Bearbeitung startet direkt |
| Klick auf Absatznummer | Adresse zeigt auf den Absatz, Panel öffnet mit „Kommentare“ |
| Klick auf den Absatztext (nur Desktop, nur wenn kein Text markiert wurde) | Panel öffnet mit „Kommentare“ |
| Klick auf einen Eintrag im Inhaltsverzeichnis | Weich zum Kapitel scrollen, Überschrift ca. 2 Sekunden hervorheben, Eintrag als aktuell markieren |
| Schließen (X, mobil auch Klick auf den Hintergrund) | Panel zu, Fokus zurück auf das auslösende Symbol |

Der ausgewählte Absatz bekommt eine getönte Fläche und einen 2 px starken Rahmen mit mindestens 3:1 Kontrast.

### 5.3 Inhalte des Panels

Kopf: „Absatz \[Nummer\]“, darunter „Fassung \[n\] · zuletzt geändert am \[Datum\]“ bzw. „Fassung 1 · Ausgangstext“, Drei-Punkte-Menü (Link zum Absatz kopieren, Versionsverlauf), Schließen. Mobil zusätzlich der Absatztext als Zitat, weil das Sheet den Text verdeckt.

| Ansicht | Inhalt | Hauptaktion unten |
| --- | --- | --- |
| Reiter „Kommentare (n)“ | Kommentarliste aus dem Kern, je Kommentar „Stimme zu“ und „Antworten“. Leerhinweis, wenn keine | Eingabefeld und „Kommentieren“ |
| Reiter „Änderungsvorschläge (n)“ | Karten der offenen Vorschläge. Ab zwei Vorschlägen Sortierung „Meiste Zustimmung“ (Standard) oder „Neueste zuerst“. Darunter ein Link „Anzeigen: abgeschlossene Vorschläge (n)“ | „Eigene Änderung vorschlagen“ |
| Karte | Status „Offen“, Datum und „zu Fassung n“, Link „Vorschlag von \[Name\]“ (öffnet Detail), die geänderte Stelle mit etwa drei Wörtern davor und danach, „Stimme zu · n“, „Im Text zeigen“ oder Vermerk „Im Text markiert“ |  |
| Detail eines Vorschlags | Zurück-Link „Alle Änderungsvorschläge“, Status, Verfasser:in, Datum, Fassung, Überschrift „Änderungsvorschlag zu Absatz \[Nummer\]“, Begründung, „Stimme zu“, Kommentare zum Vorschlag | Eingabefeld und „Kommentieren“ |
| Bearbeiten | Hinweis „Zu diesem Absatz gibt es bereits n Vorschläge. Passt einer davon, genügt Ihre Zustimmung.“ (nur wenn n > 0), Feld „Begründung (optional)“ | „Abbrechen“ und „Vorschlag einreichen“ (gesperrt, solange nichts geändert ist) |

Abgeschlossene Vorschläge tragen „Angenommen“ oder „Abgelehnt“ (mit Begründung der Moderation). Zurückgezogene erscheinen nicht. Ein offener Vorschlag, der sich auf eine ältere Fassung bezieht, bleibt in der offenen Liste und zeigt zusätzlich den Hinweis „Der Absatz wurde seither geändert.“ Eigene offene Vorschläge zeigen „Zurückziehen“ und, solange niemand zugestimmt oder kommentiert hat, „Bearbeiten“.

### 5.4 Änderung im Text

- **Ansehen (Desktop):** Ist ein Vorschlag gewählt, zeigt der Absatz in der Textspalte dessen Änderung. Darüber steht „Vorschau: Vorschlag i von n · \[Name\]“, bei mehreren mit Pfeilen zum Blättern. Im Reiter „Kommentare“ und bei geschlossenem Panel steht die gültige Fassung.
- **Ansehen (mobil):** Die Änderung steht in der Karte und im Detail im Sheet, nicht im Text.
- **Bearbeiten (Desktop):** Der Absatz wird zum Eingabefeld mit der Beschriftung „Sie bearbeiten diesen Absatz“, vorbefüllt mit dem aktuellen Text. Direkt darunter „So sieht Ihre Änderung aus“ mit der markierten Fassung, die beim Tippen mitläuft.
- **Bearbeiten (mobil):** Eingabefeld und markierte Fassung stehen im Sheet.
- **Markierung:** Einfügungen in `ins` (grün hinterlegt und unterstrichen), Streichungen in `del` (rot hinterlegt und durchgestrichen). Nie nur Farbe.
- **Entwurf schützen:** Wer mit geändertem Text abbricht, das Panel schließt oder einen anderen Absatz wählt, bekommt die Rückfrage „Entwurf verwerfen?“ mit „Weiter bearbeiten“ und „Verwerfen“.

* **Eingabefeld:** ein einfaches mehrzeiliges Textfeld mit dem Absatztext in der Markdown-Teilmenge (3.1), kein Editor mit Werkzeugleiste. Unter dem Feld steht bei Listen der Hinweis: „Eine neue Zeile, die mit ‚- ‘ beginnt, fügt einen Listenpunkt hinzu.“
* **Vergleich bei mehrzeiligem Text:** zuerst zeilenweise (eine neue Zeile ist ein eingefügter Listenpunkt, eine entfernte ein gestrichener), innerhalb geänderter Zeilen der Wortvergleich unten. Auszeichnungszeichen wie `**` zählen als Teil des Wortes.
* **Übersetzte Ansicht:** Beim Bearbeiten erscheint immer der Originaltext, mit dem Hinweis „Änderungen beziehen sich auf den Originaltext (\[Sprache\]).“ Vorhandene Vorschläge erscheinen als übersetzter vollständiger Text ohne Wortmarkierung, mit dem Link „Original mit Markierung anzeigen“. Solange eine Übersetzung noch erstellt wird, steht der Originaltext da, mit dem Vermerk „Übersetzung wird erstellt“.

Der Wortvergleich aus dem Mockup, als Ausgangspunkt für die Browser-Seite:

```javascript
const words = (t) => String(t).trim().split(/\s+/).filter(Boolean);
// Satzzeichen am Wortende zählen nicht als Änderung des Wortes
const eq = (a, b) => a.replace(/[.,;:!?]+$/, "") === b.replace(/[.,;:!?]+$/, "");

// Liefert Segmente { text, kind } mit kind "same" | "ins" | "del" (längste gemeinsame Teilfolge auf Wortebene)
function diffWords(original, replace) {
  const x = words(original), y = words(replace), n = x.length, m = y.length;
  const t = Array.from({ length: n + 1 }, () => new Array(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      t[i][j] = eq(x[i], y[j]) ? t[i + 1][j + 1] + 1 : Math.max(t[i + 1][j], t[i][j + 1]);
    }
  }
  const out = [];
  const push = (kind, w) => {
    const last = out[out.length - 1];
    if (last && last.kind === kind) last.text += " " + w; else out.push({ kind, text: w });
  };
  let i = 0, j = 0;
  while (i < n && j < m) {
    if (eq(x[i], y[j])) { push("same", y[j]); i++; j++; }
    else if (t[i + 1][j] >= t[i][j + 1]) { push("del", x[i]); i++; }
    else { push("ins", y[j]); j++; }
  }
  while (i < n) push("del", x[i++]);
  while (j < m) push("ins", y[j++]);
  return out;
}
```

Bekannte Schwäche: Eine reine Änderung von Satzzeichen wird als geändert erkannt, aber nicht markiert.

### 5.5 Adressen

| Zustand | Adresse |
| --- | --- |
| Dokument | `/…/textwork/documents/:id` |
| Absatz geöffnet | `…/documents/:id?block=:block_id` |
| Vorschlag geöffnet | `…/documents/:id?block=:block_id&suggestion=:suggestion_id` |

Beim Laden mit diesen Parametern zum Absatz scrollen und das Panel im passenden Zustand öffnen. Die Adresse ändert sich beim Öffnen und Schließen ohne Neuladen (`history.pushState`). Benachrichtigungen und „Link kopieren“ verwenden diese Adressen. Eine eigene Seite für einen einzelnen Vorschlag gibt es nicht.

**Blöcke und Vorschläge müssen für Decidim adressierbar sein.** Kommentare, Benachrichtigungen, Melden und der Versionsverlauf verlinken auf das betroffene Objekt und fragen dafür dessen Adresse über den Kern ab. `Block` und `Suggestion` werden deshalb im Komponenten-Manifest als Ressourcen angemeldet und bekommen je eine Route, die auf die Dokumentseite mit `?block=` bzw. `&suggestion=` weiterleitet. Eine eigene Ansicht haben sie nicht. Wie das Anmelden geht, im Kern nachlesen (`register_resource` in den `component.rb`-Dateien anderer Module und `Decidim::ResourceLocatorPresenter`).

### 5.6 Nachladen des Panels

Der Panel-Inhalt kommt als HTML-Fragment vom Server (eigene Controller-Aktionen für Kommentare, Vorschlagsliste, Detail). So lässt sich die Kommentar-Ansicht des Kerns unverändert verwenden. Prüfen, wie `decidim-comments` seine Kommentare initialisiert, wenn sie nachträglich in die Seite eingefügt werden.

### 5.7 Nicht angemeldet

Alles ist lesbar. Bei „Kommentieren“, „Stimme zu“, „Folgen“ und „Eigene Änderung vorschlagen“ öffnet sich der Anmelde-Dialog von Decidim. Nach der Anmeldung landet die Person wieder am selben Absatz.

## 6. Bauschritte

Die Schritte bauen aufeinander auf und sind einzeln prüfbar. Nach jedem Schritt läuft die Instanz und die Tests sind grün.

### Schritt 0: Erkundung, bevor etwas gebaut wird

Kläre die folgenden Punkte im Code von Decidim 0.32 und schreibe das Ergebnis in `docs/ERKUNDUNG.md` (je Punkt: Befund, Fundstelle, Folge für diese Anleitung). Baue erst danach. Widerspricht ein Befund der Anleitung, halte an und frage nach.

1. Welche Zählerspalten erwarten `Decidim::Comments::Commentable`, `Decidim::Likeable` und `Decidim::Followable` an einem Modell?
2. Bereits geklärt: Das Kommentar-Modul hat eigene Stimmen (Zustimmung und Ablehnung), die nur gemeinsam einschaltbar sind. Entschieden ist, beide wie im Kern zu zeigen. Hier ist nichts mehr zu prüfen.
3. Wie initialisiert `decidim-comments` Kommentare, die nachträglich als HTML-Fragment in die Seite eingefügt werden?
4. Wie werden die Cells `decidim/like_block` und `decidim/follow_button` für eine eigene Ressource verwendet, und lassen sich Text und Darstellung („Stimme zu · n“) über Übersetzungsschlüssel oder Optionen anpassen, ohne die Cell zu überschreiben?
5. Funktionieren `Decidim::MachineTranslationFieldsJob` und `Decidim::MachineTranslationSaveJob` für ein Modell, das `Decidim::TranslatableResource` nicht einbindet? Was setzen sie voraus?
6. Welche Diff-Renderer-Klasse erwartet `decidim/diff` für eine eigene Ressource, und kann der Kern einen Wortvergleich im Fließtext liefern?
7. Erzeugt `Decidim::Traceable` bei jeder Attributänderung eine Version, und wie lässt sich das auf Änderungen am Text beschränken?
8. Welche Markdown-Bibliothek bringt Decidim 0.32 mit, und wie wird ihre Ausgabe bereinigt?
9. Wie melden andere Komponenten eigene Aktionen in `component.actions` an, sodass Admins je Aktion eine Verifizierung verlangen können?
10. Welche Benachrichtigungen löst das Kommentar-Modul von sich aus aus (an Verfasser:innen, an Folgende der kommentierten Ressource)?
11. Unter welcher Lizenz steht Decidim (Gemspec des Kerns)?
    - Fertig, wenn: `docs/ERKUNDUNG.md` alle elf Punkte mit Fundstelle beantwortet.

Zusätzlich zu klären, mit demselben Ergebnisformat:

- **Adresse einer Ressource:** Was verlangt der Kern, damit Kommentare, Benachrichtigungen und Melden auf einen `Block` oder eine `Suggestion` verlinken können (Anmeldung als Ressource, Routenname, `ResourceLocatorPresenter`)?
- **Kommentare zweier Ressourcen auf einer Seite:** Kann die Kommentar-Ansicht des Kerns auf derselben Seite nacheinander für verschiedene Blöcke und für einen Vorschlag geladen werden, ohne dass sich Abfragen oder Formulare gegenseitig stören?
- **Gemeldete Inhalte:** Wie blendet `Decidim::Reportable` eine gemeldete und verborgene Ressource aus Listen aus, und welche Abfrage müssen Zähler verwenden?

Zu Punkt 5 ist bereits bekannt: Der Speicher-Job schreibt mit `update_column` und setzt `translatable_fields_list` voraus (Abschnitt 3.7). Zu prüfen bleibt, was die Klasse des Übersetzungsdienstes vom Modell erwartet.

1. **Gerüst.** Gem `decidim-textwork` nach dem Muster von `decidim-collaborative_texts` anlegen: Gemspec, Engine, Admin-Engine, Komponenten-Manifest mit den Aktionen und Einstellungen aus 3.9, leere Übersetzungsdateien, Test-Setup. In eine Decidim-0.32-Testanwendung einbinden.
   - Fertig, wenn: die Komponente „Textwork“ lässt sich im Admin-Bereich einem Beteiligungsprozess hinzufügen und zeigt eine leere Seite.
2. **Datenmodell.** Migrationen und Modelle für `Document`, `Block`, `BlockVersion`, `Suggestion` nach Abschnitt 3, mit Factories und Modelltests. Ein Helfer, der die Markdown-Teilmenge (3.1) in bereinigtes HTML umwandelt; prüfen, welche Markdown-Bibliothek Decidim 0.32 bereits mitbringt.
   - Fertig, wenn: die Regeln aus 3.6 als Tests bestehen, insbesondere `outdated?`, die Nummernberechnung und die Bedingungen für Bearbeiten und Zurückziehen.
3. **Admin: Dokument anlegen und Text importieren.** Formular mit Titel, Beschreibung, Originalsprache und dem Editor des Admin-Bereichs für den Text. Beim Speichern wird das HTML des Editors in Blöcke zerlegt: Überschriften der Ebenen 1 bis 3 werden `heading`-Blöcke, jeder Absatz und jede ganze Liste ein `paragraph`-Block mit Fassung 1 in der Markdown-Teilmenge. Vorlage für die Umwandlung: `lib/decidim/enhanced_textwork/html_to_markdown.rb` im alten Plugin. Veröffentlichen und Zurückziehen.
   - Fertig, wenn: das Beispieldokument „Ein grüneres Viertel“ aus dem Mockup zwei Kapitel mit drei Absätzen ergibt und eine eingefügte Aufzählung ein einziger Block wird.
4. **Leseansicht ohne Panel.** Titel, Beschreibung, Inhaltsverzeichnis, Kapitel und Absätze mit Nummern, Symbolspalte mit Zählern (noch ohne Funktion), Einleitungssatz. Desktop und mobil.
   - Fertig, wenn: die Seite bei 1440 px und 390 px dem Mockup im geschlossenen Zustand entspricht und bei 320 px nicht horizontal scrollt.
5. **Panel mit Kommentaren.** Stimulus-Controller für Öffnen, Schließen, Auswahl des Absatzes und die Adresse (5.2, 5.5). Reiter „Kommentare“ mit den Kommentaren des Kerns am Block. Mobil als Bottom-Sheet.
   - Fertig, wenn: ein angemeldeter Mensch an Absatz 1.1 kommentieren kann, der Zähler steigt und die Adresse mit `?block=` den Absatz nach dem Neuladen wieder öffnet.
6. **Zustimmung und Folgen.** `Likeable` und `Followable` an Überschrift-Blöcken, bei Dokumenten ohne Überschriften am Dokument. Darstellung als „Stimme zu · n“ bzw. „Zugestimmt · n“. Zustimmung an Kommentaren über das Kommentar-Modul mit Zustimmung und Ablehnung wie im Kern.
   - Fertig, wenn: Zustimmen und Zurücknehmen ohne Neuladen funktionieren und der Zustand nach dem Neuladen stimmt.
7. **Änderungsvorschlag einreichen.** Bearbeiten im Text mit Live-Markierung (5.4) einschließlich Listenpunkten, Command `CreateSuggestion`, Bestätigung „Ihr Änderungsvorschlag wurde eingereicht.“, Entwurfsschutz.
   - Fertig, wenn: ein eingereichter Vorschlag gespeichert ist, in der Liste erscheint, der Bleistift-Zähler steigt und ein ergänzter Listenpunkt als Einfügung markiert wird.
8. **Vorschläge ansehen.** Reiter „Änderungsvorschläge“ mit kompakten Karten, Markierung im Text, Blättern, Sortierung, Detailansicht mit Kommentaren und „Stimme zu“ am Vorschlag.
   - Fertig, wenn: bei einem Absatz mit fünf Vorschlägen jeder einzeln im Text gezeigt werden kann und die Adresse mit `&suggestion=` den Vorschlag öffnet.
9. **Eigene Vorschläge.** Commands `WithdrawSuggestion` und `UpdateSuggestion` mit den Bedingungen aus 3.6, Schaltflächen „Zurückziehen“ und „Bearbeiten“ nur für die Verfasser:in.
   - Fertig, wenn: Bearbeiten nach der ersten Zustimmung oder dem ersten Kommentar nicht mehr angeboten wird und serverseitig abgewiesen wird.
10. **Admin: Annehmen, Ablehnen, redaktionelle Änderung.** Liste der offenen Vorschläge je Dokument mit Vergleich. Annahme mit anpassbarem endgültigem Text und Warnung bei veralteten Vorschlägen, Ablehnung mit Pflichtbegründung, direkte Änderung eines Blocks als neue Fassung, außerdem Einfügen, Entfernen und Umstellen von Blöcken mit Eintrag im Änderungsverlauf des Dokuments (3.4.1, 3.6). Commands `Admin::AcceptSuggestion`, `Admin::RejectSuggestion`, `Admin::UpdateBlock`.
    - Fertig, wenn: nach einer Annahme der Absatz die neue Fassung zeigt, „Fassung 2“ im Panel steht, die übrigen offenen Vorschläge den Hinweis „Der Absatz wurde seither geändert.“ tragen und ihre Annahme die Warnung auslöst.
11. **Übersetzung bei Abruf.** Concern `LazyTranslatable` nach 3.7, Darstellung in übersetzten Ansichten nach 5.4.
    - Fertig, wenn: beim Speichern kein Übersetzungsauftrag für Blöcke und Vorschläge entsteht, der erste Abruf in einer zweiten Sprache genau einen Auftrag je Feld auslöst und eine Textänderung die gespeicherte Übersetzung löscht.
12. **Abgeschlossene Vorschläge, Melden, Rest.** Aufklappbare Liste der angenommenen und abgelehnten Vorschläge, Drei-Punkte-Menü mit „Link kopieren“ und „Versionsverlauf“, „Melden“ in der Detailansicht eines Vorschlags, aktuelles Kapitel im Inhaltsverzeichnis.
    - Fertig, wenn: alle Zustände des Mockups in der Instanz erreichbar sind.
13. **Benachrichtigungen** nach 3.8, je Ereignis eine Ereignisklasse nach dem Vorbild `SuggestionAcceptedEvent`.
    - Fertig, wenn: jede Zeile der Tabelle in 3.8 durch einen Test belegt ist.
14. **Barrierefreiheit und Abschluss.** Tastaturbedienung mit sichtbarem Fokus, Fokus ins Panel beim Öffnen und zurück beim Schließen, Schließen mit Escape, 200 % Vergrößerung, vergrößerte Textabstände, Kontraste mit den Farben der Instanz.
    - Fertig, wenn: ein vollständiger Durchlauf (lesen, kommentieren, zustimmen, vorschlagen) nur mit der Tastatur gelingt.
15. **Datei-Import** (Word, ODT, Markdown), Vorlage: die Importlogik im alten Plugin.
    - Fertig, wenn: eine Word-Datei mit Überschriften und einer Aufzählung dieselben Blöcke ergibt wie das Einfügen im Editor.
16. **Word-Export** in genau einer gewählten Sprache: aktueller Text, je Absatz die offenen Änderungsvorschläge und Kommentare, je Kapitel die Zahl der Zustimmungen. Vorlage `lib/decidim/exporters/word.rb` im alten Plugin.
    - Fertig, wenn: der Export in der Originalsprache und in einer zweiten Sprache jeweils nur diese eine Sprache enthält.

## 7. Umfang der ersten Ausbaustufe

Die Präsentationsinstanz zeigt die Schritte 1 bis 6 als echte Funktion. Was darüber hinaus fertig wird, kommt dazu; der Rest wird am Mockup gezeigt.

| Stufe | Schritte | Was die Präsentation damit zeigt |
| --- | --- | --- |
| Kern der Präsentation | 1 bis 6 | Ein importierter Text in der neuen Leseansicht, Kommentare am Absatz im Panel und im mobilen Sheet, Zustimmung am Kapitel |
| Erweiterung, wenn die Zeit reicht | 7 und 8 | Änderungsvorschläge einreichen und im Text ansehen |
| Danach | 9 bis 16 | Eigene Vorschläge zurückziehen und bearbeiten, Annehmen und Ablehnen mit Fassungen, Übersetzung bei Abruf, abgeschlossene Vorschläge, Benachrichtigungen, Barrierefreiheit im Detail, Datei-Import, Word-Export |

Die Reihenfolge ist bewusst so gewählt: Schritt 10 legt fest, wie Fassungen entstehen, und sollte nicht unter Zeitdruck gebaut werden. Das Datenmodell aus Schritt 2 enthält Fassungen und Status aber von Anfang an, damit später nichts umgebaut werden muss.

In der Präsentation sollte gesagt werden, dass Farben und Schrift der Instanz aus dem Decidim-Designsystem kommen und deshalb leicht vom Mockup abweichen.

## 8. Übernahmefähigkeit

Das Modul soll so gebaut sein, dass das Decidim-Kernteam Teile davon übernehmen kann. Das gelingt nur, wenn es sich wie ein Kernmodul liest.

- **Aufbau wie im Kern:** dieselbe Ordnerstruktur, dieselben Basisklassen für Commands, Forms, Permissions, Cells und Presenter wie in `decidim-collaborative_texts`.
- **Begriffe wie in Collaborative Texts:** `Document`, `Version`, `Suggestion`, `changeset` mit `original` und `replace`, Status `pending`, `accepted`, `rejected`.
- **Nur öffentliche Kern-Bausteine:** keine Überschreibungen von Kern-Ansichten oder Kern-Klassen, keine Decorator.
- **Tests:** Modell-, Command-, Permissions- und Systemtests nach dem Muster des Kerns (`decidim-collaborative_texts/spec`).
- **Übersetzungen:** alle Texte über Schlüssel, Englisch vollständig, Deutsch vollständig.
- **Stil:** Rubocop- und ESLint-Regeln des Decidim-Repositorys übernehmen.
- **Lizenz:** AGPL-3.0 wie Decidim (im Gemspec des Kerns prüfen).
- **Der eigene Beitrag ist benannt:** dauerhafte Absätze (`Block`) mit Fassungen je Absatz, Kommentare und Zustimmung am Absatz bzw. Kapitel. Diese Abweichung von Collaborative Texts im README begründen.

Bezug zu offenen Wünschen im Decidim-Repository, die dasselbe Feld betreffen: [#16593](https://github.com/decidim/decidim/issues/16593) (Vorschläge im Text sichtbar machen), [#16587](https://github.com/decidim/decidim/issues/16587) (Kommentare an Vorschlägen), [#16588](https://github.com/decidim/decidim/issues/16588) (Zustimmung zu Vorschlägen). Deren Stand wurde für diese Anleitung nicht geprüft.

## 9. Entscheidungen

Diese Entscheidungen sind getroffen und gelten. Offen ist nur Nr. 2.

| Nr. | Frage | Entscheidung |
| --- | --- | --- |
| 1 | Name des Moduls | `decidim-textwork`, `Decidim::Textwork` |
| 2 | Wörter an den Absatzsymbolen (Kriterium 11 des Katalogs verlangt, dass kein Symbolwissen nötig ist) | Noch offen, wird im Team geklärt. Bis dahin: nur Symbole mit Tooltip und `aria-label`, erklärt durch den Einleitungssatz. So bauen, dass ein sichtbares Wort später ohne Umbau ergänzt werden kann |
| 3 | Begriff „Stimme zu“ gegen „Unterstützen“ | Gewünscht ist überall „Stimme zu“ mit Daumen. Technisch gibt es im Kern zwei getrennte Bausteine: das allgemeine Like (Decidim::Likeable mit der Cell decidim/like\_buttons) für Kapitel und Änderungsvorschläge, und die eigenen Stimmen des Kommentar-Moduls für Kommentare. Beide werden unverändert verwendet. Ihre Beschriftung kommt aus den Übersetzungsschlüsseln des Kerns (decidim.like\_buttons\_cell.like und already\_liked). Der Wortlaut „Stimme zu“ wird, wenn gewünscht, in der Instanz über deren eigene Übersetzungsdateien gesetzt und gilt dann für alle Komponenten der Instanz. Das Modul überschreibt dafür nichts |
| 4 | Zustimmung an Kommentaren: nur Zustimmung oder auch Ablehnung | Zustimmung und Ablehnung, wie im Decidim-Kern. Umsetzung: die Stimmen des Kommentar-Moduls einschalten (comments\_have\_votes? liefert true). Beide Schaltflächen bleiben sichtbar. Nichts im Kern überschreiben. Symbole, Zähler und Beschriftung kommen vom Kern |
| 5 | Was nach einer Annahme mit den übrigen offenen Vorschlägen geschieht | Sie bleiben normal offen und annehmbar. Bei der Annahme eines solchen Vorschlags warnt das Backend und lässt den endgültigen Text anpassen (3.6) |
| 6 | Benachrichtigung der Verfasser:innen veralteter Vorschläge | Keine eigene Benachrichtigung |
| 7 | Gilt eine Zustimmung zum Kapitel weiter, wenn sich ein Absatz darin ändert | Ja, sie bleibt bestehen. Wer zugestimmt hat, wird über die Änderung benachrichtigt |
| 8 | Formatierung im Absatztext (fett, Links, Listen) | Markdown-Teilmenge mit fett, kursiv, Links und Listen, bearbeitet im einfachen Eingabefeld (3.1). Ein Editor mit Werkzeugleiste für die Formatierung ist eine spätere Ausbaustufe, weil der Wortvergleich davon abhängt |
| 9 | Wer annehmen und ablehnen darf | Admins und Prozess-Admins im Admin-Bereich, nicht im Frontend |
| 10 | Kurze Texte ohne Kapitel | „Stimme zu“ erscheint dann neben dem Dokumenttitel |
| 11 | Schließt „Folgen“ am Kapitel Benachrichtigungen zu Kommentaren und Vorschlägen der Absätze ein | Ja |

| Nr. | Frage | Entscheidung |
| --- | --- | --- |
| 12 | Listen im Text | Eine ganze Liste ist ein Block und wird als Ganzes kommentiert und geändert |
| 13 | Was ein Änderungsvorschlag ändern kann | Den Wortlaut. Listenpunkte lassen sich über eine neue Zeile ergänzen. Das muss nicht elegant sein, aber funktionieren |
| 14 | Eigener offener Vorschlag | Zurückziehen jederzeit. Text bearbeiten nur, solange niemand zugestimmt oder kommentiert hat |
| 15 | Kapitelüberschrift | Nur „Stimme zu“ und „Folgen“. Keine Kommentare, keine Änderungsvorschläge |
| 16 | Worüber „Folgen“ benachrichtigt | Angenommene Änderungen, neue Änderungsvorschläge und neue Kommentare im Kapitel |
| 17 | Import des Ausgangstexts | Zuerst Einfügen im Editor des Admin-Bereichs, später zusätzlich Datei-Upload |
| 18 | Sprachen | Eine Originalsprache je Dokument. Alle Inhalte werden maschinell übersetzt, aber nur beim ersten Abruf in einer Sprache, nie vorab |
| 19 | Änderungsvorschläge in übersetzter Ansicht | Beziehen sich immer auf den Originaltext. Darstellung übersetzt und ohne Wortmarkierung |
| 20 | Übersetzung von Kommentaren | Verhalten des Kerns bleibt (sofort beim Speichern) |
| 21 | Direkte Änderung durch Admins | Erlaubt, erzeugt eine neue Fassung mit Vermerk „redaktionelle Änderung“ |
| 22 | Word-Export | Aktueller Text, offene Änderungsvorschläge, Kommentare und Zustimmung je Kapitel. Immer in genau einer gewählten Sprache; übersetzte Inhalte in ihrer maschinellen Übersetzung |
| 23 | Berechtigungen und Sichtbarkeit | Wie bei anderen Decidim-Komponenten über das System, kein eigener Mechanismus |
| 24 | Schalter je Phase | Kommentare, Änderungsvorschläge und Zustimmung einzeln sperrbar (von Claude gewählter Standard, nicht ausdrücklich entschieden) |
| 25 | Begründung eines Vorschlags | Optional (von Claude gewählter Standard, nicht ausdrücklich entschieden) |
| 26 | Versionsverlauf | Nach dem Standard des Decidim-Kerns: eigene Seite je Absatz mit Liste der Fassungen und Vergleich, wie bei Debatten. Keine eigene Darstellung im Panel |
| 27 | Änderungen am Aufbau nach der Veröffentlichung | Admins dürfen Absätze und Überschriften einfügen, entfernen und umstellen. Jede Änderung wird als Version im Änderungsverlauf des Dokuments festgehalten. Entfernte Blöcke bleiben mit ihren Beiträgen gespeichert |
| 28 | Melden | Nur an Änderungsvorschlägen und Kommentaren, nicht am Absatz. Verborgene Vorschläge verschwinden aus Listen und Zählern |

Nicht Teil dieser Anleitung: Datenumzug aus `decidim-enhanced_textwork`, Vorschläge über mehrere Absätze, gemeinsames Bearbeiten in Echtzeit.
