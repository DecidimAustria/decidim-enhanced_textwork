# Erkundung für das Textwork-Redesign

Die folgenden Befunde beschreiben den bisherigen Redesign-Stand vom 5. Oktober.
Für den neuen Auftrag stehen die ergänzten Befunde und noch offenen Entscheidungen
im Abschnitt [Umbau zur Sammelphase, Schritt 0](#umbau-zur-sammelphase-schritt-0).
Frühere Entscheidungen über Kapitelzustimmung und Auswertung sind damit keine
Vorgabe für die neue Sammeloberfläche.
Der [Nachtrag zum Umbauauftrag](#nachtrag-zum-umbauauftrag) führt die anschließend
eingegangenen Antworten und die überarbeiteten Referenzen nach. Die Befunde aus
Schritt 0 bleiben als Ausgangsnachweis erhalten; überholte Empfehlungen sind dort
ausdrücklich abgelöst.

Geprüft am 5. Oktober 2026 gegen den lokalen offiziellen Decidim-Checkout,
Version 0.32.1, Zweig `release/0.32-stable`. Fundstellen sind relativ zu diesem
Checkout. Quellcodeprüfung allein bestätigt noch keinen funktionierenden Ablauf;
die Integrationsprüfungen stehen im Umsetzungsplan.

| Frage | Befund und Fundstelle | Folge |
| --- | --- | --- |
| Zähler | `decidim-comments/lib/decidim/comments/commentable.rb`: `comments_count`; `decidim-core/lib/decidim/likeable.rb` und `followable.rb`: `likes_count`, `follows_count`. | Alle drei sind nicht-null Integer mit Standard 0. Kommentare nutzen zusätzlich `CommentableWithComponent` für Phasen und Berechtigungen. |
| Kommentarstimmen | `Commentable#comments_have_votes?` aktiviert die Stimmen des Kommentar-Moduls gemeinsam. | Zustimmung und Ablehnung unverändert anzeigen. |
| Nachgeladene Kommentare | `decidim-comments/app/packs/src/decidim/comments/comments.js` exportiert `window.Decidim.CommentsComponent`. Die Klasse in `comments.component.js` hat `mountComponent` und `unmountComponent`; automatischer Start nur bei `turbo:load`. | Vor Fragmentwechsel unmounten, danach genau eine neue Instanz am neuen Container mounten. Überholte Fragmentantworten verwerfen; nicht global `turbo:load` auslösen. |
| Like- und Follow-Cells | `decidim-core/app/cells/decidim/like_buttons_cell.rb`, `like_block_cell.rb`, `follow_button_cell.rb` und die zugehörigen Ansichten verwenden feste bzw. nur numerische IDs. Die AJAX-Antwort der Likes ersetzt per `getElementById` nur einzelne Elemente. | Vom Nutzer bestätigte Abweichung: eigene kleine Oberfläche und Antwort, Core-Modelle und Like-Commands bleiben. IDs enthalten Ressourcentyp und ID; alle sichtbaren Vorkommen werden synchronisiert. Auch Folgen benötigt eindeutige Bedienelemente. |
| Übersetzungsjobs | `decidim-core/app/jobs/decidim/machine_translation_fields_job.rb` instanziiert den konfigurierten Dienst. `machine_translation_save_job.rb` schreibt unter Lock mit `update_column`, ohne Originalfassungsprüfung. Der AWS-Dienst in `decidim-module-amazon_translate/lib/decidim/amazon_translate.rb` nutzt denselben Speicherjob. | Eager `TranslatableResource` nicht einbinden. Eigene dauerhafte Auftragsidentität pro Ressource, Feld, Zielsprache und Originaldigest; verspätete Ergebnisse dürfen neue Originale nicht überschreiben. Lokale Tests dürfen keinen kostenpflichtigen Dienst aufrufen. |
| Diff | `decidim-core/app/cells/decidim/diff_cell.rb` sucht eine ressourcenspezifische `*DiffRenderer`-Klasse und fällt auf den Basisrenderer zurück. | Core-Cells für Traceable-Verlauf; eigener Live-Vergleich für Absatzvorschläge. Satzzeichen und Zeilenumbrüche nicht wie im Mockup ignorieren. |
| Traceable | `decidim-core/lib/decidim/traceable.rb` aktiviert PaperTrail für create/update/destroy. | PaperTrail-Attribute auf Textfelder beschränken. Zähler und Position erzeugen keine Textfassung. Eigene unveränderliche BlockVersion zählt ausschließlich Originaländerungen. |
| Markdown | Das Modul hat bereits Kramdown 2.5 als explizite Abhängigkeit; Core bietet mit `Decidim::ContentProcessor.sanitize` eine allgemeine Inhaltsbereinigung, aber keinen Vertrag für die gewünschte Markdown-Teilmenge. | Kramdown explizit behalten, Ausgabe auf Absätze, Listen, Hervorhebung und sichere Links begrenzen. Kein beliebiges HTML übernehmen. |
| Aktionsrechte | `decidim-debates/lib/decidim/debates/component.rb`: `component.actions` und Ressourcenaktionen; `decidim-core/app/permissions/decidim/permissions.rb`: ActionAuthorizer und Like-Phasenschalter. | Eigene Aktionen anmelden, Komponenten- und Ressourcenrechte, Teilnahmeberechtigung und Phasensperren an jedem Schreib-Endpunkt prüfen. |
| Kommentarevents | `decidim-comments/app/services/decidim/comments/new_comment_notification_creator.rb`: Erwähnte, Elternkommentarautor, Autor-Folgende, `users_to_notify_on_comment_created`; Empfänger werden dedupliziert und der Autor ausgeschlossen. | Kapitel-Folgende und ggf. Vorschlagsautor über diesen Hook liefern; kein zweites Kommentarevent erzeugen. |
| Lizenz | `decidim-core/decidim-core.gemspec`: AGPL-3.0-or-later. | SPDX-Angabe des Gems angleichen. |
| Ressourcenadressen | Ressourcenregistrierung in Komponentenmanifesten und `Decidim::ResourceLocatorPresenter` verwenden Modell und gleichnamige Routen. | Document, Block und Suggestion registrieren; Block/Suggestion-Routen leiten auf Dokument mit stabilen IDs in Queryparametern. |
| Mehrere Kommentarressourcen | Instanzen verwenden eigene Root-Container; einzelne Unterfunktionen verwenden dokumentweite Kommentar-IDs. | Im Panel immer nur eine Kommentarressource gleichzeitig montieren. Wiederholte Wechsel, Vorschlagskommentare und späte Antworten explizit testen. |
| Verborgene Vorschläge | `decidim-core/lib/decidim/reportable.rb`: `not_hidden` über Moderation, `hidden?`; Melden allein verbirgt noch nichts. | Alle öffentlichen Vorschlagslisten und Zählungen verwenden `not_hidden`, schließen withdrawn aus. Direkte Links verraten verborgenen Inhalt nicht. |

## Bestätigte Entscheidungen gegenüber der Übergabe

- Neuer Branch im bestehenden Gem. Der installierte Gemname und der bestehende
  Namensraum `Decidim::EnhancedTextwork` bleiben; neue Fachmodelle heißen Block,
  BlockVersion, Suggestion und DocumentRevision. Kein zweites Plugin erforderlich.
- Kapitelzustimmung gilt dauerhaft, unabhängig von Textfassungen. Alte
  revisionsbezogene Supports werden nicht als Kapitelzustimmung umgedeutet.
- Veraltete Vorschläge bleiben nach redaktioneller Prüfung annehmbar; der beim
  Öffnen des Adminformulars gelesene Versionsstand schützt vor konkurrierenden Änderungen.
- Manuelle Übersetzungen bleiben nach Originaländerungen als veraltet erhalten.
  Sie werden erst nach Prüfung wieder als aktuelle Übersetzung angezeigt.
- Entfernen ist Soft-Delete. Offene Vorschläge werden begründet abgelehnt;
  Kommentare, Vorschläge, Versionen und bisherige Zustimmungen bleiben gespeichert.
- Umsetzung umfasst alle Bauschritte, nicht nur die Präsentationsstufe 1–6.
- Alpha2 bleibt im ursprünglichen Checkout unter Port 3032 erhalten. Das Redesign
  wird getrennt unter Port 3033 und mit eigener Datenbank geprüft.

## Befund aus den Browserprüfungen

Der Core-Kommentarcode hat zwei zusätzliche Integrationsgrenzen: `unmountComponent`
beendet seine laufende GET-Abfrage nicht; die Sortierhandler suchen dokumentweit.
`panel_comments.js` kapselt deshalb diese beiden Methoden in einer nur im
Textwork-Panel erzeugten Unterklasse. Core-Klassen, globale Prototypen, Ansichten,
Formulare und Schreib-Endpunkte bleiben unverändert. Die kleine Anbindung muss
bei Decidim-Upgrades mit den Browsertests geprüft werden. Vor einem Panelwechsel
wartet Textwork außerdem laufende Formularübermittlungen ab; ein bereits
abgeschickter Kommentar wird nicht abgebrochen.

`Block#depth` aus der Übergabe kollidiert mit der Kommentartiefe: Core Comments
prüft `respond_to?(:depth)` und behandelt solche Ressourcen wie Elternkommentare.
Die Kapitelgliederung heißt deshalb `heading_depth`. Absätze bekommen dadurch
reguläre Root-Kommentare mit Tiefe 0; die Core-Benachrichtigung verwechselt den
Absatz nicht mit einem Kommentarautor. Dies ist eine technische Feldumbenennung,
keine Änderung der fachlichen Gliederung.

## Umbau zur Sammelphase, Schritt 0

Geprüft am 6. Oktober 2026. Modulstand `f3421d1`, Branch
`feature/textwork-redesign`, Version `2.0.0.alpha3`. Nach ausdrücklicher Anweisung
des Nutzers wird kein neuer Branch erstellt. Bestandszuordnung und Folgearbeiten
stehen in [BESTAND.md](BESTAND.md).

Grundlage: [UMBAUAUFTRAG.md](../../../decidim-enhanced_textwork/textwork-umbau/docs/UMBAUAUFTRAG.md),
Abschnitt 7, Schritt 0. Die neuen Regeln ersetzen die früheren Entscheidungen
nur für die angesprochenen Funktionen. Es wurde kein Anwendungscode geändert.
Änderungsvorschläge unten sind noch nicht freigegeben und ändern den Auftrag nicht.

### Geprüfte Versionen und Quellen

Die Test-App `decidim-localtest-redesign` lädt offizielle RubyGems-Versionen
`0.32.1` von Core, Admin, Comments und Participatory Processes. Der Modulpfad ist
`.worktrees/textwork-redesign`. Ruby ist `3.4.7`, Node `22.14.0`. Die App nutzt
Port 3033 und die separate Redesign-Testdatenbank, nicht Alpha2 oder Kundendaten.

Der Framework-Checkout `decidim/` steht auf `release/0.32-stable`, Commit
`d514de311b1d3783f63b4fcb614c907180049845`. Die Test-App lädt diesen Checkout
nicht als Gemquelle. Ein SHA-256-Vergleich von 20 für Schritt 0 relevanten Dateien
ergab 16 identische Dateien und vier Unterschiede:

| Datei im Framework | Unterschied des lokalen Branches zur installierten 0.32.1-Version | Bedeutung hier |
| --- | --- | --- |
| `decidim-core/lib/decidim/form_builder.rb` | Ergänzte Aufbereitung von Mention-Optionen. | Bild-Upload-/Toolbar-Optionen sind im gelesenen Abschnitt gleich. |
| `decidim-core/app/uploaders/decidim/application_uploader.rb` | Nicht-ActiveStorage-Fallback gibt nil statt super zurück. | Nicht für die hier betrachteten ActiveStorage-Editorbilder relevant; keine Vermutung über andere Uploadtypen. |
| `decidim-core/app/packs/src/decidim/editor/index.js` | Zusätzlicher Handler `move-cursor-to-end`. | In der Test-App nicht voraussetzen; Textwork-Textarea setzt Auswahl selbst. |
| `decidim-comments/app/packs/src/decidim/comments/comments.component.js` | `_getUID` nutzt `getUTCMilliseconds` statt `setUTCMilliseconds`. | Core-Cell liefert einen eigenen Ressourcencontainer mit ID, sodass dieser Fallback beim regulären Einbau nicht nötig ist. |

Die folgenden Fundstellen beziehen sich auf den Framework-Checkout. Die gleichen
Abschnitte bzw. genannten Unterschiede wurden mit den tatsächlich installierten
Gems verglichen. Das ist ein gezielter Vergleich, kein Vollvergleich des Frameworks.

### 1. Enddatum der aktiven Phase

**Befund:** Bei einem Beteiligungsprozess ist der Zugang
`current_component.participatory_space.active_step&.end_date`.
`ParticipatoryProcess` hat eine `has_one :active_step`-Beziehung auf die ausdrücklich
als aktiv markierte Phase. Das Datum ist optional. Bei einem Beteiligungsraum ohne
Phasen muss der Zugriff über `allows_steps?` bzw. die vorhandene Schnittstelle
abgesichert werden; ohne aktive Phase/Enddatum entfällt die Fristanzeige.

Fundstellen:

- [ParticipatoryProcess](../../../decidim/decidim-participatory_processes/app/models/decidim/participatory_process.rb), `active_step`.
- [ParticipatoryProcessStep](../../../decidim/decidim-participatory_processes/app/models/decidim/participatory_process_step.rb), optionale Datumsvalidierung.
- [HasSettings](../../../decidim/decidim-core/lib/decidim/has_settings.rb), `current_settings`, `active_step_settings`, `default_step_settings`.

**Folge:** Enddatum anzeigen, Schreibrechte über die vorhandenen drei
Phasensperren prüfen. `HasSettings` leitet die aktive Phase nicht aus der Uhrzeit
ab und beendet die Beteiligung nicht automatisch bei Erreichen des Datums.
Eine automatische Sperre wäre eine zusätzliche fachliche Regel, kein vorhandener
Core-Vertrag. Sie ist im Auftrag ausdrücklich nicht vorgesehen. Präzisierung E2.

Prüfung: Quellcode der aktiven Beziehung und Settingsauswahl, keine Änderung einer
Phase in der lokalen Entwicklungsdatenbank und kein Test über einen echten Tageswechsel.

### 2. Core-Likes nur für Absätze

**Befund:** Ja, mit den vorhandenen Core-Daten und Commands. `Block` enthält bereits
`Decidim::Likeable` und `likes_count`; Core speichert polymorphe Ressourcen.
`Block#likeable?` ist eine Regel des Moduls und erlaubt derzeit nur Überschriften.
Der eigene `InteractionsController#toggle_like` prüft sie ausdrücklich. Die
Umstellung auf sichtbare Absätze erfordert keine neue Like-Tabelle und keine
Umdeutung vorhandener Kapitel-Likes.

Fundstellen:

- [Likeable](../../../decidim/decidim-core/lib/decidim/likeable.rb), [Like](../../../decidim/decidim-core/app/models/decidim/like.rb).
- [LikeResource](../../../decidim/decidim-core/app/commands/decidim/like_resource.rb), [UnlikeResource](../../../decidim/decidim-core/app/commands/decidim/unlike_resource.rb).
- [Block](../app/models/decidim/enhanced_textwork/block.rb), [InteractionsController](../app/controllers/decidim/enhanced_textwork/interactions_controller.rb).

**Zusätzlicher Integrationsbefund:** Der allgemeine Core-Endpunkt
`POST /likes` existiert unabhängig von der Textwork-Oberfläche. Seine
[Permissions](../../../decidim/decidim-core/app/permissions/decidim/permissions.rb),
`apply_like_permissions`, erwarten `current_settings.likes_enabled` in den
Phaseneinstellungen. Textwork definiert es bisher nur global. Eine authentifizierte
Testanfrage für einen Absatz wirft deshalb aktuell `NoMethodError: likes_enabled`.
Es entsteht kein Like. Das ist eine unbehandelte Integrationsgrenze, keine saubere
fachliche Ablehnung.

[LikesController](../../../decidim/decidim-core/app/controllers/decidim/likes_controller.rb)
und `LikeResource` prüfen außerdem nicht selbst `Block#likeable?` oder die
Autorengleichheit bei Vorschlägen. Der Core-Like-Datensatz validiert Organisation
und Eindeutigkeit, nicht diese Modulregeln. Sobald die Settingskompatibilität
hergestellt wird, müssen die Modulrechte diese alternativen Schreibwege mit
abdecken. Keine globale Änderung des Core-Controllers vornehmen.

**Eigene Vorschlagszustimmung:** Der aktuelle Textwork-Endpunkt erlaubt sie.
Eine temporäre Requestprobe bestätigt HTTP 200 und einen neuen Like am eigenen
Vorschlag. Neue Regel daher serverseitig und in der Oberfläche ergänzen. Eine
bereits vorhandene eigene Zustimmung darf nicht still gelöscht werden; Umgang
mit solchen Test-/Bestandsdaten gesondert festlegen.

**Zähler:** `Block#comments_count` zählt dessen sichtbare Kommentare inklusive
Antworten anhand der Root-Ressource; Kommentare an `Suggestion` gehören nicht dazu.
Pending-Zahlen werden in `DocumentsController#show` bereits gruppiert geladen.
Für Kapitel/Überblick und Like-Zustand dieselben vorgeladenen Daten nutzen, keine
`pending_suggestions_count`-/`number`-/`liked_by?`-Abfrage je Absatz in einer Schleife.
Der geforderte 100-Absatz-Abfragetest fehlt noch und gehört zu Schritt 2.

Folgen am Dokument ist technisch ebenfalls vorhanden. `Document#followable?`
ist derzeit an die fehlenden Überschriften gekoppelt und muss davon gelöst werden.
Der Core-[FollowForm](../../../decidim/decidim-core/app/forms/decidim/follow_form.rb)
prüft den Modell-Methodennamen `followable?` nicht. Alternative Core-Aufrufe sind
deshalb auch beim Abschalten des Kapitel-Folgens zu berücksichtigen.

### 3. Absatz- und Vorschlagskommentare in derselben Leiste

**Befund:** Nacheinander ja. Der Auftrag beschreibt zwei Ansichten, die sich
ersetzen: Absatzliste mit Absatzkommentaren, danach Vorschlagsdetail mit dessen
Kommentaren. Eine einzige montierte Kommentarressource reicht dafür aus.

Fundstellen:

- [CommentsHelper](../../../decidim/decidim-comments/lib/decidim/comments/comments_helper.rb), `inline_comments_for`.
- [CommentsCell](../../../decidim/decidim-comments/app/cells/decidim/comments/comments_cell.rb), ressourcenspezifische `node_id` und `threads_node_id`.
- [CommentsComponent](../../../decidim/decidim-comments/app/packs/src/decidim/comments/comments.component.js), mount/unmount/GET/Sortierung.
- [Inlineansicht](../../../decidim/decidim-comments/app/cells/decidim/comments/comments/inline.erb) und [Sortieransicht](../../../decidim/decidim-comments/app/cells/decidim/comments/comments/order_control.erb).
- [panel_comments.js](../app/packs/src/decidim/textwork/panel_comments.js), [controller.js](../app/packs/src/decidim/textwork/controller.js), mount/unmount, ausstehende Übermittlungen.

**Grenze:** Core verwendet innen feste IDs wie `comments`, `order` und
`order-mobile`; der originale Sortierhandler sucht dokumentweit. Zwei gleichzeitig
sichtbare Instanzen sind mit unveränderten Core-Ansichten daher keine sichere
Grundlage. Die vorhandene Textwork-Unterklasse begrenzt Handler und bricht alte
GETs ab. Beim Wechsel wird die vorherige Instanz unmountet. Bereits abgeschickte
Kommentare werden vor dem Wechsel abgewartet.

Prüfung: Die bestehenden Browsertests bestätigen Absatzwechsel, einmaliges
Absenden, Browserhistorie, schnelle Wechsel und Vorschlagskommentare bei 390/320 px.
Nicht geprüft in Schritt 0: ein absichtlich gleichzeitiger Einbau zweier
Core-Kommentarbereiche, Antwort-/Bewertungsabläufe in der noch nicht gebauten
gemeinsamen Liste. Letztere werden in Schritt 8 getestet.

Die zusätzliche Modulüberschrift im Vorschlagsdetail ist tatsächlich vorhanden
und muss entfallen. Core liefert die Kommentarüberschrift selbst.

### 4. Kommentarsortierung und Kürzung

**Befund:** In den gelesenen Core-Schnittstellen gibt es keine Option zum
Ausblenden des Sortierfelds nach Kommentarzahl. `CommentsHelper` reicht `order`,
aber keinen Sichtbarkeitsschalter weiter; die Inline-Cell rendert `order_control`
auch bei null Kommentaren. Daher innerhalb des Panels/Sheets eine lokale
Kennzeichnung nach Ressourcen-Kommentarzahl und gezieltes CSS verwenden.
Die Kennzeichnung nach Kommentarübermittlung bzw. Nachladen aktualisieren.

Die im Auftrag erlaubte niedrigere Eingabehöhe kann ebenfalls lokal gestylt
werden. Profilbild, Emoji, Zeichenzähler, Stimmen und Antworten bleiben Core.
Den bestehenden Fix für mobile Formulare und Buttonkontrast erhalten.

Für das Kürzen der Liste: [SortedComments](../../../decidim/decidim-comments/app/queries/decidim/comments/sorted_comments.rb)
bietet limit/offset, der [CommentsController](../../../decidim/decidim-comments/app/controllers/decidim/comments/comments_controller.rb)
nutzt jedoch seinen eigenen Nachladevertrag. Eine Option des Queries ist nicht
automatisch eine Option von `inline_comments_for`. Empfehlung: zunächst Core-
Nachladen unverändert lassen; drei Vorschläge initial zu zeigen ist unabhängig
davon einfach. Eine eigene Kommentar-Paginierung nur für die optionale Kürzung
würde ich nicht bauen. Das entspricht der vorgesehenen Ausweichlösung.

### 5. Bilder im Admin-Editor

**Upload und Werkzeugleiste:** Core 0.32.1 kann Editorbilder hochladen. Im aktuellen
Textwork-Import wird `f.editor :content` ohne Toolbar-Option aufgerufen. Default
ist `basic`, das kein Bildwerkzeug aktiviert. `content` ergänzt Überschriften;
`full` ergänzt Bilder und Video. Der vorhandene Bild-Upload lässt sich mit `full`
aktivieren, damit kommt aber auch Video als Werkzeug hinzu. Nicht still eine
Unterstützung für Videobausteine daraus ableiten; ggf. Bild-Erweiterung gezielt
konfigurieren oder nicht unterstützte Inhalte verständlich behandeln.

Fundstellen:

- [FormBuilder](../../../decidim/decidim-core/lib/decidim/form_builder.rb), `editor`, `editor_options`, `editor_upload`.
- [Editorinitialisierung](../../../decidim/decidim-core/app/packs/src/decidim/editor/index.js), Toolbar-Modi.
- [DecidimKit](../../../decidim/decidim-core/app/packs/src/decidim/editor/extensions/decidim_kit/index.js), aktive Erweiterungen.
- [Image-Erweiterung](../../../decidim/decidim-core/app/packs/src/decidim/editor/extensions/image/index.js), Upload/parseHTML/renderHTML.

**Speicherung:** [EditorImagesController](../../../decidim/decidim-core/app/controllers/decidim/editor_images_controller.rb)
nimmt `image` an, [CreateEditorImage](../../../decidim/decidim-core/app/commands/decidim/create_editor_image.rb)
erstellt `Decidim::EditorImage` mit Autor und Organisation.
[EditorImage](../../../decidim/decidim-core/app/models/decidim/editor_image.rb) nutzt
`has_one_attached :file`. Der Upload liegt im konfigurierten ActiveStorage-Service,
nicht in einem Modul-Dateiverzeichnis. Core gibt eine Storage-URL zurück.
Ein dauerhafter Blockbezug zur passenden organisationsgebundenen EditorImage-/Blob-
Ressource muss neu entstehen; eine URL allein bietet keinen zuverlässigen Bezug.

**Alternativtext:** Der Core-[UploadDialog](../../../decidim/decidim-core/app/packs/src/decidim/editor/common/upload_dialog.js)
verwendet ein Feld `name="alt"` mit Core-Beschriftung. Es ist nicht required.
Beim Upload wird als Vorgabe der aufbereitete Dateiname eingesetzt. Der Inhalt
wird im Editor-HTML als `alt` gespeichert, nicht als Spalte an `EditorImage`.
Der HTML-Import muss ihn deshalb beim Zerlegen übernehmen und dauerhaft mit dem
Bildbaustein aufbewahren. Kein zweites Admin-Alt-Text-Feld nötig. Bei fehlendem
Text ist technisch `alt=""` möglich; die redaktionelle WCAG-Frage steht in E5.

HTML-Struktur ohne Bildlink, vereinfacht:

```html
<div class="editor-content-image" data-image="">
  <img src="…" alt="…" width="…">
</div>
```

Bei einem Bildlink steht noch ein äußerer `a`-Knoten darum. Der Import darf weder
Editorbreiten übernehmen noch Bilder in solchen Hüllen verlieren.

**Bildunterschrift:** In der geprüften Core-Image-Erweiterung gibt es keine
caption-Eigenschaft und kein `figcaption`-Feld. Der Umbauauftrag beschreibt eine
optionale Unterschrift in der Ausgabe, aber keinen Eingabe-/Importvertrag dafür.
Alternative in E3; Alt-Text und sichtbare Bildunterschrift sind unterschiedliche Daten.

**Typen und Grenzen:** Die serverseitige Allowlist und Dateigröße kommen aus den
Organisations-/Instanzeinstellungen. Der ImageUploader validiert maximal 3840 px
auf der längeren Bildkante; zu große Bilder werden abgelehnt, nicht automatisch
verkleinert. Die JS-Erweiterung hat eine Standardregel JPEG/PNG/SVG/WebP, der
FormBuilder übergibt aber die effektive serverseitige MIME-Allowlist.

Eine Laufzeitprobe mit einer isolierten Testorganisation in der hiesigen App ergab
JPG/JPEG/PNG/WebP, 10 MiB und 3840 px. Diese Werte sind keine feste Vorgabe für
andere Installationen. Textworks Grenze von 2 MiB gilt für den Dokumentdateiimport,
nicht für den separaten Core-Bild-Upload.

Fundstellen: [HasUploadValidations](../../../decidim/decidim-core/lib/decidim/has_upload_validations.rb),
[ImageUploader](../../../decidim/decidim-core/app/uploaders/decidim/image_uploader.rb),
[UploaderImageDimensionsValidator](../../../decidim/decidim-core/app/validators/uploader_image_dimensions_validator.rb).

**Varianten:** [EditorImageUploader](../../../decidim/decidim-core/app/uploaders/decidim/editor_image_uploader.rb)
definiert keine Varianten, sein effektives `variants` ist in der Test-App `{}`.
[ApplicationUploader](../../../decidim/decidim-core/app/uploaders/decidim/application_uploader.rb)
bietet zwar Variant-Unterstützung, aber keine passende fertige Editorbildgröße.
Der Satz im Auftrag über bereits vom Core erzeugte verkleinerte Fassungen ist
für diesen Bildtyp daher nicht zutreffend. ActiveStorage-Varianten auf derselben
Datei sind machbar und müssen für Textwork ausdrücklich definiert werden.

**Importbestand:** `Markdown.from_html` lässt reine Bildknoten derzeit weg und
entfernt Bilder auch aus Textknoten. `DocumentInput` extrahiert bei DOCX nur
Text-/Formatierungs-Runs und bei ODT nur Textstruktur. Es liest keine Bilddateien
oder Bild-Relationships aus den Archiven. Auch Markdown-Bilder werden bisher
nicht als Bildbausteine übernommen. Der Bild-Import ist echte neue Funktionalität.

Prüfung: Code und Laufzeitkonfiguration, kein neuer Bild-Upload, keine neue Datei
im Storage, keine Bildvariantenerzeugung. Die Zerlegung, vier Bildformate und
Overlay-/Fokusabläufe werden erst in Schritt 9 gebaut und geprüft.

### Widersprüche und vorgeschlagene Präzisierungen

Die folgende Liste unterscheidet notwendige fachliche Entscheidungen von
technischen Ergänzungen. Keine dieser Empfehlungen wurde in Schritt 0 umgesetzt.

| ID | Befund | Vorschlag zur Änderung/Präzisierung des Auftrags | Wann entscheiden |
| --- | --- | --- | --- |
| E1 | Abschnitt 4.1 erlaubt Vorbereitung/Korrektur nach Rückzug ohne Beteiligung, verbietet aber neue BlockVersion/DocumentRevision außerhalb des Imports. Änderungen/Add im vorhandenen Service erzeugen Fassungen; jeder Vorschlag benötigt einen gültigen Fassungssnapshot. | Fassungen während der Vorbereitung intern weiterhin zulassen; ab Veröffentlichung in Sammelphase keine Änderungen/Entscheidungen. Falls exakt eine Ausgangsfassung verlangt wird, deren Erzeugung bei Veröffentlichung separat planen, nicht alte immutable Fassungen überschreiben. | Vor Schritt 1. |
| E1a | "Noch keine Zustimmung, keinen Kommentar und keinen Vorschlag" kann aktuelle Zahlen oder die gesamte Beteiligungsgeschichte meinen. Likes können zurückgenommen, Kommentare gelöscht werden. Nur Suggestion hat bisher einen dauerhaften Erstfeedback-Marker. | Historische Beteiligung meint jede jemals erfolgte Rückmeldung; Korrektur nach Rückzug dann weiter gesperrt. Dafür dauerhaften Dokumentmarker prüfen. Originaltitel/Beschreibung in die Sperre einbeziehen; Pflege geprüfter Übersetzungen getrennt regeln. Papierkorb/Restore darf Schutz nicht aufheben. | Vor Schritt 1. |
| E2 | Die aktive Phase wird nicht automatisch anhand des Enddatums gewechselt; die vorhandenen Sperren wirken unabhängig davon. | Schreiben: "Das Datum ist eine Anzeige; Verantwortliche schließen die Sammelphase mit den Phaseneinstellungen. Es gibt keine zusätzliche datumsgesteuerte Sperre." Eine automatische Schließung nur nach gesonderter Entscheidung. | Vor Fristanzeige/Schritt 3. |
| E3 | Keine fertigen Editorbildvarianten, kein Caption-Feld, bislang keinerlei Datei-Bildimport. | Core-Upload und Alt-Text übernehmen; Varianten für Textwork selbst definieren. Caption zunächst nur übernehmen, wenn eindeutig mitgeliefert, sonst weglassen, oder eigenes optionales Caption-Feld beschließen. Editor-/HTML-Bilder zuerst; DOCX/ODT eingebettete Bilder als zusätzlichen Umfang ausdrücklich entscheiden. Keine fremden Bild-URLs unbemerkt serverseitig abrufen. | Vor Schritt 9. |
| E4 | Referenz ignoriert reine Satzzeichenänderungen vollständig in der Markierung; CRLF erzeugt dagegen falsche Änderungen. Sie hat keine Begrenzung der quadratischen LCS-Matrix. Der neue Vergleich ersetzt einen bisher verlustfreien Vergleich mit Laufzeitgrenze. | CRLF zu LF normalisieren und begrenzte Berechnung behalten. Für ausschließlich Satzzeichenänderungen Bisher/Vorschlag zeigen oder die Unmarkiert-Regel ausdrücklich bestätigen. Vollständigen Vorschlag unverändert speichern. Schwellenwerte zunächst als überprüfbare Darstellungsregeln übernehmen, nicht als Validierungsregeln. | Vor Schritt 6. |
| E5 | Core verlangt keinen ausgefüllten Alt-Text und füllt aus dem Dateinamen vor. Damit ist inhaltlich aussagekräftiger Alt-Text nicht sichergestellt. | Core-Feld behalten, keine pauschale Pflicht für dekorative Bilder. Redaktionelle Prüfung inhaltlicher Bilder vor Veröffentlichung vorsehen; Vorgehen bei fehlender Textalternative ausdrücklich festlegen. | Vor Schritt 9. |
| E6 | Abschnitt 3.6 sagt "Dateien ersetzen / fehlende Schlüssel entfernen"; der Kommentar im neuen de.yml nimmt Admin und Auswertung ausdrücklich aus. Aktive Fehler-, Leer- und Original-Fallbacktexte fehlen ebenfalls teilweise. | Nur die Sammel-Frontend-Schlüssel ersetzen. Admin, Events, Modell-Ressourcentitel, Validierungs-/Fallbacktexte und deaktivierte Auswertung erhalten. Nicht jeden unbenutzten Auswertungsschlüssel im Aufräumschritt löschen. | Technische Präzisierung für Schritte 3 und 13. |
| E7 | Exportannahme "wie bisher" enthält Angaben, die der Writer noch nicht ausgibt: Vorschlagsdatum und -Likes. Sortierung ist derzeit nach Erstellungsdatum, nicht Zustimmung. Der DOCX-Writer kann keine Bilder einbetten. | Schritt 12 umfasst ausdrücklich Datum, Likes und Sortierung. Bildplatzhalter als vorhandenen einfachen Weg verwenden; echten Bildexport gesondert entscheiden. | Vor Schritt 12; keine Grundsatzblockade. |
| E8 | Ein Auswertungsschalter könnte wieder Entscheidungen/Textänderungen aktivieren, obwohl der Text während Sammlung immer unverändert bleiben muss. Bestehende accepted/rejected- und Versionsdaten können vorhanden sein. | Schalter standardmäßig aus; Auswertung erst in späterem definiertem Ablauf aktivieren, keine Veröffentlichungssperre durch den Schalter allein aufheben. Historische Daten erhalten und vor dem Umstieg gesondert behandeln. Keine bestehenden Vorschläge zurücksetzen oder löschen. | Vor Schritt 1; spätere Auswertung eigener Auftrag. |

Für E5 gilt [W3C, WCAG 2.2, Nicht-Text-Inhalte](https://www.w3.org/WAI/WCAG22/Understanding/non-text-content.html):
Inhaltliche Bilder benötigen eine ihrem Zweck entsprechende Textalternative;
rein dekorative Inhalte müssen ignorierbar sein. Eine technische Uploadfreigabe
belegt daher keine inhaltliche Barrierefreiheit. Diese Empfehlung ändert die
vorgegebene Core-Eingabe nicht ohne eine Entscheidung.

Weitere Regeln des Pakets sind als noch nicht ausdrücklich bestätigt markiert:
660-px-Containergrenze, drei initial sichtbare Vorschläge, Diff-Schwellen und
Bildhöhenlimit. Sie sind umsetzbare Startwerte. Fokus, Kontrast und Layout müssen
mit Core-Tokens, anderen Instanzfarben und schmalen/kurzen Ansichten geprüft werden;
Mockup-Pixel sind kein Ersatz dafür. Alte Kapitel-Abonnements oder eigene
Vorschlags-Likes werden nicht ungefragt umgedeutet oder entfernt.

### Tests und Grenzen der Aussage

Am 6. Oktober 2026:

- Bestehende Suite `bundle exec rspec spec`: **54 Beispiele, 0 Fehler**, Seed
  `64668`, 41,09 s plus Laden; davon 12 Browserabläufe. Vorhandene Test-App/Packs,
  zurückgerollte Testfixtures, kein Development-Reset und kein externer Dienst.
- `npm test`: bisheriger Tokenvergleich und Kurzkontext bestehen.
- `bin/check-independence`: lädt ohne Proposals und Collaborative Texts.
- Drei temporäre Request-/Laufzeitproben außerhalb des Repositories: **3 Beispiele,
  0 Fehler**, Seed `58717`. Sie erwarten ausdrücklich den bestehenden Core-Like-
  Fehler und die bisher erlaubte Eigenzustimmung; sie sind keine Abnahme der neuen
  Regeln. Außerdem Uploadkonfiguration und 20 Dateien mit den vier genannten
  Source-Unterschieden bestätigt. Frühe Probeversuche fanden diese Unterschiede;
  keine Fehler durch Änderung von Anwendungscode behoben.
- Wortvergleichsreferenz separat: **alle sieben gelieferten Beispiele stimmen**.
  Zusätzlich reproduziert: Satzzeichen-only ohne Markierung und CRLF als falsche
  Wortänderung. Noch nicht als Tests in die Modulsuite übernommen.
- `git diff --check` und interne Dokumentationsverweise geprüft.

Lokale Protokolle zur Nachprüfung, nicht Teil der Auslieferung:
`/private/tmp/textwork-step0-rspec.log`, `/private/tmp/textwork-step0-probes.log`.
Die temporären Proben verändern weder Modulcode noch Entwicklungsbeiträge.

Nicht geprüft: die neue Oberfläche, 100-Absatz-Abfragebudget, tatsächlicher
Editorbild-Upload/Storage/Varianten, Officebilder, vollständiger WCAG-Audit,
Screenreader, neue Phasen-/Veröffentlichungssperren oder spätere Auswertung.
Diese Funktionen wurden in Schritt 0 nicht gebaut. Ein erfolgreicher Ausgangstest
bestätigt ausschließlich den bisherigen Stand.

### Abnahme von Schritt 0

Das Kriterium aus dem Auftrag lautet: "beide Dateien vorliegen und du Befunde
nennst, die diesem Auftrag widersprechen. Baue in diesem Schritt nichts."

`BESTAND.md` liegt vor, diese Erkundung ergänzt alle fünf Fragen und nennt die
Widersprüche samt vorgeschlagener Präzisierungen. Nur diese zwei Dokumente wurden
geändert. Schritt 0 ist damit abgeschlossen. Schritt 1 beginnt erst nach der
vorgesehenen Bestätigung der Befunde. Der anschließende Nachtrag nimmt Schritt 0
ab. E1a war darin noch unbestätigt und wurde anschließend vom Nutzer bestätigt,
siehe den folgenden Abschnitt.

## Nachtrag zum Umbauauftrag

Am 6. Oktober 2026 hat der Nutzer auf
[AENDERUNGEN_ZUM_UMBAUAUFTRAG.md](../../../decidim-enhanced_textwork/textwork-umbau/docs/AENDERUNGEN_ZUM_UMBAUAUFTRAG.md)
und die überschriebenen Referenz-/Mockupdateien hingewiesen. Die Ergänzung hat
Vorrang vor dem unveränderten Umbauauftrag. Sie nimmt Schritt 0 ab und beschreibt
den anschließenden Umfang. Diese Nachführung setzt noch keinen Umbauschritt um.
Anschließend wurde die als vollständig bestätigt gekennzeichnete Fassung 3
als Nutzeranlage geliefert. Sie liegt unverändert in
[AENDERUNGEN_ZUM_UMBAUAUFTRAG.md](AENDERUNGEN_ZUM_UMBAUAUFTRAG.md).
Die folgende Entscheidungstabelle berücksichtigt Fassung 3; die vorangehenden
Befunde und Testergebnisse bleiben die historische Erkundung aus Schritt 0.

### Antworten auf die Befunde

| Punkt | Neuer Stand laut Nachtrag | Folge gegenüber Schritt 0 |
| --- | --- | --- |
| E1 | Fassungen und Strukturverlauf in der Vorbereitung intern weiterschreiben; nicht überschreiben. Bei veröffentlichtem Text keine neuen Einträge. | Widerspruch zur bisherigen Import-only-Regel gelöst. Versionscode behalten; öffentliche Verläufe bleiben abgeschaltet. |
| E1a | Vom Nutzer am 6. Oktober 2026 bestätigt. Maßgeblich ist der aktuelle gespeicherte Bestand, ohne dauerhaften Beteiligungsmarker. Jeder gespeicherte Vorschlag und Kommentar sperrt, auch withdrawn/hidden/deleted; jede gespeicherte Zustimmung ebenfalls. Originaltitel/-beschreibung und Aufbau sperren; Übersetzungen dürfen gepflegt werden. Zusätzlich ist das Zurückziehen des Dokuments bei Beteiligung gesperrt. Papierkorb bleibt auch mit Beteiligung erlaubt. | Weicht von meiner historischen Sperrempfehlung ab. Keine Marker-Migration. Prüfung vor Rückzug und Originalbearbeitung; Papierkorb erhält alle Rückmeldungen, Restore hebt die Sperre nicht auf. |
| E2 | Zusätzliche Datumssperre des Moduls, kombiniert mit Phasenschaltern. Ende des Tages in Organisationszeitzone; neue Phase/verlängerte Frist öffnet wieder. Folgen/Entfolgen, Löschen eigener Kommentare und Melden bleiben von dieser Sperre ausgenommen. | Frist ist nicht mehr nur Anzeige. Zentrale Regel für Schreiben über Modul und Core erforderlich. Tagesende ist in Fassung 3 bestätigt. Kommentare anlegen, bearbeiten und bewerten werden gesperrt; Löschen eigener Kommentare weiterhin erlauben. |
| E3 | Nur Core-Editorbilder, kein Datei-Bildimport, keine Unterschrift. Dauerhafter EditorImage-/Anhangbezug und Alt-Text am Block; kein Abruf fremder URLs. Textvariante maximal 1600 px, Zoom Original. | Importumfang klar begrenzt. Variantenwahl ist in Fassung 3 bestätigt. Migration nur für Bildbezug/Alt-Metadaten vorgesehen. |
| E4 | Vorhandenes `diff.mjs` bleibt samt verlustfreiem Vergleich und Laufzeitgrenze; nur Darstellung ergänzen. Satzzeichen sichtbar, CRLF normalisieren, Speichertext unverändert. | Referenz ist ausschließlich Veranschaulichung. Neun Muss-gelten-Fälle ersetzen sieben exakte Referenzausgaben als Abnahmemaßstab. |
| E5 | Hinweis auf leeren/aus Dateinamen abgeleiteten Alt-Text vor Veröffentlichung; Vorschau und nachträgliches Eingabefeld; Trotzdem veröffentlichen bleibt möglich. | Keine Upload-/Veröffentlichungsblockade. Das neue Feld bearbeitet den importierten Block, kein zweites gleichzeitiges Uploadfeld. Redaktioneller Hinweis belegt keine vollständige WCAG-Konformität des Inhalts. |
| E6 | Sammel-Frontend-Schlüssel zusammenführen; Admin, Events, Ressourcentitel, Fehler/Fallback/Leerzustände und Auswertung erhalten. | Empfehlung übernommen. Neue Admin-Schlüssel aus Abschnitt 2.6 zusätzlich übernehmen; bestehende Locale-Dateien im Paket sind noch nicht angepasst. |
| E7 | Absatz-Likes, Vorschlagsdatum/-Likes und Sortierung; Bilder nur als Platzhalter mit Alt-Text. | Echter Bildexport ist ausdrücklich ausgeschlossen. Bestehender Textwriter reicht als Grundlage. |
| E8 | Auswertung aus; Schalter allein hebt Textsperre nicht auf; historische Daten erhalten. | Empfehlung übernommen. Spätere Auswertung eigener Auftrag. |

Kommentare bleiben ungekürzt mit Core-Nachladen; `comments.show_all` entfällt.
Die drei initial sichtbaren Einträge gelten nur für Vorschläge. Sortieranzeige
nach Kommentarzahl bleibt eine lokale CSS-Anpassung mit aktualisierter
Kennzeichnung. Nur eine Core-Kommentarressource gleichzeitig montieren.

Alte Kapitel-Likes/-Abonnements bleiben gespeichert, ohne neue Anzeige oder
Umdeutung. Alte eigene Vorschlags-Likes zählen weiter; neue eigene Likes sind
verboten. Fassung 3 bestätigt die Ausnahme: Nur der Like-Autor kann zurücknehmen,
solange Phase und Frist Zustimmungen erlauben. POST für Eigenzustimmung bleibt
verboten, DELETE für eine vorhandene eigene Zustimmung wird erlaubt. Am eigenen
Vorschlag erscheint dafür neben der Anzahl der Link „Eigene Zustimmung
zurücknehmen“, nur wenn eine solche Zustimmung vorhanden und ihre Rücknahme
erlaubt ist. Der neue Schlüssel ist `decidim.textwork.suggestions.unlike_own`.

### Ergänzende technische Prüfung

**Zeitzone:** Core besitzt `Organization#time_zone` und
[UseOrganizationTimeZone](../../../decidim/decidim-core/app/controllers/concerns/decidim/use_organization_time_zone.rb).
In Requests wird die Organisationszeitzone gesetzt. Die neue modulweite Regel
soll trotzdem aus Organisation und aktueller Zeit ausdrücklich das lokale Datum
ermitteln, damit sie auch außerhalb eines Controllers korrekt ist. Ein Vergleich
des lokalen Datums mit `end_date` vermeidet die Annahme, ein Kalendertag habe
immer 24 Stunden. Tests sollen unterschiedliche Zeitzonen und Tagesgrenzen
einschließen. Fassung 3 bestätigt diesen Ansatz; der Schutz ist noch nicht gebaut.

**Alle Core-Schreibwege:** Die Komponenten-Permission allein erreicht nicht
automatisch sämtliche Controller:

- [Components::BaseController](../../../decidim/decidim-core/app/controllers/decidim/components/base_controller.rb)
  verwendet die Komponenten-Permissions. Darüber laufen die allgemeinen Likes.
- [FollowsController](../../../decidim/decidim-core/app/controllers/decidim/follows_controller.rb)
  erbt die globale Registry-Kette von
  [ApplicationController](../../../decidim/decidim-core/app/controllers/decidim/application_controller.rb).
  Die Textwork-Komponenten-Permission ist dort nicht automatisch enthalten.
  [RegistersPermissions](../../../decidim/decidim-core/app/controllers/concerns/decidim/registers_permissions.rb)
  bietet eine modulweite Anbindung; sie muss auf Textwork-Ressourcen begrenzt
  bleiben, damit andere Komponenten unverändert funktionieren.
- [Comments::ApplicationController](../../../decidim/decidim-comments/app/controllers/decidim/comments/application_controller.rb)
  setzt seine eigene Kette. In
  [Comments::Permissions](../../../decidim/decidim-comments/app/permissions/decidim/comments/permissions.rb)
  fragen Erstellen und Bewerten Modellhooks ab; Bearbeiten/Löschen fragen dagegen
  nur die Autorschaft ab. Fassung 3 sperrt ausdrücklich Bearbeiten nach
  Frist/Schalter und lässt Löschen eigener Kommentare weiter zu. Dafür braucht
  es eine passende, ausschließlich Textwork betreffende Anbindung und Tests,
  nicht nur `accepts_new_comments?`. Die Löschberechtigung anderer Nutzer wird
  durch diese Ausnahme nicht erweitert.

Die Hinweise sind keine Begründung für Änderungen an Core-Dateien. Die konkrete
Anbindung wird im jeweiligen Umbauschritt geprüft und gebaut. Auch direkte
Modell-/Command-Regeln bleiben wichtig. Aus einem verborgenen Button entsteht
noch keine serverseitige Sperre.

**Bestandsprüfung vor Rückzug und Bearbeitung:** Nach der bestätigten E1a-Regel keine
sichtbarkeitsgefilterten Zähler verwenden. Alle Vorschlagsstatus, Kommentare mit
hidden/deleted-Markern und gespeicherte Likes der zugehörigen Ressourcen sind
zu prüfen. Core-Kommentarlöschung setzt `deleted_at` und erhält den Datensatz;
nach der wörtlichen Regel "kein Kommentar gespeichert" sperrt er weiter. Core-
Unlike entfernt dagegen den Like-Datensatz. Deshalb unterscheidet sich E1a
praktisch vor allem bei zurückgenommenen Zustimmungen von einem dauerhaften Merker.
Entfernte Blöcke und Papierkorb/Restore dürfen nicht zur Umgehung führen.

### Überarbeitete Referenzen und Mockups

Gelesen wurden die neue Referenz, alle neun Beispiele, der Screenshotindex und
die geänderten Darstellungsstellen im Mockupcode. Exemplarisch visuell geprüft:
`d-05`, `d-08`, `d-18` und `m-02`. Die Ansichten zeigen Satzzeichenänderungen und
keine Bildunterschrift. Die Kommentar-Daten im Mockup werden nicht mehr auf drei
gekürzt. Unbenutzte Mockupvariablen für caption/moreK existieren noch; sie sind
keine Anforderung und werden nicht in den Modulcode kopiert.

Die Fassung-2-Referenz besteht in einer separaten Node-Probe für sichtbare
Satzzeichen, gleichwertige CRLF/LF-Zeilen, reine Leerzeichen und großen Umbau.
Das ist keine Abnahme aller neun Muss-gelten-Fälle im Modul: Darstellungsregeln
und CRLF-Behandlung fehlen dort noch. Ihre Integration samt neun automatischen
Tests bleibt Schritt 6.

README und STARTAUFTRAG des Pakets enthalten noch Angaben aus Fassung 1, etwa
"sieben Testfälle" und Übersetzungsdateien ersetzen. Der Nachtrag ist hier
ausdrücklich vorrangig. Die vom Nutzer gelieferten Dateien wurden nicht bearbeitet.

### Stand nach Durchsicht des Nachtrags

`BESTAND.md` ist entsprechend nachgeführt. Die frühere Empfehlung einer rein
angezeigten Frist und eines Ersatzes von `diff.mjs` ist abgelöst. Die bestehende
Ausgangssuite wurde für diese reine Dokumentationsänderung nicht erneut ausgeführt;
es gibt weiterhin keinen neuen Anwendungscode und keine Migration. Lokale Links
und `git diff --check` werden erneut geprüft.

E1a ist durch die anschließende Nutzerantwort bestätigt. Der Nutzer ergänzt:
"es darf nur zurückgezogen / bearbeitet werden, wenn es noch keine Beteiligungen
gab". Dies sperrt auch den Rückzug selbst, sobald gespeicherte Beteiligung
vorliegt. Als Bestätigung der E1a-Regel gilt weiterhin der aktuelle Bestand;
eine zurückgenommene Zustimmung allein erzeugt keinen dauerhaften Schutzmarker.
Bereits zurückgezogene Dokumente mit gespeicherter Beteiligung bleiben gegen
Originalbearbeitung geschützt. Die Umsetzung und ihre Tests gehören zu Schritt 1.

Bei der ersten Durchsicht waren Tagesende/Zeitzone, 1600-px-Variante, historische
Eigen-Likes und Darstellungsgrenzen noch ausdrücklich unbestätigt. Die danach
gelieferte Fassung 3 kennzeichnet sie als bestätigt und löst diesen offenen Stand ab.

### Fassung 3 und nächste Umsetzung

Fassung 3 passt zum bisherigen Aufbau und erfordert keinen neuen Branch und kein
neues Gem. Sie schließt die offenen Entscheidungen und präzisiert drei Abläufe:

- Schritt 1 muss Rückzug und Papierkorb unterscheiden. Beteiligung sperrt den
  Rückzug und Originaländerungen. Papierkorb bleibt erlaubt, entfernt die
  öffentliche Sichtbarkeit und erhält die Rückmeldungen. Restore muss den
  Beteiligungsschutz erneut anwenden. Die bisherige Veröffentlichung wird durch
  Verschieben in den Papierkorb nicht als Umweg zu einer bearbeitbaren Fassung
  aufgehoben.
- In Schritt 2/5 bekommt ein vorhandener eigener Vorschlags-Like einen erlaubten
  Rücknahmeweg und den benannten Link. Neue Eigenzustimmungen bleiben verboten.
- Schritt 11 sperrt Vorschläge anlegen/bearbeiten/zurückziehen, Zustimmungen
  geben/zurücknehmen und Kommentare anlegen/bearbeiten/bewerten. Folgen/Entfolgen,
  Löschen eigener Kommentare und Melden bleiben möglich, wenn die normalen
  Zugriffs- und Autorenregeln erfüllt sind. Eine pauschale Sperre aller
  Schreibaktionen nach Fristende wäre falsch.

Die Schwellen 660 px, drei Vorschläge, großer Umbau und Bildhöhe sind bestätigte
Startwerte. Sie werden nach dem Bau am Bildschirm geprüft und bei Bedarf angepasst.
Ausführungsreihenfolge und Schrittgrenzen bleiben erhalten. Die nächsten Tests
für Schritt 1 müssen insbesondere die Papierkorb-/Restore-Ausnahme und getrennte
Original-/Übersetzungsbearbeitung abdecken. Die Frist-Ausnahmen gehören zu Schritt 11.

Es wurde nur Dokumentation nachgeführt und die gelieferte Fassung unverändert
gesichert. Anwendungscode, Datenbank und der Teststand aus Schritt 0 bleiben
unverändert. Die Fassung-3-Regeln sind damit festgehalten, noch nicht implementiert.

## Schritt 1: Abschalten und sperren

Umgesetzt am 6. Oktober 2026 nach ausdrücklichem Auftrag des Nutzers, auf
`feature/textwork-redesign`. Die Zuordnung zu den Dateien aus Schritt 0 steht in
[BESTAND.md](BESTAND.md#umsetzung-von-schritt-1).

### Schutzregeln

- `Document#participation?` fragt gespeicherte Vorschläge, Kommentare und Likes
  ab, einschließlich entfernter Blöcke, aller Vorschlagsstatus sowie verborgener
  und gelöscht markierter Kommentare. Öffentliche Zähler werden dafür nicht
  verwendet. Ein Unlike entfernt den Datensatz und damit diese Beteiligung;
  kein dauerhafter Dokumentmarker und keine Migration.
- `original_editable?` verlangt ein unveröffentlichtes, nicht im Papierkorb
  liegendes Dokument ohne Beteiligung. `EditDocument` prüft dies unter
  Dokument-Lock vor jeder Änderung. Metadatenänderungen und Veröffentlichung/
  Rückzug werden ebenfalls unter Lock geprüft. Neue Vorbereitungsfassungen und
  Strukturverläufe bleiben erlaubt. Fremde Blöcke/Vorschläge können nicht an einen
  Bearbeitungsservice für ein anderes Dokument übergeben werden.
- Originaltitel und Originalbeschreibung sind eingeschlossen. Übersetzungen
  können weiter gepflegt werden, ohne neue Originalfassungen zu erzeugen.
  Gleichzeitige verbotene Originaländerung und Übersetzung führen zum Abbruch
  des gesamten Requests. Im Admin-Formular sind gesperrte Originalfelder readonly.
- `evaluation_enabled` ist standardmäßig false. Admin-Review und Entscheiden
  besitzen eine eigene Berechtigungsprüfung; der Service schützt auch direkte
  Aufrufe. Der Schalter allein erlaubt keine Änderung veröffentlichter Texte.
  Bestehende Entscheidungen und Fassungen werden nicht zurückgesetzt.
- Öffentliche Dokument-/Blockverläufe sind mit ausgeschalteter Auswertung
  gesperrt; ihre Links sind ausgeblendet. Modelle, Verlaufscode, Routen und
  Ansichten bleiben erhalten. Die spätere Auswertung ist damit nicht umgesetzt.

### Papierkorb und Core-Kommentare

`Decidim::Likeable` definiert `dependent: :destroy`; der bisherige Aufruf
`document.destroy!` würde auch beim Paranoia-Soft-Delete die Dokument-Likes
löschen. Der Admin-Papierkorb markiert deshalb `deleted_at` unter Lock per Update.
Dadurch bleiben sämtliche Beiträge und Abonnements gespeichert. Der normale
Searchable-Update-Callback entfernt den Dokumenttreffer. Restore bleibt unter
Lock und hebt keine Beteiligungssperre auf.

Eine weitere Lücke betrifft Kommentare. Core-`Comment#visible?` berücksichtigt
Raum/Komponente, aber nicht die Veröffentlichung oder den Papierkorb des
Textwork-Dokuments. Die Core-Kommentarleseberechtigung fragt `commentable?` ab;
für signierte Kommentaradressen kann die Ressource auch ein Kommentar selbst
sein. Die Modul-Ergänzung `CommentVisibility` prüft deshalb bei Textwork-Wurzeln
zusätzlich die Ressourcensichtbarkeit. Block/Vorschlag schützen ihren eigenen
Kommentarbereich ebenfalls. Andere Komponenten behalten das Core-Verhalten.

Bei Änderungen an Veröffentlichung oder Papierkorb sowie beim Restore werden
die gespeicherten Absatz- und Vorschlagskommentare einschließlich Antworten
neu indexiert. So verschwinden deren Suchtreffer beim Ausblenden, ohne die
Kommentare zu löschen. Verborgene oder gelöscht markierte Textwork-Kommentare
werden dabei nicht wieder in die Suche aufgenommen. Es wurde keine Core-Datei
geändert. Die zusätzlichen Prüfungen sind noch keine Fristsperre aus Schritt 11.

### Abnahme und Grenzen

Die Fertig-wenn-Zeile aus Schritt 1 ist erfüllt:

- Annehmen/Ablehnen sind für Admins über GET/PATCH und Service gesperrt. Auch ein
  eingeschalteter Auswertungsschalter übergeht den Schutz nicht.
- Veröffentlichte Texte, Aufbau, Originaltitel und Originalbeschreibung lassen
  sich über die Admin-Schreibwege nicht ändern. Rückzug ohne Beteiligung erlaubt
  erneute Korrektur; Beteiligung sperrt ihn. Papierkorb/Restore erhalten
  Rückmeldungen und die Sperre. Übersetzungen bleiben bearbeitbar.
- Vollständige Suite: **75 Beispiele, 0 Fehler**, Seed `25141`, 47,65 s plus
  2,06 s Laden, einschließlich 12 Browserabläufen. 21 zusätzliche Prüfungen
  decken die neuen Regeln ab. RuboCop: **64 Dateien, keine Verstöße**;
  `npm test`, `bin/check-independence` und `git diff --check` bestanden.

Alte Tests für Entscheidungs-/Benachrichtigungsalgorithmen bleiben erhalten und
kennzeichnen ihren isolierten Policy-Stub ausdrücklich. Sie belegen den
erhaltenen Code, keine öffentlich aktivierbare Auswertung. Die Schutztests in
`collection_lock_spec.rb` verwenden dafür keine Policy-Stubs. Historische
Browserfixtures stellen alte Fassungen/Entscheidungen als gespeicherte Daten dar;
sie werden nicht durch jetzt verbotene Admin-Aktionen erzeugt.

Frühe Prüfläufe fanden Syntax-/Request-Probleme und unpassende Altfixtures;
diese wurden vor dem erfolgreichen Gesamtlauf korrigiert. Die Regeln wurden
in der isolierten Testdatenbank geprüft; keine Entwicklungsbeiträge verändert.
Protokolle: `/private/tmp/textwork-step1-rspec.log` und
`/private/tmp/textwork-step1-rubocop.log`.

Die lokale App 3033 wurde mit ihrem eigenen `bin/localtest restart` neu gestartet.
Alpha2 und die gemeinsame Datenbank wurden nicht gestoppt. Keine Migration,
Seeds oder Assetquelltextänderung; deshalb kein erneuter Asset-Build.

Nicht geprüft oder umgesetzt: spätere Auswertungsaktivierung, Fristregeln,
Absatz-Likes/Zähler aus Schritt 2, neue Oberfläche, Bildimport, vollständiger
WCAG-Audit, parallele Teilnahme über sämtliche Core-Schreibwege. Die
Mutationstests dieses Schritts ersetzen insbesondere keine späteren Core-
Like-/Kommentar- und Fristtests aus Schritten 2 und 11.

## Umsetzung der restlichen Schritte am 6. Oktober 2026

Der Nutzer hat die restliche Umsetzung ohne Zwischenfreigaben autorisiert.
Abnahme und endgültiger Aufbau:
[SAMMELPHASE-IMPLEMENTATION.md](SAMMELPHASE-IMPLEMENTATION.md).
Frühere Befunde und Vorschläge bleiben oben als Erkundung erhalten.

Die Core-Berechtigungen wurden per auf Textwork begrenztem `prepend` nach der
Core-Prüfung ergänzt, ohne Umordnen einer Registry. `allowed_to?` erhält eine
Ablehnung ohne Exception beim Rendern; die Controller erzwingen diese Ablehnung.
Dies schützt auch die Rücknahme einer alten eigenen Vorschlagszustimmung:
Die anschließend gerenderte Core-Cell fragt nach der Erlaubnis zum Anlegen einer
Zustimmung. Ein Wurf dort würde die Rücknahme im Dokument-Lock zurückrollen.

Fristtests verwenden Organisationszeitzone und gestellte Uhr. Die Anmeldung wird
nach dem Uhrsprung erneuert, damit ein Login-Timeout nicht die Schreibsperre ersetzt.
Layouttests warten den Browserframe vor Höhenvergleichen ab. Nachgeladene Core-
Dialoge benötigen das vorhandene `ajax:loaded`-Protokoll.

Die Bild-Migration ist additiv und lief nur in den getrennten Datenbanken der
Redesign-App. Keine alten Beiträge migriert, keine Entwicklungsdaten zurückgesetzt,
keine Kundeninstallationen verändert.
