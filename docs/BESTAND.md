# Bestand vor dem Umbau zur Sammelphase

Stand der Bestandsaufnahme: 6. Oktober 2026, Schritt 0.
Die anschließende Umsetzung von Schritt 1 ist am Ende dieser Datei dokumentiert.
Die Bestandsaufnahme bleibt als Ausgangslage erhalten. Für den fertig umgebauten
Stand siehe [SAMMELPHASE-IMPLEMENTATION.md](SAMMELPHASE-IMPLEMENTATION.md).

Geprüfter Modulstand: `f3421d1ddecf9d2b6fe86b9689818161abc51a57`, Branch
`feature/textwork-redesign`, Gem `decidim-enhanced_textwork` in Version
`2.0.0.alpha3`. Der Nutzer hat ausdrücklich festgelegt, auf diesem Branch zu
bleiben. Der Paketname `decidim-textwork` bezeichnet hier dasselbe Vorhaben,
keinen neuen Gemnamen.

Grundlage ist der [Umbauauftrag vom 6. Oktober](../../../decidim-enhanced_textwork/textwork-umbau/docs/UMBAUAUFTRAG.md)
mit dem vorrangigen [Nachtrag nach Schritt 0, Fassung 3](AENDERUNGEN_ZUM_UMBAUAUFTRAG.md).
Das Paket liegt derzeit im ursprünglichen Checkout, außerhalb dieses Worktrees.
Es wurde in Schritt 0 weder verschoben noch verändert. Die bisherige Übergabe
liegt versioniert in `textwork-uebergabe/`. Fassung 3 wurde anschließend als
unveränderte Kopie der Nutzeranlage in diesem Worktree gesichert. Die Entscheidungen
sind in [ERKUNDUNG.md](ERKUNDUNG.md#nachtrag-zum-umbauauftrag) nachgeführt.
Fassung 3 kennzeichnet alle Punkte als bestätigt und löst frühere offene Punkte ab.
Die Kennzeichnungen unten beschreiben den vorgesehenen Umbau,
ausgehend vom geprüften Bestand vor Schritt 1. Die Umsetzungsnotizen am Ende
unterscheiden bereits erledigte Änderungen von den weiteren Schritten.

## Kennzeichnungen

- **bleibt**: wird weiterverwendet, ohne vorgesehenen fachlichen Umbau.
- **ändert sich**: bleibt Grundlage, bekommt andere Regeln oder Darstellung.
- **wird abgeschaltet**: bleibt für die spätere Auswertung erhalten, ist in der
  Sammelphase weder über Oberfläche noch über direkte Aufrufe erreichbar.
- **entfällt**: gehört ausschließlich zur bisherigen Bedienung und wird entfernt.

Bei einer Datei mit mehreren Aufgaben sind die betroffenen Teile getrennt genannt.
Tabellen und bisherige Beiträge werden nicht wegen entfallender Oberfläche gelöscht.

## Modelle und gespeicherte Daten

Modellpfade sind relativ zu `app/models/decidim/enhanced_textwork/`.

| Eintrag / Datei | Kennzeichnung | Bestand und Folge des Auftrags |
| --- | --- | --- |
| `application_record.rb` | bleibt | Gemeinsame abstrakte Basis aus Decidim. |
| `document.rb` / `decidim_textwork_documents` | ändert sich | Eine Ressource je Komponente; Titel, Beschreibung, Originalsprache, Veröffentlichung, Soft-Delete, Übersetzungen, Like-/Follow-Zähler. Folgen ist derzeit an `likeable?` gekoppelt und nur ohne Kapitel erlaubt. Künftig Dokument-Folgen unabhängig von Kapiteln; keine Dokumentzustimmung. Nummerierung und Suche müssen Bilder überspringen bzw. passend behandeln. Veröffentlichungs-/Bearbeitungssperre fehlt. |
| `block.rb` / `decidim_textwork_blocks` | ändert sich | Stabile IDs, Position, `heading_depth`, Markdown-Text, aktuelle Fassungsnummer, Übersetzungen, Entfernen-Marker und Zähler. Nur `heading` / `paragraph`; Bilder fehlen. Core-Likes/-Follows sind eingebunden, Likes/Folgen derzeit nur an Überschriften. Künftig Likes nur an Absätzen, kein Block-Folgen; Kommentare weiterhin nur an Absätzen. Benachrichtigungen künftig an Dokument-Folgende. |
| `suggestion.rb` / `decidim_textwork_suggestions` | ändert sich | Vollständiger Ersatztext, Begründung, Autor, Bezug zur Ausgangsfassung, Changeset, Moderation, Kommentare und Core-Likes. `pending`, `accepted`, `rejected`, `withdrawn`. Liste schließt withdrawn aus, enthält aber akzeptierte/abgelehnte. Künftig öffentliche Sammelliste nur pending. Eigene Zustimmung ist bisher erlaubt und muss gesperrt werden. Bearbeiten/Zurückziehen brauchen Phasensperren. |
| `Suggestion#editable_by?`, `feedback_received_at` | bleibt | Bearbeitung nur vor dem ersten Feedback; Rücknahme von Likes oder Löschung von Kommentaren hebt die Sperre nicht wieder auf. Diese vorhandene dauerhafte Regel erhalten. |
| `Suggestion#outdated?`, Entscheidungseigenschaften | wird abgeschaltet | Für spätere Auswertung behalten; Hinweise/Sonderfälle in der Sammeloberfläche entfernen. Vorhandene Entscheidungen nicht auf pending zurücksetzen. |
| `block_version.rb` / `decidim_textwork_block_versions` | wird abgeschaltet | Unveränderliche Originalfassungen mit Herkunft, Autor und ggf. angenommenem Vorschlag. Bezug wird von jedem Vorschlag benötigt. Tabelle/Modell bleiben; öffentliche Darstellung wird abgeschaltet. Vorbereitung schreibt intern weiter Fassungen; bei veröffentlichtem Dokument keine neuen Fassungen. |
| `document_revision.rb` / `decidim_textwork_document_revisions` | wird abgeschaltet | Unveränderlicher Strukturverlauf für Import, Hinzufügen, Entfernen, Verschieben. Tabelle/Modell bleiben; keine öffentliche Verlaufsansicht in der Sammelphase. Vorbereitung schreibt intern weiter Strukturverlauf. |
| `translation_request.rb` / `decidim_textwork_translation_requests` | bleibt | Dauerhafte Übersetzungsaufträge nach Ressource, Feld, Sprache und Originaldigest; Schutz vor verspäteten Ergebnissen. |
| `app/models/concerns/decidim/enhanced_textwork/original_language.rb` | bleibt | Originalsprache, Lese-Fallback, Aufbewahrung veralteter manueller Übersetzungen. Automatische Übersetzung ist keine Originaländerung. |

Die Spalten stehen in [AddTextworkRedesign](../db/migrate/20261005120000_add_textwork_redesign.rb).
[RenameTextworkHeadingDepth](../db/migrate/20261005190000_rename_textwork_heading_depth.rb)
trennt Kapitelgliederung von der Core-Kommentartiefe. Bestehende Migrationen nicht
nachträglich umschreiben.

| Weitere Tabelle / Anbindung | Kennzeichnung | Folge |
| --- | --- | --- |
| `decidim_likes` | ändert sich | Core-Tabelle mit polymorpher Ressource und Autor; keine eigene Reaktionstabelle nötig. Neue Absatz-Likes sind neue Datensätze. Kapitel-Likes bleiben gespeichert und zählen nicht als Absatz-Likes. Vorhandene eigene Vorschlags-Likes zählen weiter, neue sind verboten. Nur der Like-Autor darf sie bei offener Phase/Frist zurücknehmen; am eigenen Vorschlag erscheint dafür bei vorhandenem Like der Link „Eigene Zustimmung zurücknehmen“. |
| `decidim_follows` | ändert sich | Core-Tabelle; neue Oberfläche folgt dem Dokument. Übernahme alter Kapitel-Abonnements auf Dokumentebene ist nicht festgelegt, keine automatische Umdeutung. |
| `decidim_comments_comments`, Core-Kommentarstimmen | bleibt | Absatz und Vorschlag sind getrennte Root-Ressourcen. Absatz-Zähler enthält dessen sichtbare Kommentare einschließlich Antworten, keine Vorschlagskommentare. |
| Core-Moderation, Suchindex, Action Logs, PaperTrail | bleibt | Verborgene Vorschläge/Kommentare nicht mitzählen oder über direkte Links offenlegen. PaperTrail-Historie bleibt gespeichert. Auswertung bleibt abgeschaltet. |
| `decidim_textwork_sections`, `_revisions`, `_amendments`, `_supports`, `_document_versions` | bleibt | Alpha2-Tabellen aus [CreateStandaloneTextwork](../db/migrate/20261004190000_create_standalone_textwork.rb); aktuelle Laufzeit verwendet sie nicht. Erhalten, keine Konvertierung oder Löschung in diesem Umbau. |
| Bilddaten / `Decidim::EditorImage`, ActiveStorage | ändert sich | Noch keine Bildverknüpfung in Block. Nachtrag verlangt dauerhaften Bezug auf EditorImage/Anhang und gespeicherten Alt-Text, keine Unterschrift. Bestätigt: eigene Textvariante mit maximal 1600 px längerer Kante ohne Vergrößerung, Original im Zoom. |

Für Absatz-Likes sind bereits Counter-Spalten vorhanden. Eine zusätzliche Migration
wird für Bildverknüpfung und Alternativtext erwartet. E1a wurde am 6. Oktober
2026 vom Nutzer bestätigt: Alle gespeicherten Beiträge prüfen, ohne dauerhaften
Dokumentmarker und ohne Migration dafür. Auch das Zurückziehen des Dokuments ist
bei Beteiligung gesperrt. Zurückgezogene Vorschläge und verborgene oder gelöschte
Kommentare zählen für diese Sperre weiterhin. Zurückgenommene Likes sind nach
der Bestandsregel keine gespeicherte Beteiligung mehr. Fassung 3 stellt klar:
Papierkorb bleibt auch mit Beteiligung erlaubt. Er entfernt die öffentliche
Sichtbarkeit, erhält die Daten und hebt beim Wiederherstellen keine Sperre auf.

## Commands, Services, Jobs und Formulare

| Datei / Teil | Kennzeichnung | Bestand und notwendige Änderung |
| --- | --- | --- |
| `app/commands/decidim/enhanced_textwork/save_suggestion.rb` | ändert sich | Erstellen/Bearbeiten unter Dokument-Lock, Prüfung von Teilnahme, Phase, Absatztyp und Ausgangsfassung; Benachrichtigung bisher an Kapitel-Folgende. Neue Oberfläche und Meldungsschlüssel anbinden, Empfänger auf Dokument umstellen. Servervalidierung für unveränderten Text erhalten. |
| `app/commands/decidim/enhanced_textwork/withdraw_suggestion.rb` | ändert sich | Setzt withdrawn unter Dokument-Lock; prüft bisher nur Autor-/Statusregel, keine Vorschlags-Phasensperre. Direkten Aufruf nach Sperre verhindern. |
| `app/services/decidim/enhanced_textwork/edit_document.rb`: add/update/remove/move | ändert sich | Gemeinsame Transaktionen, Fassungen, Strukturverlauf, Benachrichtigungen. Veröffentlichte bzw. nach Rückzug weiterhin geschützte Dokumente serverseitig sperren. Bildimport ergänzen; interne Vorbereitungsfassungen bleiben nach Nachtrag erhalten. |
| `edit_document.rb`: decide, persist_version für Entscheidungen | wird abgeschaltet | Annahme/Ablehnung, stale-Prüfung, angepasste Endfassung bleiben vorhanden. Standardmäßig ausgeschalteten Auswertungsschalter und eigene Berechtigungsprüfung vorsehen. Entfernung mit automatischer Ablehnung ebenfalls bei veröffentlichten Arbeiten unerreichbar. |
| `app/services/decidim/enhanced_textwork/access.rb` | ändert sich | Organisation, Teilnahmeberechtigung und ActionAuthorizer; Admins auf Organisations-/Verfahrensebene. Um zentrale Bearbeitungs-/Auswertungsregeln ergänzen, keine alleinige UI-Sperre. |
| `app/services/decidim/enhanced_textwork/document_input.rb` | ändert sich | Editor-HTML separat; Dateiimport liest Markdown, DOCX, ODT, ohne Bilder/Office-Layout. Grenze 2 MiB für Datei, 5 MiB für XML, keine externen XML-Entitäten. Datei-Bilder laut Nachtrag weiterhin auslassen, ggf. Hinweis; keine fremden Bildadressen abrufen. |
| `app/services/decidim/enhanced_textwork/markdown.rb` | ändert sich | Sichere Markdown-Ausgabe für Absätze/Listen/Fettdruck/Kursiv/Links. HTML-Import zerlegt oberste Knoten, lässt Bilder derzeit weg. Für Bilder mitten im Absatz oder in Listen strukturell erweitern. Textausgabe weiter sanitizen. |
| `app/services/decidim/enhanced_textwork/reading_export.rb` | ändert sich | Einsprachiger Bericht mit Text, Autoren und sichtbaren Kommentaren. Bisher Likes nur an Dokument/Überschrift; Vorschlagsdatum und Likes fehlen. Absatz-/Vorschlagszustimmung, Datum und Sortierung ergänzen; Bildplatzhalter ist mit vorhandenem Writer machbar. |
| `lib/decidim/enhanced_textwork/word_document.rb` | bleibt | Schreibt Text und einfache Überschriften als DOCX. Kein echter Bildexport vorgesehen; Platzhalter mit Alternativtext an Bildposition. |
| `app/services/decidim/enhanced_textwork/notifications.rb` | bleibt | Deduplizierung, Ausschluss des Akteurs, Versand erst nach äußerer Transaktion. |
| `app/jobs/decidim/enhanced_textwork/translation_job.rb` | bleibt | Anbindung an konfigurierten Core-Übersetzungsdienst, Retry, keine externen Übersetzungsaufrufe im lokalen Test. |
| `app/forms/decidim/enhanced_textwork/admin/import_form.rb` | ändert sich | Eine Arbeit je Komponente, Pflichtfelder, Originalsprache, Datei oder Editorinhalt. Bildhaltiger Inhalt muss auch ohne Text fachlich geprüft werden. Core-Alt-Feld beim Upload; Nachtrag ergänzt vor Veröffentlichung das Nachtragen am importierten Block, keine Bildunterschrift. |
| `app/services/decidim/enhanced_textwork/diff_renderer.rb` | wird abgeschaltet | Core-PaperTrail-Vergleich für Versionsansichten erhalten, nicht für neue Teilnehmerkarten verwenden. |

## Controller, Berechtigungen und Routen

Controllerpfade relativ zu `app/controllers/decidim/enhanced_textwork/`.
Routen sind in [Engine](../lib/decidim/enhanced_textwork/engine.rb) und
[AdminEngine](../lib/decidim/enhanced_textwork/admin_engine.rb) definiert.

| Datei / Route | Kennzeichnung | Folge |
| --- | --- | --- |
| `application_controller.rb` | bleibt | Komponenten-Kontext, veröffentlichte Dokumente, 403 bei ActionForbidden. |
| `documents_controller.rb`: index/show/panel | ändert sich | Einstieg und Fragmentladen bleiben. Seite lädt Blöcke und pending-Zahlen gesammelt. Panel derzeit Modus comments/suggestions/edit. Künftig gemeinsame Liste und Überblick; Bild/Überschrift als Query ohne Fehler ignorieren. Likes, Kapitel-/Überblickszähler vorladen. Gleichstand künftig ältere zuerst, derzeit neuere zuerst. |
| `documents_controller.rb`: history / `GET documents/:id/history` | wird abgeschaltet | Verlaufscode/Ansicht erhalten; direkte öffentliche Aufrufe sperren, nicht nur Link entfernen. |
| `blocks_controller.rb` / `GET blocks/:id`, index | ändert sich | Stabile Ressourcenadressen bleiben; Nicht-Absätze müssen auf unveränderte Startansicht führen. |
| `suggestions_controller.rb` / show/index/create/update/withdraw | ändert sich | Stabile Detailadressen und Schreibendpunkte bleiben. Neue Rückkehr zur Liste nach Einreichen, Phasen-/Autorenregeln, Meldungsschlüssel. |
| `interactions_controller.rb` / POST und DELETE interactions | ändert sich | Eigene eindeutige Oberfläche, Core Like-/Follow-Commands, Dokument-Lock. Absatz statt Kapitel, Folgen nur Dokument, keine eigene Vorschlagszustimmung, gesperrte Aktionen auch direkt abweisen. Allgemeine Core-Endpunkte zusätzlich berücksichtigen, siehe Erkundung 2. |
| `versions_controller.rb` / GET blocks/:block_id/versions und Detail | wird abgeschaltet | Core-Versionen erhalten, öffentliche Endpunkte in Sammelphase sperren. |
| `admin/application_controller.rb` | ändert sich | Bisher pauschal `manage :textwork`; einzelne Bearbeitungs-/Auswertungsaktionen brauchen zusätzliche Regeln. |
| `admin/documents_controller.rb`: show/create/export/restore | ändert sich | Verwaltung/Import/Export bleiben; alte Entscheidungen aus Navigation nehmen, Bilder integrieren. Restore darf Bearbeitungssperre nicht umgehen. |
| `admin/documents_controller.rb`: publish/update/add/edit_block/update_block/remove/move/trash | ändert sich | Bisher Veröffentlichung umschaltbar, Metadaten/Text/Struktur auch veröffentlicht editierbar. Schutz zentral und unter Lock umsetzen; Titel/Beschreibung sperren, Übersetzungen weiter erlauben. Beteiligung sperrt Rückzug; Papierkorb bleibt unabhängig von Beteiligung erlaubt und erhält alle Rückmeldungen. |
| `admin/documents_controller.rb`: suggestion/decide und zugehörige GET/PATCH-Routen | wird abgeschaltet | Entscheidungscode erhalten, Zugriff über ausgeschalteten Auswertungsschalter verwehren. |
| `app/permissions/decidim/enhanced_textwork/permissions.rb` | ändert sich | Bisher nur Admin-manage für Subject textwork. Keine granularen Auswertungsregeln; Core-Subjects like/follow benötigen Prüfung mit Ressourcentyp und Autor. Nachtrag verlangt zentrale Datumssperre auch für Core-Schreibwege. Follow-/Comments-Controller binden die Komponenten-Permissions nicht automatisch ein, siehe Nachtrag in der Erkundung. |

## Ansichten, Cells und Presenter

Ansichtspfade relativ zu `app/views/decidim/enhanced_textwork/`.

| Datei / Teil | Kennzeichnung | Folge |
| --- | --- | --- |
| `documents/show.html.erb` | ändert sich | Titel, Text und tiefe Links bleiben; feste Zweispaltenfläche, Frist, Dokument-Folgen, aufklappbares Inhaltsverzeichnis mit Zählern, eine Absatz-Pille und neue Bildzeile. |
| show: Kapitelaktionen, zwei Absatzaktionen, Inline-Editor-/Vorschauhosts, Hilfe über Desktoptext, Verlaufslink | entfällt | Nur neue Bedienung ausgeben; Absatznummer aus Tab-Reihenfolge nehmen. |
| `documents/_panel.html.erb` | ändert sich | Fester Kopf/scrollender Inhalt/Fuß bleiben als Grundlage. Reiter, Fassungszeile, Menü, Sortierung, abgeschlossene Liste entfallen. Überblick und drei Handlungen ergänzen; Liste enthält Vorschläge und einen Core-Kommentarbereich. |
| `documents/_editor.html.erb` | ändert sich | Textfeld, Begründung, Listenhinweis, Validierung und Entwurfsschutz bleiben. Eingabe ausschließlich im Panel; neue Labels, Vorschau und Fokus. Hinweis auf vorhandene Vorschläge entfällt. |
| `documents/_suggestion.html.erb` | ändert sich | Neue Kopfzeile mit Avatar/Autor/Datum/Eigenmarke, Begründung und Kommentarlink; keine Status-/Versionsmarken oder Textvorschauaktionen. Nur erste drei pending-Karten initial sichtbar. |
| `documents/_suggestion_detail.html.erb` | ändert sich | Vergleich künftig auch am Desktop im Detail rechts; Absatzkopf behalten, Aktionsreihe dort ausblenden. Zusätzliche Modul-Kommentarüberschrift entfernen. |
| `documents/_suggestion_diff.html.erb` | ändert sich | Gleicher Browservergleich für Karte/Detail/Formular, Original und Ersatz am jeweiligen Element. Ohne JS derzeit leer im Originalmodus; künftig Textfallback Bisher/Vorschlag. |
| `documents/_suggestion_meta.html.erb` | ändert sich | Autor/Datum bleiben, Status-/Ausgangsversionszeile entfällt. |
| `documents/_suggestion_actions.html.erb` | ändert sich | Bearbeiten/Zurückziehen bleiben mit Phasensperren; Darstellung in Kartenfuß. |
| `documents/_suggestion_previews.html.erb` | entfällt | Inerte Quellen für Dokumentvorschau und Blättern gehören nur zur alten Bedienung. Neue Diff-Daten direkt an Karten/Detail. |
| `documents/_interactions.html.erb` | ändert sich | Core-Daten/Commands weiter nutzen; neue Absatz-/Vorschlagsaktionen, eigene Zustimmung nur als Zahl, Dokument-Folgen separat. Gesperrte Aktionen ausblenden statt disabled anzeigen. |
| `documents/_unavailable.html.erb` | ändert sich | Moderation/ungültige Ressourcen sicher behandeln; öffentlicher Verlaufslink entfällt. |
| `documents/empty.html.erb` | bleibt | Leerer Veröffentlichungszustand. Übersetzungsschlüssel beim Umbau erhalten. |
| `documents/history.html.erb`, `versions/index.html.erb`, `versions/show.html.erb` | wird abgeschaltet | Für Auswertung/Archiv erhalten, in Sammelphase nicht öffentlich ausliefern. |
| `admin/documents/show.html.erb` | ändert sich | Importeditor derzeit basic ohne Bildwerkzeug; Entscheidungen und editierbare veröffentlichte Texte ausblenden. Vorbereitung und Export bleiben. |
| `admin/documents/edit_block.html.erb` | ändert sich | Vorbereitungsbearbeitung und Übersetzungsprüfung; Zugriff entsprechend Sperre trennen. |
| `admin/documents/suggestion.html.erb` | wird abgeschaltet | Entscheidungsvorlage für später behalten. |
| `app/cells/decidim/enhanced_textwork/document_cell.rb` | bleibt | Such-/Ressourcenkarte auf Core CardLCell. |
| `app/presenters/decidim/enhanced_textwork/text_presenter.rb` | bleibt | Titel/Text und Sprachauswahl für Ressourcen. Modell-Titel benötigen beim Locale-Umbau weiterhin Schlüssel. |
| `app/presenters/decidim/enhanced_textwork/admin_log/document_presenter.rb`, `suggestion_presenter.rb` | bleibt | Protokolltexte behalten, einschließlich bisheriger Entscheidungen. |
| `app/helpers/decidim/enhanced_textwork/reading_helper.rb` | ändert sich | Übersetzungen, Ressourcenkeys/-pfade und `tw` bleiben; neue verschachtelte Schlüssel. Admin-Diffy-Vergleich bleibt abgeschaltet erhalten und ist keine zweite aktive Teilnehmer-Diff-Implementierung. |

## Skripte, Styles und Konfiguration

| Datei / Teil | Kennzeichnung | Folge |
| --- | --- | --- |
| `app/packs/src/decidim/textwork/controller.js` | ändert sich | Verantwortlich für AJAX, URL/Browserhistorie, Entwürfe, Likes/Folgen, Fokus und Kommentar-Lifecycle. Überblick, gleichbleibende Spalten, Livezähler, Fristzustand, Dialogebenen und Bilder ergänzen. Voriger Inhalt beim Laden erhalten. |
| controller: `showPreview`, `previewSource`, `previewControls`, `preview`, Inline-Editor-Verschiebung, Vorschlagssortierung | entfällt | Links steht künftig ausschließlich der gültige Text. |
| controller: URL, race cancellation, ausstehende Kommentarübermittlung, Entwurfsschutz, Login-Dialog | ändert sich | Mechanismen erhalten, neue Zustände anbinden. Mobil verhindert `paragraph()` derzeit explizit Textklick; diese Sperre entfernen. Escape schließt bisher das ganze Panel statt eine Ebene. |
| `app/packs/src/decidim/textwork/diff.mjs` | ändert sich | Verlustfreier Tokenvergleich einschließlich Satzzeichen und Laufzeitgrenze bleibt Grundlage. Nur Darstellung ergänzen: gruppierte Änderungen, großer Umbau, kurze Absätze vollständig, Langtext-Kontext; CRLF vor Vergleich normalisieren, gespeicherten Text unverändert lassen. |
| `app/packs/src/decidim/textwork/panel_comments.js` | bleibt | Lokaler Core-Adapter beendet alte GETs und begrenzt Sortierhandler auf die aktuelle Ressource. Kein globaler Patch. |
| `app/packs/stylesheets/decidim/enhanced_textwork.scss` | ändert sich | Core-Tokens, Fokus, Lesetext und bestehender Kommentar-Kontrastfix erhalten. Permanente rechte Spalte, Container-Abfrage, Übersicht/Bilder ergänzen; alte Tabs/Vorschau-/Editorlayouts entfernen. |
| `app/packs/entrypoints/decidim_enhanced_textwork.js`, `config/assets.rb` | bleibt | Registrierung des Stimulus-Controllers und Asset-Packs. |
| `config/locales/redesign.de.yml`, `redesign.en.yml` | ändert sich | Enthalten Frontend, Admin, Fehler, Verlauf und Events gemeinsam. Neues Paket ersetzt nur Sammel-Frontend, nicht Admin/Events. Aktive gemeinsame Fehler-/Fallbacktexte fehlen teilweise im Paket und müssen übernommen werden. |
| `config/locales/component.de.yml`, `component.en.yml`, `de.yml`, `en.yml` | ändert sich | Komponenten-/Phasentexte und Importformular bleiben; neue Schlüssel mit vorhandenen zusammenführen. Bereinigung nach Verbrauch, keine pauschale Dateilöschung. |
| `lib/decidim/enhanced_textwork/component.rb` | ändert sich | Core-Aktionen like/suggest/comment/vote_comment; globale Kommentare/Likes, drei Phasensperren, drei Ressourcen. Neuer Auswertungsschalter fehlt. Core erwartet likes_enabled in Phaseneinstellungen, Modul hat es bisher nur global. |
| `lib/decidim/enhanced_textwork.rb`, `version.rb` | bleibt | Gemname/Namespace/Unabhängigkeit und Zielversion. Kein Versionssprung in Schritt 0. |
| `lib/decidim/enhanced_textwork/engine.rb`, `admin_engine.rb` | ändert sich | Routen erhalten oder sicher abschalten; Ressourcenadressen und Icons weiterverwenden. |
| `app/events/decidim/enhanced_textwork/change_event.rb`: suggestion_created | ändert sich | Gleiches Ereignis, Empfänger auf Dokument-Folgende umstellen. Core-Kommentarevents weiter über Modellhook. |
| change_event: suggestion_accepted/rejected, editorial_change, structure_changed | wird abgeschaltet | Ereigniscode und Übersetzungen für Auswertung erhalten; keine neuen Auswertungsereignisse während Sammelphase. |
| `lib/decidim/enhanced_textwork/legacy_inventory.rb`, `lib/tasks/legacy.rake`, `bin/textwork-inventory` | bleibt | Nur lesende Altbestandsaufnahme, keine Altdatenmigration. |
| `bin/test-setup`, `bin/check-independence`, `.github/workflows/test.yml`, `package.json`, Gem-/Runtime-Dateien | bleibt | Bestehende Testwerkzeuge/CI; neue fachliche Tests in folgenden Schritten ergänzen. |

## Tests und vorhandene Nachweise

| Datei | Kennzeichnung | Bestehende Abdeckung / Umbau |
| --- | --- | --- |
| `spec/redesign/domain_spec.rb` | ändert sich | Nummern/stabile IDs, Fassungen, Annahme, Entfernung, Übersetzungen, Erstfeedback, Markdown. Sammelregeln ergänzen; Entscheidungstests ausdrücklich für aktivierte spätere Auswertung erhalten. |
| `spec/redesign/requests_spec.rb` | ändert sich | Kapitel-Likes/-Folgen, Schreiben/Phasen, Moderation, Verlauf, Admins, Import/Restore. Auf neue Regeln umstellen, abgeschaltete Endpunkte und generische Core-Likes mitprüfen. |
| `spec/redesign/browser_spec.rb` | ändert sich | 12 Browserabläufe für Kommentare, Inline-Vorschlag, Vorschau, Mobil/Fokus, Race, Kontrast und axe. Alte Bedienannahmen ersetzen, neue Mockupzustände und Tastaturfolge prüfen. |
| `spec/redesign/notifications_spec.rb` | ändert sich | Kapitel-Folgende sowie Auswertungsereignisse. Dokumentempfänger und abgeschaltete Auswertung prüfen; bestehende Auswertungsnachweise erhalten. |
| `spec/redesign/files_spec.rb` | ändert sich | Word-Liste, sichere XML-Eingabe, einsprachiger Export. Bilder und Exportzahlen/-datum/-reihenfolge ergänzen. |
| `spec/redesign/translation_spec.rb` | bleibt | Deduplizierung, manuelle Priorität, alte/verspätete Ergebnisse, Wiederverwendung. |
| `spec/services/decidim/enhanced_textwork/document_input_spec.rb` | ändert sich | Markdown/ODT, falsche/zu große Dateien. Datei-Bilder auslassen; Editorbilder separat mit Dauerbezug, Alt-Text und ohne Video testen. |
| `spec/lib/decidim/enhanced_textwork/word_document_spec.rb` | bleibt | DOCX-Struktur/XML/Unicode, keine externen Ressourcenabrufe. |
| `spec/lib/decidim/enhanced_textwork/legacy_inventory_spec.rb` | bleibt | Altbestände ohne Inhalte/Personendaten auszugeben oder umzuschreiben. |
| `spec/javascript/diff_test.mjs` | ändert sich | Rekonstruktion inkl. Satzzeichen/Zeilen und langem Text; Kurzkontext ohne Verlust. Neun Beispiele der Fassung 2 nach ihrer Muss-gelten-Regel ergänzen, bisherige Laufzeitgrenze nicht verlieren. |
| `spec/spec_helper.rb`, `spec/support/factories.rb` | ändert sich | Isolierte App/Testdatenbank, Transaktionen, keine externen Jobs. Bild-/gesperrte-/Auswertungs-Fixtures bei Bedarf ergänzen. |

## Zuordnung für die nächsten Schritte

| Schritt | Bestandseinträge, auf die die Umsetzung verweisen soll |
| --- | --- |
| 1 Abschalten/Sperren | Document, EditDocument, Access, Permissions, Admin-Controller/-Ansichten, Versions-/History-Endpunkte, component.rb. |
| 2 Zustimmung/Zähler | Block, Suggestion, InteractionsController, Permissions, Core-Likes, DocumentsController, Request-/Querytests. |
| 3 Seite/Zeilen | Document/Folgen/Benachrichtigungen, show, ReadingHelper, Controller-JS, Styles, Frontend-Locales. |
| 4 Leiste/Überblick | show/panel und neue Überblicksansicht, gesammelte Absatzdaten, Controller-JS, Styles. |
| 5 Absatz/Liste | panel, suggestion/meta/actions/interactions, DocumentsController, Core-Kommentar-Lifecycle. |
| 6 Wortvergleich | diff.mjs, suggestion_diff, Datenattribute in Karte/Detail, JavaScript-Tests. |
| 7 Formular | editor, SaveSuggestion, Suggestion.normalize, Controller-JS, Entwurfsschutz-/Browsertests. |
| 8 Detail/Kommentare | suggestion_detail, panel_comments.js, ReadingHelper/Core-Kommentare, lokale Styles. |
| 9 Bilder | Block/Document, ImportForm/Admineditor, Markdown/DocumentInput, additive Migration, Anzeige/Dialog, Import-/Browsertests. |
| 10 Fokus | Controller-JS, Panel-/Bild-/Bestätigungsdialoge, ein Absatz-Tabstopp, Browsertests. |
| 11 Phasensperren | Zentrale Handlungssperre aus Schaltern plus aktiver Phasenfrist; Suggestion, WithdrawSuggestion, InteractionsController, Core-Kommentare/Rechte, Overview und UI-Aktionen. Zeitzone/Tageswechsel und Wiederöffnung testen. Folgen/Entfolgen, Löschen eigener Kommentare und Melden bleiben von Frist und Schaltern unabhängig möglich; allgemeine Zugriffs-/Autorenregeln gelten weiter. |
| 12 Export | ReadingExport, WordDocument bei tatsächlichem Bedarf, Export-Locales, files_spec. |
| 13 Bereinigung | Nur alte Bedienung entfernen; deaktivierte Auswertung erhalten; Locale-Verbrauch und diese Liste nachführen. |

## Prüfung von Schritt 0

Am 6. Oktober 2026 bestanden `bundle exec rspec spec` mit **54 Beispielen,
0 Fehlern**, darunter 12 Browserabläufe, außerdem `npm test` und
`bin/check-independence`. RSpec-Seed: `64668`.

Drei temporäre Testproben mit zurückgerollten Fixtures bestätigten die
Core-Like-Inkompatibilität, die bisher erlaubte eigene Vorschlagszustimmung und
die Bildkonfiguration sowie die Unterschiede zwischen Source-Checkout und
installierten Gems. Sie bestehen mit den dokumentierten Erwartungen, bestätigen
also den aktuellen Bestand, nicht die Erfüllung der neuen Regeln. Die sieben
Beispiele der gelieferten Wortvergleichsreferenz wurden separat erfolgreich
nachgerechnet. Befunde und Grenzen stehen in der Erkundung.

Geändert wurden in Schritt 0 ausschließlich `docs/BESTAND.md` und
`docs/ERKUNDUNG.md`. Kein neuer Branch, keine Anwendungsmigration, kein Asset-Build,
keine Änderung der Entwicklungsdaten, keine Umsetzung von Schritt 1.

Nach Eingang der Fassung 2 wurden am selben Tag nur diese Bestandsdokumentation
und die Erkundung nachgeführt. Die oben genannten Tests bleiben der Nachweis des
Ausgangsstands, keine Abnahme des aktualisierten Auftrags. Die neue Referenz wurde
gezielt auf Satzzeichen, CRLF, Leerzeichen und großen Umbau geprüft; sie ersetzt
ausdrücklich nicht `diff.mjs`.

## Umsetzung von Schritt 1

Am 6. Oktober 2026 auf demselben Branch umgesetzt, nach Fassung 3:

| Betroffene Dateien aus dem Bestand | Umsetzung |
| --- | --- |
| `Document`, `Access`, `Permissions`, `component.rb` | `evaluation_enabled` standardmäßig false; zentrale Prüfung gespeicherter Beteiligung. Veröffentlichter Originaltext bleibt gesperrt, auch mit eingeschaltetem Auswertungsschalter. Rückzug nur ohne Beteiligung. |
| `EditDocument`, Admin-Controller/-Ansichten | Originalbearbeitung und Strukturänderungen unter Dokument-Lock gesperrt; Originaltitel/-beschreibung eingeschlossen. Übersetzungsfelder weiter erreichbar. Entscheidungspfade und deren Admin-Navigation standardmäßig gesperrt. Vorbereitungsfassungen und bestehender Entscheidungscode erhalten. |
| `DocumentsController#history`, `VersionsController`, öffentliche Verlaufslinks | Standardmäßig nicht erreichbar bzw. ausgeblendet; Routen, Ansichten und gespeicherte Fassungen für spätere Auswertung erhalten. |
| `Document`, Admin-Papierkorb/Restore | Papierkorb auch mit Beteiligung erlaubt. Soft-Delete als Update erhält Core-Likes, statt ihre Destroy-Callbacks auszuführen. Wiederherstellen erhält Veröffentlichung und Schutzprüfung. |
| `Block`, `Suggestion`, neue `CommentVisibility`, `Engine` | Textwork-Kommentarbereiche und direkte Core-Aufrufe berücksichtigen Sichtbarkeit des Dokuments. Zugehörige Kommentare verlieren beim Papierkorb ihre Suchtreffer und werden beim Wiederherstellen passend neu indexiert. Ergänzung betrifft nur Textwork-Wurzeln. |
| DE-/EN-Component-Locales, README | Sperrhinweise, Übersetzungsbearbeitung und Einstellungsschalter beschrieben; neue Texte mit bestehenden Schlüsseln zusammengeführt. |
| `spec/redesign/*`, neue `collection_lock_spec.rb` | 21 zusätzliche Prüfungen für Schritt 1. Vorbereitungsfixtures vor Veröffentlichung aufgebaut; historische Fälle bleiben als ausdrücklich gekennzeichnete Regressionstests erhalten. |

Die bestehende Suite umfasst jetzt **75 Beispiele, 0 Fehler**, Seed `25141`,
47,65 s plus 2,06 s Laden. Darunter bleiben die 12 Browserabläufe der bisherigen
Sammeloberfläche. RuboCop: **64 Dateien, keine Verstöße**. `npm test`,
`bin/check-independence` und `git diff --check` bestanden.

Keine Datenbankmigration, kein neuer Branch und kein Assetquelltext geändert.
Die Test-App auf Port 3033 wurde neu gestartet; keine Seeds, kein Datenbankreset.
Schritt 2 und die späteren Oberflächen-/Friständerungen wurden nicht vorgezogen.
Weitere Befunde und Grenzen stehen im Abschnitt Schritt 1 der Erkundung.

## Nachführung: Schritte 2–13

Der Umbau bleibt auf `feature/textwork-redesign` im vorhandenen Gem. Die neue
Oberfläche ersetzt die bisherige vollständig. Neu sind `Participation`, die auf
Textwork begrenzten Core-Berechtigungs-/Command-/Cell-Ergänzungen,
`DocumentStats`, `EditorDocumentInput`, Überblick/Zähler/Bildansichten und die
additive Bild-Migration. Details, Karten und Formular nutzen denselben vorhandenen
Tokenvergleich mit neuer Darstellung. Kapitel-Likes und Kapitel-Follows sind in
der Bedienung abgeschaltet; vorhandene Datensätze werden nicht gelöscht.

Entfernt wurden die Inline-Vorschau- und Fassungszeilen-Partials sowie die alten
Teilnahmebedienelemente und ihre Texte. Die Modelle, Commands, Ereignisse,
Routen, Ansichten und Texte der späteren Auswertung bleiben geschützt erhalten.
Die bestätigte Fassung 3 wurde unverändert in `AENDERUNGEN_ZUM_UMBAUAUFTRAG.md`
gesichert. Abnahme und Prüfnachweise: `SAMMELPHASE-IMPLEMENTATION.md`.
