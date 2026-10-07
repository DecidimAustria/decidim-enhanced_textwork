# Umbau zur Sammelphase

Stand: 6. Oktober 2026. Branch `feature/textwork-redesign`, bestehendes Gem
`decidim-enhanced_textwork`, Decidim 0.32.1. Grundlage: Umbauauftrag und bestätigte
[Fassung 3](AENDERUNGEN_ZUM_UMBAUAUFTRAG.md). Der Nutzer hat die verbleibenden
Schritte zusammen freigegeben; es wurde kein weiterer Branch angelegt.

## Abnahme der Schritte

| Schritt | Umsetzung und Nachweis |
| --- | --- |
| 0 Bestand | BESTAND/ERKUNDUNG erhalten Ausgangslage, geprüfte Core-Schnittstellen und bestätigte Entscheidungen. |
| 1 Sperren | Auswertung aus; veröffentlichter Originaltext, Originalmetadaten und Aufbau gesperrt. Rückzug nur ohne gespeicherte Beteiligung, Papierkorb/Restore erhalten Beiträge. Übersetzungen bleiben bearbeitbar. `collection_lock_spec`. |
| 2 Zustimmung/Zähler | Core-Likes an Absatz und fremdem Vorschlag. Überschrift, Bild und eigener Vorschlag auch über Core-Endpunkte gesperrt. Alte eigene Likes bleiben gezählt und zurücknehmbar. Sichtbare pending-Vorschläge und Absatzkommentare zählen getrennt von Vorschlagskommentaren. Stats und gesamte Seite mit 100 Absätzen ohne Abfrage je Absatz. `participation_spec`. |
| 3 Seite/Zeilen | Reservierte rechte Spalte, Dokument-Folgen als Core-Cell, Inhaltsverzeichnis über dem Text mit Kapitelzählern, eine beschriftete Pille je Absatz, Start ohne Auswahl. Links bleibt die Breite beim Wechsel gleich. `browser_spec`. |
| 4 Leiste/Überblick | Klebender Behälter mit Höhe 0, feste Kopfleiste, eigener Scrollbereich mit `overscroll-behavior: contain`; Höhe nach Fenster und Core-Seitenfuß. Überblick mit Rückkehr, ausblendbarer Anleitung/Legende, drei meistdiskutierten Absätzen, stillen Absätzen und Frist. Desktop/1054px, kurze Dokumente und Seitenfuß geprüft. |
| 5 Absatz/Liste | Drei Aktionen im Kopf, Vorschläge vor Kommentaren, zunächst drei Karten, dann alle. Zustimmung absteigend, bei Gleichstand älteste zuerst. Textklick auch mobil; keine Reiter, Fassungszeilen oder Vorschau im Original. |
| 6 Wortvergleich | Vorhandener begrenzter, verlustfreier Tokenvergleich erhalten. Eine Darstellung für Karte, Detail und Live-Vorschau; Löschung vor Einfügung, große Änderungen als Bisher/Vorschlag. Neun verbindliche Fälle plus Verlustfreiheit/Laufzeit bestehen. Server-Markup enthält Bisher/Vorschlag als Text. |
| 7 Formular | Ausschließlich rechts/im Blatt, Fokus am Textende, unveränderte Texte gesperrt, Live-Vergleich, optionale Begründung, feste Fußleiste. Entwurfsschutz bei Escape, Abbrechen, Schließen und Absatzwechsel. Absenden kehrt zur Liste mit Rückmeldung zurück. |
| 8 Detail/Kommentare | Voller Vergleich, Begründung, Zustimmung, eigene Aktionen, Core-Meldedialog und genau eine Diskussion. Absatz-/Vorschlagskommentare anlegen, bearbeiten, beantworten und bewerten geprüft. Core-Nachladen erhalten; Sortierung unter fünf Kommentaren lokal ausgeblendet/dynamisch aktualisiert. |
| 9 Bilder | Echter Core-Upload im Requesttest, dauerhafte EditorImage-Verknüpfung/Alt-Text. Absatzteilung und Bilder hinter ganzen Listen; fremde URLs/Videos ausgelassen. Vorschau/Alt-Feld vor Veröffentlichung mit Veröffentlichung trotz fehlender Beschreibung. Varianten bis 1600px, Zoom lädt Original. Vier Seitenverhältnisse mit tatsächlicher Bildauslieferung bei 1440/390px geprüft; keine Vergrößerung kleiner Bilder oder horizontales Scrollen. |
| 10 Tastatur | Tastaturablauf mit Zustimmung, Einreichung, Escape/Rückfrage und Fokus zurück zur Absatzpille. Mobil Fokus im korrekt beschrifteten Dialog; Escape schließt eine Ebene. Bilddialog kehrt zum Auslöser zurück. |
| 11 Stichtag | Gemeinsame Regel aus Schaltern und Ende des Organisationstages. Gestellte Uhr prüft Enddatum/Tag danach und Verlängerung. Core-Kommentar-/Like-Schreibwege auch für Admins gesperrt. Folgen/Entfolgen, eigene Kommentarlöschung und Melden bleiben erreichbar. Texte, Vorschläge, Kommentare und Zahlen bleiben lesbar. |
| 12 Export | Absatz-Zustimmungen; je pending-Vorschlag Autor, Datum, Text, Begründung und Zustimmungen; nach Zustimmung/Alter sortiert. Bilder als Textplatzhalter mit Alt-Text. Einsprachigkeit und sichtbare Kommentare bleiben. |
| 13 Aufräumen | Alte Inline-Vorschau-/Fassungszeilen-Partials, Bedienung und Texte entfernt. Admin-, Ressourcen-, Ereignis-, Fehler-, Fallback- und Auswertungstexte erhalten. Bestand, Implementierung und README nachgeführt. |

