# Umsetzungsstand Redesign

Branch: `feature/textwork-redesign`, Version `2.0.0.alpha3`, Stand 5. Oktober 2026.
Grundlage: übergebene Bauanleitung und Mockup, ergänzt durch die bestätigten
Entscheidungen in [ERKUNDUNG.md](ERKUNDUNG.md). Der Gemname bleibt erhalten.

## Abnahme der Bauschritte

| Schritt | Umsetzung und Prüfung |
| --- | --- |
| 0–1 Erkundung und Gerüst | Core-Schnittstellen gelesen; separates Modul-Worktree und separate Test-App. Eigenständiger Ladecheck ohne Proposals/Collaborative Texts. |
| 2 Datenmodell | Stabile Blöcke, Originalfassungen und Strukturverlauf; Reihenfolge, Historie, Regeln und Sperren in Integrationstests. |
| 3 Editorimport | Zwei Kapitel, drei Absätze einschließlich vollständiger Liste; Veröffentlichung, Papierkorb und Wiederherstellung geprüft. |
| 4 Leseansicht | Desktop mit Inhaltsverzeichnis, 18px Lesetext; 390/320px ohne horizontales Scrollen geprüft. |
| 5 Kommentare | Core-Kommentarformular im Panel; Wechsel, Absenden, Zähler, direkte Adresse und Browser-Zurück geprüft. |
| 6 Zustimmung/Folgen | Mehrere Kapitel unabhängig ohne Neuladen; Core-Likes und -Follows, keine eigene Reaktionstabelle. |
| 7 Einreichen | Inline-Eingabe, Live-Vergleich einschließlich Satzzeichen/Listen, Entwurfsschutz und Absenden geprüft. |
| 8 Vorschläge ansehen | Fünf Vorschläge einzeln durchblättern, Sortierung, Detailadresse und Diskussion. |
| 9 Eigene Vorschläge | Bearbeiten vor erstem Feedback; Zurückziehen mit Bestätigung. Frühere Zustimmung sperrt Bearbeitung auch nach deren Rücknahme. |
| 10 Adminentscheidungen | Annahme mit angepasstem Text, veraltete Grundlage, konkurrierender Versionsstand, automatische begründete Ablehnung bei Entfernung. |
| 11 Übersetzungen | Deduplizierung, verspätete Antworten, manuelle Priorität, Veralten und Wiederverwendung bei identischem Original getestet. Kein externer Dienst aufgerufen. |
| 12 Verlauf/Moderation | Core-Versionsliste und Vergleich; abgeschlossene Vorschläge; verborgene Beiträge nicht öffentlich lesbar; entfernte Absätze mit Archivdiskussion. |
| 13 Benachrichtigungen | Empfänger je Ereignis, Deduplizierung, Ausschluss des Akteurs, Entscheidungsbegründung und Transaktionsgrenze geprüft. |
| 14 Barrierefreiheit | Tastaturablauf, Fokus/Escape, mobiles Sheet, 200% Schriftgröße und vergrößerte Textabstände; axe für WCAG-A/AA-Regeln in Leseansicht und Kommentar-Panel. |
| 15 Dateiimport | Markdown, ODT und DOCX; Word-Liste bleibt ein Absatz, unsichere XML-Definitionen werden abgewiesen. |
| 16 Export | Einsprachiger Word-Bericht, fehlende Übersetzungen führen zu einem Hinweis; sichtbare Kommentare/Vorschläge und Zustimmung enthalten. |

## Lokaler Test

- Redesign: <http://localhost:3033/de/processes/textwork/f/1/documents/1>
- Verwaltung: <http://localhost:3033/admin>
- Eigener Import: <http://localhost:3033/de/admin/participatory_processes/textwork/components/2/manage/textwork>
- Konten und lokale Passwörter: `decidim-localtest-redesign/.local/access.json` (nicht versioniert).
- Alpha2 bleibt unverändert unter Port 3032. Kein Datenumzug und keine Änderung einer Kundeninstallation.

Aus dem Modul-Worktree:

```sh
BUNDLE_GEMFILE=/absolute/path/decidim-localtest-redesign/Gemfile \
TEXTWORK_TEST_APP=/absolute/path/decidim-localtest-redesign \
bundle exec rspec spec
bin/check-independence
bundle exec rubocop
npm test
npm run lint
```

Die Test-App braucht die gebauten Assets; bei einem externen Test-App-Pfad wird deren
Test-Packs-Verzeichnis mit den gebauten Packs verbunden. `bin/localtest assets`
baut die Assets, `bin/localtest rails zeitwerk:check` prüft die Rails-Autoloads.

## Prüfergebnis

Am 5. Oktober 2026: **50 RSpec-Beispiele, 0 Fehler**, einschließlich acht
Browserabläufen. RuboCop: 62 Dateien ohne Befund; ESLint ohne Fehler; Diff-Test,
Gem-Build, unabhängiges Laden und Rails-Autoloading erfolgreich. Deutsch/Englisch
haben je 164 identische Übersetzungsschlüssel. Der Asset-Build besteht mit den
bekannten Core-/Webpack-Warnungen. Erneutes Seeding erhält die vorhandenen
Datensätze. Die ursprünglichen Repositories und Port 3032 blieben unverändert.

