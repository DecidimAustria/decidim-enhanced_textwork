# Erkundung für das Textwork-Redesign

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