## Core-Anbindung

`Participation` definiert die Schreibregel. Ergänzungen an Core-Berechtigungen,
Commands und Kommentar-Cells wirken ausschließlich auf Textwork-Ressourcen.
Sie können Core-Ablehnungen nicht überschreiben. Commands prüfen im Dokument-Lock
erneut. Der lokale Kommentaradapter verwaltet abbrechbare Lesezugriffe und
Sortierung. Nachgeladene Core-Dialoge nutzen `ajax:loaded` und werden beim Wechsel
entsorgt. Keine Core-Datei und kein Core-JavaScript-Prototyp wurde verändert.
Diese Schnittstellen benötigen Regressionstests bei späteren Decidim-Upgrades.
Der unabhängige Ladecheck benötigt weder Proposals noch Collaborative Texts.

## Migration und lokaler Test

Die neue Migration `20261006090000_add_textwork_editor_images.rb` ergänzt nullable
`editor_image_id` mit Fremdschlüssel auf `decidim_editor_images` und `image_alt` mit
leerem Standardwert. Bestehende Alpha3-Beiträge und Verlauf bleiben unverändert.
Sie wurde in den getrennten Entwicklungs-/Testdatenbanken der Redesign-App
installiert und ausgeführt. Kein Reset, keine Seeds.

Andere Alpha3-Testinstallationen: Gem-Migration installieren, `db:migrate`, Assets
bauen und Rails neu starten. Dies ist **kein Datenkonverter aus Textwork 1.x,
Alpha1 oder Alpha2**; siehe [MIGRATION](MIGRATION.md). Alte Kapitel-Likes/Follows
bleiben gespeichert, werden aber nicht als Absatz-Likes/Dokument-Follows umgedeutet.

Test: <http://localhost:3033/de/processes/textwork/f/1/documents/1>.
Konten: ignorierte `.local/access.json` der Redesign-App. Alpha2 auf 3032 und
Kundeninstallationen gehören nicht zum Umbau.

## Prüfungen und Grenzen

Vollständige RSpec-Suite, Diff-Fälle, ESLint, RuboCop, unabhängiges Laden,
Asset-Build und Rails-Autoloading werden gegen die isolierte App geprüft.
Browser-Screenshots: `/private/tmp/textwork-*.png`. Die Asset-Warnungen betreffen
vorhandene Sass-Abkündigungen, große Core-Bundles und das Workbox-Cachelimit.

axe prüft WCAG-A/AA-Regeln der Moduloberfläche. Tastatur, 320/390px, Textvergrößerung,
Bildformate und deaktivierter Kommentarbutton-Kontrast werden zusätzlich geprüft.
Das ist kein vollständiger WCAG-2.2-AA-Audit. Screenreader mit realen Personen und
weitere Instanzthemen wurden nicht abgenommen. Die spätere fachliche Auswertung
und Migration alter Plugin-Generationen sind keine Ergebnisse dieses Umbaus.

### Erfolgreiche Prüfläufe

- Vollständige Suite: **96 Beispiele, 0 Fehler**, Seed `55965`, 52,62 s plus
  1,45 s Laden, einschließlich 16 Browserbeispielen.
- Separater Grenzfallnachweis (auch in der vollständigen Suite enthalten): Leiste bei exakt 1440 × 900 und 1054 × 700,
  vor/nach Scrollen 16px über dem unteren Fensterrand, echtes Mausrad am Ende der
  Panel-Liste ohne Dokument-Scroll: **1 Beispiel, 0 Fehler**, Seed `8536`.
- Neun verbindliche Diff-Fälle plus ursprüngliche Verlustfreiheit/Laufzeit: bestanden.
- ESLint, RuboCop, `git diff --check`, eigenständiger Ladecheck und Rails-Zeitwerk:
  bestanden. Deutsch/Englisch: **238 übereinstimmende Schlüssel**.
- Assets gebaut; Rails nur auf Port 3033 neu gestartet. Keine Seeds oder Resets.

Protokolle dieser lokalen Prüfung: `/private/tmp/textwork-final-rspec.log`,
`textwork-wheel.log`, `textwork-final-rubocop.log`, `textwork-assets-final.log`
und `textwork-zeitwerk.log`.

Alte Core-Likes ohne bisherigen Feedback-Zeitstempel setzen diesen spätestens bei
der Rücknahme aus dem gespeicherten Like-Datum. So öffnet auch die Rücknahme einer
solchen alten eigenen Zustimmung die Bearbeitung eines Vorschlags nicht erneut.
Die lokale Redesign-Seite liefert HTTP 200, vier Absatzpillen und den Überblick,
ohne fehlende Übersetzungen. Auch Alpha2 liefert weiterhin HTTP 200.