Die lokale Instanz wurde zusätzlich bei 1440px und 390px visuell angesehen.
Ihre verwendete Sekundärfarbe ist `#234d75`, der Lesetext nutzt 18px mit 28,8px
Zeilenhöhe. Diese Prüfung ersetzt keine Prüfung anderer Instanzfarben.

## Grenzen und weitere Abnahme

Dies ist eine testbare Entwicklungsalpha. Es gibt keinen automatischen Umzug aus
Textwork 1.x oder Alpha1/2. Alte Tabellen werden erhalten, sind dadurch aber noch
kein nutzbares Archiv. Office-Import überträgt Textstruktur, keine vollständige
Office-Formatierung. Der Word-Bericht ersetzt kein Datenbank-/Dateibackup.

Die kleinen Browser-Anbindungen für mehrere Likes und nachgeladene Kommentare
sowie die Übersetzungs-Auftragsklasse sind bewusste Ergänzungen zum Kern. Ihre
Gründe stehen in der Erkundung. Adminentscheidungen teilen einen transaktionalen
Service statt separater Commands je Operation; Benachrichtigungen teilen eine
Ereignisklasse mit ereignisspezifischen Übersetzungen.

Vor produktivem Einsatz bleiben die fachliche/visuelle Abnahme, ein vollständiger
WCAG-2.2-AA-Audit, Tests mit repräsentativen langen Dokumenten und dem tatsächlich
konfigurierten Übersetzungsdienst erforderlich. Die automatische Prüfung allein
bestätigt keine vollständige Barrierefreiheit.

## Korrektur der Amendment-Oberfläche

Der erneute Vergleich mit `desktop.dc.html`, `mobil.dc.html` und Bauanleitung
5.3/5.4 zeigte, dass die erste Umsetzung trotz bestandener Funktionstests den
vorgegebenen Aufbau nicht ausreichend übernommen hatte. Insbesondere war die
Detailansicht nur eine erweiterte Karte, und die Karten zeigten vollständige
Absatzvergleiche. Die frühere visuelle Prüfung war dafür nicht ausreichend.

Die Oberfläche trennt jetzt Karten und Detailansicht. Karten zeigen jede
Änderung mit etwa drei Wörtern unverändertem Kontext, Status aus dem
Decidim-Label-Baustein und den sichtbaren Zustand „Im Text markiert“. Auf dem
Desktop steht der vollständige Vergleich im Dokument; mobil im Detail des
Sheets. Die Vorschau zeigt Nummer, Gesamtzahl, Verfasser und bei veralteten
Vorschlägen die frühere Fassung. Abgeschlossene Vorschläge gehören nicht zur
Navigation durch offene Vorschläge. Auch aus der Detailansicht kann geblättert
werden, wobei Adresse und Diskussion gemeinsam wechseln.

Das mobile Sheet hat einen eigenen scrollbaren Inhaltsbereich sowie einen
festen Kopf und Aktionsbereich. Der Editor enthält die Anleitung und den
Rückweg zu vorhandenen Vorschlägen. Der Listenhinweis erscheint nur bei Listen.
Die mobilen Karten bieten zusätzlich „Details“.

Die Core-Kommentaransichten bleiben eingebunden. Ihre mobile Formularhülle wird
im Textwork-Panel mit lokal begrenztem CSS direkt angezeigt; der Core-Button zum
Öffnen einer weiteren Vollbildansicht entfällt dort. „Vorschlag kommentieren“
fokussiert das Formular und wartet gegebenenfalls auf dessen Initialisierung.
Der Emoji-Button hat im Panel eine Bedienfläche von 44 × 44 px.

Die Browserprüfungen umfassen Karten, Details, Navigation, ältere Fassungen,
abgeschlossene Vorschläge, Editor und mobiles Kommentieren bei 390/320 px.
Axe prüft jetzt zusätzlich Vorschlagsliste, Detailansicht und mobilen Editor.
Der separate Kontrasttest wartet mit einer von Capybara behandelten Exception
auf das Ende des Core-Farbwechsels; die vorher verwendete RSpec-Exception wurde
von Capybara nicht erneut geprüft. Ein bestandener Testlauf ersetzt weiterhin
keine vollständige visuelle und fachliche Abnahme durch den Auftraggeber.

Abschlussprüfung am 5. Oktober 2026: **54 RSpec-Beispiele, 0 Fehler**, davon
12 Browserabläufe. JavaScript-Diff-Tests, ESLint, RuboCop für die geänderte
Testsuite und Asset-Build erfolgreich. Desktop-Karten und Detailansicht sowie
die mobile Detailansicht wurden zusätzlich in der lokalen deutschen Oberfläche
mit den Vorlagen verglichen. Es sind keine Datenbankmigrationen erforderlich.
